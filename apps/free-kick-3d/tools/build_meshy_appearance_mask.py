"""Bake semantic UV masks from the existing PLAYER GLB; never edit its mesh.

Run with Python, Pillow and NumPy. R=skin, G=hair, B=shorts, A=beard.
The two runtime roles share UV0 and the original atlas, so they share this map.
Classification uses rest geometry to distinguish navy shorts from boots/collar,
and texture color to retain eyes, lips, white stripes and cloth details.
"""
from pathlib import Path
import json
import struct

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "apps/free-kick-3d/assets/footballer"


def accessor(data, buffer, index):
    value = data["accessors"][index]
    view = data["bufferViews"][value["bufferView"]]
    dtype = {5123: "<u2", 5125: "<u4", 5126: "<f4"}[value["componentType"]]
    width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[value["type"]]
    return np.frombuffer(buffer, dtype, value["count"] * width,
                         view.get("byteOffset", 0) + value.get("byteOffset", 0)).reshape(-1, width)


def smooth(a, b, value):
    fraction = np.clip((value - a) / (b - a), 0, 1)
    return fraction * fraction * (3 - 2 * fraction)


def pad_islands(values, coverage):
    result = values.copy()
    filled = coverage.copy()
    for _ in range(3):
        previous = filled.copy()
        for dy, dx in [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)]:
            source_filled = np.roll(previous, (dy, dx), axis=(0, 1))
            target = ~filled & source_filled
            result[target] = np.roll(result, (dy, dx), axis=(0, 1))[target]
            filled[target] = True
    return result


def build():
    raw = (ASSETS / "meshy_striker.glb").read_bytes()
    length = struct.unpack_from("<I", raw, 12)[0]
    data = json.loads(raw[20:20 + length])
    buffer = raw[28 + length:]
    atlas = np.array(Image.open(ASSETS / "meshy_striker_Image_0.jpg"), dtype=np.float32) / 255
    height, width, _ = atlas.shape
    positions = np.zeros((height, width, 3), dtype=np.float32)
    coverage = np.zeros((height, width), dtype=bool)
    for primitive in data["meshes"][0]["primitives"]:
        attrs = primitive["attributes"]
        vertices = accessor(data, buffer, attrs["POSITION"])
        uv = accessor(data, buffer, attrs["TEXCOORD_0"]) * (width, height)
        indices = accessor(data, buffer, primitive["indices"]).reshape(-1, 3)
        for triangle in indices:
            corners = uv[triangle]
            low = np.maximum(0, np.floor(corners.min(axis=0)).astype(int))
            high = np.minimum((width - 1, height - 1), np.ceil(corners.max(axis=0)).astype(int))
            if np.any(high < low):
                continue
            x, y = np.meshgrid(np.arange(low[0], high[0] + 1) + .5,
                               np.arange(low[1], high[1] + 1) + .5)
            a, b, c = corners
            denominator = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
            if abs(denominator) < 1e-8:
                continue
            first = ((b[1] - c[1]) * (x - c[0]) + (c[0] - b[0]) * (y - c[1])) / denominator
            second = ((c[1] - a[1]) * (x - c[0]) + (a[0] - c[0]) * (y - c[1])) / denominator
            third = 1 - first - second
            inside = (first >= 0) & (second >= 0) & (third >= 0)
            region = np.s_[low[1]:high[1] + 1, low[0]:high[0] + 1]
            position = first[..., None] * vertices[triangle[0]] + second[..., None] * vertices[triangle[1]] + third[..., None] * vertices[triangle[2]]
            positions[region][inside] = position[inside]
            coverage[region][inside] = True

    x, y, z = np.moveaxis(positions, -1, 0)
    r, g, b = np.moveaxis(atlas, -1, 0)
    brightness = .2126 * r + .7152 * g + .0722 * b
    warmth = smooth(.035, .085, r - g) * smooth(.015, .05, g - b)
    skin = warmth * smooth(.19, .30, brightness)
    head = (y > 1.63)
    # Anatomical exclusions follow lips and eyes rather than rectangular bands.
    # The old mouth rectangle included the moustache; the old eye band included
    # the eyebrows, leaving both untouched by the facial-hair controls.
    mouth_shape = ((x + .002) / .034) ** 2 + ((y - 1.690) / .0065) ** 2
    # Lip pigment has a red undertone; adjoining skin/stubble does not. This
    # distinguishes the real vermilion from the old flesh-colored mouth ring.
    lip_pigment = smooth(.045, .085, r - 2 * g + b)
    mouth = (1 - smooth(.78, 1.16, mouth_shape)) * (z > .072) * lip_pigment
    # Preserve the eye opening only. The lower lid is skin, not eye white.
    eye_shape = ((np.abs(x) - .033) / .019) ** 2 + ((y - 1.7635) / .0045) ** 2
    eyes = (1 - smooth(.78, 1.16, eye_shape)) * (z > .065)
    protected = np.maximum(mouth, eyes)
    skin *= 1 - protected
    hair_zone = np.maximum(smooth(1.783, 1.81, y), ((y > 1.705) & (z < .025)).astype(float))
    hair = head * hair_zone * (1 - smooth(.20, .39, brightness)) * (1 - protected)
    # Removing painted facial hair restores skin; the silhouette stays intact.
    # Removal covers the complete lower face, including anti-aliased and pale
    # stubble. Dye coverage remains separate so "on" preserves the original
    # beard pattern instead of painting a solid beard-shaped patch.
    beard = head * (1 - smooth(1.720, 1.731, y)) * smooth(1.635, 1.643, y) * smooth(-.009, .004, z)
    beard *= 1 - protected
    eyebrow_shape = ((np.abs(x) - .039) / .029) ** 2 + ((y - 1.7785) / .0085) ** 2
    eyebrows = (1 - smooth(.80, 1.14, eyebrow_shape)) * (z > .062) * (1 - eyes)
    beard_dye = beard * (1 - smooth(.31, .47, brightness))
    eyebrow_dye = eyebrows * (1 - smooth(.29, .45, brightness))
    shorts = (y > .66) & (y < 1.085) & (np.abs(x) < .285)
    shorts = shorts * (1 - smooth(.12, .32, brightness)) * (1 - warmth)
    # Face shadows can be too dark for hue classification. Geometry supplies
    # complete facial skin coverage while the authored eyes/lips stay intact.
    # Lips get their own complexion-relative pigment in the shader. Their
    # underlying pixels must also be skin, so feathered edges cannot leak the
    # original complexion through a partial mask.
    skin = np.maximum(skin, head.astype(float) * (1 - eyes))
    skin *= 1 - hair
    masks = np.stack([skin, hair, shorts, beard], axis=-1) * coverage[..., None]
    # Extend two texels across island edges for filtering, without changing UVs.
    masks = pad_islands(masks, coverage)
    channels = [Image.fromarray((masks[..., channel] * 255).astype(np.uint8)) for channel in range(4)]
    target = ASSETS / "meshy_appearance_mask.png"
    Image.merge("RGBA", channels).save(target)
    # RGBA: brow removal, beard dye, brow dye, actual lip pigment.
    face = np.stack([eyebrows, beard_dye, eyebrow_dye, mouth], axis=-1)
    face *= coverage[..., None]
    face = pad_islands(face, coverage)
    Image.fromarray((face * 255).astype(np.uint8), "RGBA").save(ASSETS / "meshy_facial_mask.png")
    # The keeper export splits a slightly narrower jersey region. Tint the
    # remaining neutral cloth without touching skin, collar, stripes or boots.
    neutral = 1 - smooth(.15, .24, (atlas.max(axis=-1) - atlas.min(axis=-1)) / np.maximum(atlas.max(axis=-1), .01))
    cloth = ((y > .955) & (y < 1.64)) * neutral * smooth(.25, .35, brightness) * coverage
    cloth = pad_islands(cloth, coverage)
    Image.fromarray((cloth * 255).astype(np.uint8)).save(ASSETS / "meshy_cloth_mask.png")
    print(f"Saved {target.relative_to(ROOT)}: " + ", ".join(
        f"{name}={np.count_nonzero(masks[..., i] > .5)}" for i, name in enumerate(["skin", "hair", "shorts", "beard"])))


if __name__ == "__main__":
    build()
