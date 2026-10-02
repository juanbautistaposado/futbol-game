extends Control

var goal_rect := Rect2()
var target := Vector2.ZERO
var committed := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_target(rect: Rect2, point: Vector2, is_committed := false) -> void:
	goal_rect = rect
	target = point
	committed = is_committed
	visible = true
	queue_redraw()

func set_target(point: Vector2, is_committed := false) -> void:
	target = point
	committed = is_committed
	queue_redraw()

func _draw() -> void:
	if goal_rect.size.x <= 0.0 or goal_rect.size.y <= 0.0:
		return
	var color := Color("8cf2ac") if committed else Color("facc15")
	draw_circle(target, 18.0, Color(color.r, color.g, color.b, 0.22))
	draw_arc(target, 12.0, 0.0, TAU, 32, color, 3.0, true)
	draw_line(target + Vector2(-23, 0), target + Vector2(-16, 0), color, 2.0)
	draw_line(target + Vector2(16, 0), target + Vector2(23, 0), color, 2.0)
	draw_line(target + Vector2(0, -23), target + Vector2(0, -16), color, 2.0)
	draw_line(target + Vector2(0, 16), target + Vector2(0, 23), color, 2.0)
