extends Label
const Visual = preload("res://ui/visual_theme.gd")
var entries: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_color", Color.TRANSPARENT)
	resized.connect(queue_redraw)

func _draw() -> void:
	if entries.is_empty():
		return
	var segments: Array = []
	if entries.size() == 2:
		segments = [[str(entries[0][0]) + " ", false], [str(entries[0][1]), true], [" — ", false], [str(entries[1][1]), true], [" " + str(entries[1][0]), false]]
	else:
		for i in range(entries.size()):
			if i > 0: segments.append(["  |  ", false])
			segments.append([str(entries[i][0]) + ": ", false])
			segments.append([str(entries[i][1]), true])
	var width := 0.0
	for part in segments:
		var font: Font = Visual.DISPLAY if part[1] else Visual.EMPHASIS
		width += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 32 if part[1] else 24).x
	var fit := minf(1.0, size.x / maxf(width, 1.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * fit)
	var x := 0.0
	for part in segments:
		var font: Font = Visual.DISPLAY if part[1] else Visual.EMPHASIS
		var point_size := 32 if part[1] else 24
		draw_string(font, Vector2(x, 30 if part[1] else 28), part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, point_size, Visual.ENERGY if part[1] else Visual.INK)
		x += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x
	draw_set_transform(Vector2.ZERO)
