extends Node
## Independent per-avatar eyelid motion; skeletal animation keeps its clips.
var target: MeshInstance3D
var blink_index := -1
var elapsed := 0.0
var interval := 3.8
var cycle := 0

func _ready() -> void:
	if target == null or blink_index < 0:
		set_process(false)
		return
	# A stable phase per instance avoids a synchronized team blink.
	elapsed = float(target.get_instance_id() % 170) / 100.0

static func blink_amount(time: float) -> float:
	if time < 0.0 or time >= 0.25: return 0.0
	if time < 0.085: return smoothstep(0.0, 0.085, time)
	if time < 0.115: return 1.0
	return 1.0 - smoothstep(0.115, 0.25, time)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		set_process(false)
		return
	elapsed += delta
	if elapsed > interval + 0.25:
		elapsed = 0.0
		cycle += 1
		interval = 3.3 + float((cycle * 37 + target.get_instance_id()) % 160) / 100.0
	target.set_blend_shape_value(blink_index, blink_amount(elapsed - interval))
