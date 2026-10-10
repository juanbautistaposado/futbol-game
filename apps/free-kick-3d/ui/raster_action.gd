extends Button

const ART = preload("res://ui/brand/play-raster.png")
const Visual = preload("res://ui/visual_theme.gd")
const SmoothPolygon = preload("res://ui/smooth_polygon.gd")
var smooth_polygons := SmoothPolygon.new()
var artwork: Texture2D = ART
var caption := "JUGAR"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	text = caption
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	for event in [mouse_entered, mouse_exited, focus_entered, focus_exited, button_down, button_up]:
		event.connect(queue_redraw)
	resized.connect(func() -> void:
		smooth_polygons.clear()
		queue_redraw()
	)

func _draw() -> void:
	var offset := Vector2(0, 3) if is_pressed() else Vector2(0, -2) if is_hovered() else Vector2.ZERO
	var tint := Color(0.94, 0.94, 0.94) if is_pressed() else Color(1.08, 1.08, 1.08) if is_hovered() else Color.WHITE
	draw_texture_rect(artwork, Rect2(offset, size), false, tint)
	if has_focus() or is_hovered():
		var points := PackedVector2Array()
		for point in [Vector2(0.035, 0.982), Vector2(0.96, 0.792), Vector2(0.958, 0.816), Vector2(0.032, 1.006)]:
			points.append(point * size + offset)
		smooth_polygons.draw(self, points, Visual.ENERGY)
