extends Button

const Visual = preload("res://ui/visual_theme.gd")
const SmoothPolygon = preload("res://ui/smooth_polygon.gd")
var smooth_polygons := SmoothPolygon.new()
var caption := "PERSONAJE"

func _ready() -> void:
	text = caption
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	var title := Label.new()
	title.text = caption
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.add_theme_font_override("font", Visual.DISPLAY)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Visual.BASE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	for event in [mouse_entered, mouse_exited, focus_entered, focus_exited, button_down, button_up]:
		event.connect(queue_redraw)
	resized.connect(func() -> void: smooth_polygons.clear(); queue_redraw())

func _draw() -> void:
	var points := PackedVector2Array()
	var shadow := PackedVector2Array()
	var offset := Vector2(0, 2) if is_pressed() else Vector2.ZERO
	for point in [Vector2(0.05, 0.93), Vector2(0.13, 0.15), Vector2(0.98, 0.04), Vector2(0.90, 0.82)]:
		points.append(point * size + offset)
		shadow.append(point * size + Vector2(5, 5))
	smooth_polygons.draw(self, shadow, Visual.BASE)
	smooth_polygons.draw(self, points, Visual.ENERGY if is_hovered() or has_focus() else Visual.INK)
