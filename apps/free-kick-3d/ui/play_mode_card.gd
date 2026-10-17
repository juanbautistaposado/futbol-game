extends Button
## Illustrated mode selection; labels remain native and the whole cover is a Button.

const Visual = preload("res://ui/visual_theme.gd")
const SmoothPolygon = preload("res://ui/smooth_polygon.gd")
var smooth_polygons := SmoothPolygon.new()
var artwork: Texture2D
var caption := ""
var description := ""
var selected := false:
	set(value):
		selected = value
		if is_instance_valid(_heading):
			_heading.add_theme_color_override("font_color", Visual.BASE if selected else Visual.INK)
		if is_instance_valid(_check): _check.visible = selected
		queue_redraw()
var _heading: Label
var _check: TextureRect

func _ready() -> void:
	text = caption
	custom_minimum_size = Vector2(280, 324)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	_heading = _label(caption, 22, Visual.DISPLAY, Visual.INK)
	_heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_heading.offset_left = 18
	_heading.offset_top = 215
	_heading.offset_right = -18
	_heading.offset_bottom = 249
	var detail := _label(description, 16, Visual.BODY, Visual.MUTED)
	detail.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	detail.offset_left = 18
	detail.offset_top = 269
	detail.offset_right = -18
	detail.offset_bottom = 316
	_check = TextureRect.new()
	_check.texture = Visual.CHECK
	_check.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_check.offset_left = -40
	_check.offset_right = -16
	_check.offset_top = 16
	_check.offset_bottom = 40
	_check.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_check.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_check.modulate = Visual.ENERGY
	_check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_check)
	selected = selected
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(func() -> void: smooth_polygons.clear(); queue_redraw())

func _label(value: String, font_size: int, font: Font, color: Color) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_override("font", font)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item)
	return item

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Visual.BASE)
	if artwork != null:
		var target := Rect2(2, 2, w - 4, 220)
		var source_size := artwork.get_size()
		var fit := maxf(target.size.x / source_size.x, target.size.y / source_size.y)
		var crop_size := target.size / fit
		draw_texture_rect_region(artwork, target, Rect2((source_size - crop_size) * 0.5, crop_size))
	# The caption belongs to a cut sports-poster plate, not baked-in image text.
	var fill := Visual.ACCENT if selected else Visual.BASE
	if is_hovered() and not selected: fill = Visual.BLUE
	smooth_polygons.draw(self, PackedVector2Array([Vector2(1, 209), Vector2(w - 1, 193), Vector2(w - 1, 253), Vector2(1, 267)]), fill)
	var edge := Visual.ENERGY if selected or has_focus() else Visual.INK if is_hovered() else Visual.BLUE
	var width := 3.0 if selected or has_focus() else 2.0
	draw_rect(Rect2(Vector2.ONE * width * 0.5, size - Vector2.ONE * width), edge, false, width)
	if selected:
		draw_rect(Rect2(w - 48, 8, 40, 40), Visual.BASE)
