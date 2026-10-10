extends PanelContainer
const Visual = preload("res://ui/visual_theme.gd")
const SmoothPolygon = preload("res://ui/smooth_polygon.gd")
var smooth_polygons := SmoothPolygon.new()
var fill := Visual.BASE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var spacing := Visual.box(Color.TRANSPARENT, Color.TRANSPARENT)
	spacing.set_border_width_all(0)
	spacing.content_margin_left = 24
	spacing.content_margin_right = 24
	add_theme_stylebox_override("panel", spacing)
	resized.connect(_on_resized)

func _on_resized() -> void:
	smooth_polygons.clear()
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var points := PackedVector2Array([Vector2(14, 0), Vector2(w, 0), Vector2(w - 14, h), Vector2(0, h)])
	smooth_polygons.draw(self, points, fill)
	smooth_polygons.draw(self, PackedVector2Array([Vector2(14, 0), Vector2(20, 0), Vector2(6, h), Vector2(0, h)]), Visual.ACCENT)
	draw_line(Vector2(7, h - 1), Vector2(w - 14, h - 1), Visual.ACCENT, 2)
