"""Author PLAYER's football arm gesture; leave every other animation channel intact.

Reference landmarks are art-direction guides in x-right/y-up/z-forward metres.
FK rotations retain the existing bone lengths, hierarchy and animated torso.
"""
import math
import json
import struct
import bpy
from mathutils import Matrix, Quaternion, Vector

ARM_BONES = [kind + '.' + side for side in ['R', 'L'] for kind in ['UpperArm', 'Forearm', 'Hand']]

# (elbow, wrist, wrist axial turn). R is the same chain as the kicking Foot.R.
READY = {
    'R': ((.285, 1.265, .075), (.310, 1.110, .290), 35),
    'L': ((-.285, 1.265, .075), (-.310, 1.110, .290), -35),
}
WINDUP = {
    'R': ((.320, 1.280, -.100), (.370, 1.120, -.280), 25),
    'L': ((-.430, 1.390, .050), (-.550, 1.340, .260), -45),
}
CONTACT = {
    'R': ((.350, 1.250, -.150), (.300, 1.130, .100), 35),
    'L': ((-.450, 1.420, .080), (-.640, 1.400, .290), -55),
}
FOLLOW = {
    'R': ((.340, 1.370, .150), (.250, 1.240, .370), 45),
    'L': ((-.380, 1.300, -.050), (-.470, 1.070, -.100), -30),
}
KEY_POSES = [(1., READY), (7., WINDUP), (15., CONTACT), (21., FOLLOW), (29., READY)]


def curves(action):
    for layer in action.layers:
        for strip in layer.strips:
            for bag in strip.channelbags:
                yield bag


def blender_vector(point):
    return Vector((point[0], -point[2], point[1]))


def orient_bone(rig, name, rotation):
    bone = rig.pose.bones[name]
    origin = bone.head.copy()
    target = Matrix.Translation(origin) @ rotation.to_matrix().to_4x4()
    local = bone.bone.convert_local_to_pose(target, bone.bone.matrix_local,
        parent_matrix=bone.parent.matrix,
        parent_matrix_local=bone.parent.bone.matrix_local, invert=True)
    # Assign only rotation: writing PoseBone.matrix also mutates unkeyed
    # location/scale defaults and can leak rounding changes into other clips.
    bone.rotation_quaternion = local.to_quaternion()
    bpy.context.view_layer.update()


def author_striker_arms(rig):
    """Copy only Idle/Kick, replace six rotation curves, keep other clips unchanged."""
    scene = bpy.context.scene
    tracks = {track.name: track for track in rig.animation_data.nla_tracks}
    for track in tracks.values():
        track.mute = True
    modifications = []
    for clip in ['Idle', 'Kick']:
        strip = tracks[clip].strips[0]
        original = strip.action
        authored = original.copy()
        authored.name = clip + '_football_arms'
        for bag in curves(authored):
            for curve in list(bag.fcurves):
                if any(curve.data_path == 'pose.bones["' + name + '"].rotation_quaternion' for name in ARM_BONES):
                    bag.fcurves.remove(curve)
        start, end = (round(t) for t in original.frame_range)
        landmarks = []
        pose_keys = [(start, READY), (end, READY)] if clip == 'Idle' else KEY_POSES
        for frame, target in pose_keys:
            rig.animation_data.action = original
            scene.frame_set(round(frame))
            bpy.context.view_layer.update()
            chest_delta = rig.pose.bones['Chest'].matrix.to_quaternion() @ rig.data.bones['Chest'].matrix_local.to_quaternion().inverted()
            for side in ['R', 'L']:
                shoulder = Vector((.207 if side == 'R' else -.207, 1.524, .019))
                elbow, wrist, turn = target[side]
                upper_axis = blender_vector(Vector(elbow) - shoulder).normalized()
                forearm_axis = blender_vector(Vector(wrist) - Vector(elbow)).normalized()
                upper_rest = rig.data.bones['UpperArm.' + side]
                forearm_rest = rig.data.bones['Forearm.' + side]
                upper_q = chest_delta @ (upper_rest.tail_local - upper_rest.head_local).normalized().rotation_difference(upper_axis) @ upper_rest.matrix_local.to_quaternion()
                forearm_q = chest_delta @ (forearm_rest.tail_local - forearm_rest.head_local).normalized().rotation_difference(forearm_axis) @ forearm_rest.matrix_local.to_quaternion()
                orient_bone(rig, 'UpperArm.' + side, upper_q)
                orient_bone(rig, 'Forearm.' + side, forearm_q)
                hand_rest = rig.data.bones['Hand.' + side]
                hand_relative = forearm_rest.matrix_local.to_quaternion().inverted() @ hand_rest.matrix_local.to_quaternion()
                hand_q = forearm_q @ hand_relative @ Quaternion(Vector((0, 1, 0)), math.radians(turn))
                orient_bone(rig, 'Hand.' + side, hand_q)
            landmarks.append((frame, {name: rig.pose.bones[name].rotation_quaternion.copy() for name in ARM_BONES}))
        sampled = []
        for frame in range(start, end + 1):
            for (first_frame, first), (last_frame, last) in zip(landmarks, landmarks[1:]):
                if frame <= last_frame:
                    fraction = max(0., min(1., (frame - first_frame) / (last_frame - first_frame)))
                    fraction = fraction * fraction * (3 - 2 * fraction)
                    # Interpolate rotations on their shortest arc rather than
                    # normalizing interpolated wrist directions near reversal.
                    sampled.append((frame, {name: first[name].slerp(last[name], fraction) for name in ARM_BONES}))
                    break
        rig.animation_data.action = authored
        for frame, poses in sampled:
            for name, rotation in poses.items():
                bone = rig.pose.bones[name]
                bone.rotation_mode = 'QUATERNION'
                bone.rotation_quaternion = rotation
                bone.keyframe_insert('rotation_quaternion', frame=frame, group=name)
        for bag in curves(authored):
            for curve in bag.fcurves:
                if any(curve.data_path == 'pose.bones["' + name + '"].rotation_quaternion' for name in ARM_BONES):
                    for point in curve.keyframe_points:
                        point.interpolation = 'LINEAR'
        strip.action = authored
        modifications.append({'clip': clip, 'rotation_bones': ARM_BONES, 'frames': [start, end]})
    rig.animation_data.action = tracks['Idle'].strips[0].action
    scene.frame_set(1)
    bpy.context.view_layer.update()
    return modifications


def relax_hand(point, smooth):
    """A mild continuous finger rest curl; preserve palm/wrist, UV and weights."""
    result = point.copy()
    if abs(point.x) > .35 and .75 < point.z < .95:
        curl = 1 - smooth(.82, .95, point.z)
        sign = 1 if point.x > 0 else -1
        result.x -= (point.x - sign * .435) * .15 * curl
        result.y -= .024 * curl * curl * smooth(.39, .425, abs(point.x))
        result.z += .008 * curl * curl
    return result


def preserve_unedited_clip_channels(source_path, target_path, keep_authored_arms=True):
    """Keep untouched source channels exact despite exporter FK roundoff.

    The exporter derives local transforms from animated global matrices. New
    arm rotations introduce tiny rounding variations in child translations,
    scales and finger tracks. Copy their original glTF samplers, leaving only
    the six authored rotation channels different in Idle/Kick.
    """
    def read(path):
        raw = path.read_bytes()
        length = struct.unpack_from('<I', raw, 12)[0]
        return json.loads(raw[20:20 + length]), raw[28 + length:]

    source, source_buffer = read(source_path)
    target, target_buffer = read(target_path)
    buffer = bytearray(target_buffer)
    nodes = {node['name']: i for i, node in enumerate(target['nodes']) if 'name' in node}
    accessor_cache = {}

    def copy_accessor(index):
        if index in accessor_cache:
            return accessor_cache[index]
        accessor = dict(source['accessors'][index])
        original_view = source['bufferViews'][accessor['bufferView']]
        view = dict(original_view)
        start = original_view.get('byteOffset', 0)
        buffer.extend(b'\0' * (-len(buffer) % 4))
        view['byteOffset'] = len(buffer)
        view['buffer'] = 0
        buffer.extend(source_buffer[start:start + view['byteLength']])
        accessor['bufferView'] = len(target['bufferViews'])
        target['bufferViews'].append(view)
        result = len(target['accessors'])
        target['accessors'].append(accessor)
        accessor_cache[index] = result
        return result

    authored = {animation['name']: animation for animation in target['animations']}
    copied = 0
    for original in source['animations']:
        animation = authored[original['name']]
        current = {(target['nodes'][channel['target']['node']]['name'], channel['target']['path']): channel for channel in animation['channels']}
        for channel in original['channels']:
            name = source['nodes'][channel['target']['node']]['name']
            path = channel['target']['path']
            if keep_authored_arms and original['name'] in ['Idle', 'Kick'] and name in ARM_BONES and path == 'rotation':
                continue
            sampler = dict(original['samplers'][channel['sampler']])
            sampler['input'] = copy_accessor(sampler['input'])
            sampler['output'] = copy_accessor(sampler['output'])
            replacement = {'sampler': len(animation['samplers']), 'target': {'node': nodes[name], 'path': path}}
            animation['samplers'].append(sampler)
            existing = current[(name, path)]
            animation['channels'][animation['channels'].index(existing)] = replacement
            copied += 1
    target['buffers'][0]['byteLength'] = len(buffer)
    payload = json.dumps(target, separators=(',', ':')).encode()
    payload += b' ' * (-len(payload) % 4)
    buffer.extend(b'\0' * (-len(buffer) % 4))
    total = 12 + 8 + len(payload) + 8 + len(buffer)
    target_path.write_bytes(struct.pack('<III', 0x46546C67, 2, total)
        + struct.pack('<II', len(payload), 0x4E4F534A) + payload
        + struct.pack('<II', len(buffer), 0x004E4942) + buffer)
    return copied
