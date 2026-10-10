extends Control
const Visual = preload("res://ui/visual_theme.gd")
const SmoothPolygon = preload("res://ui/smooth_polygon.gd")
var smooth_polygons := SmoothPolygon.new()

# Same red / amber / green timing challenge as the Phaser prototype.
var elapsed := 0.0
var indicator := 0.5
var power := 0.0
var active := false
var feedback := "Mantené clic para cargar · soltá en el centro"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(_on_resized)

func _on_resized() -> void:
	smooth_polygons.clear()
	queue_redraw()

func begin() -> void:
	elapsed = 0.0
	indicator = 0.5
	power = 0.0
	active = true
	feedback = "SOLTÁ EN VERDE"
	show()
	queue_redraw()

func advance(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	# Triangle wave, independent of refresh rate and safe across long frames.
	indicator = 1.0 - absf(fposmod(0.5 + elapsed * 0.65, 2.0) - 1.0)
	power = minf(elapsed / 1.15, 1.0)
	queue_redraw()

func accuracy() -> float:
	return clampf(1.0 - absf(indicator - 0.5) * 2.0, 0.0, 1.0)

func lock_shot() -> void:
	active = false
	feedback = "¡PERFECTO!" if accuracy() >= 0.9 else "BUEN TIRO" if accuracy() >= 0.7 else "DESVIADO"
	queue_redraw()

func reset() -> void:
	active = false
	indicator = 0.5
	power = 0.0
	feedback = "Mantené clic para cargar · soltá en el centro"
	show()
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var left := 26.0
	var width := w - 52.0
	smooth_polygons.draw(self, PackedVector2Array([Vector2(18, 0), Vector2(w, 0), Vector2(w - 18, h - 8), Vector2(w - 30, h), Vector2(0, h)]), Visual.BASE)
	smooth_polygons.draw(self, PackedVector2Array([Vector2(18, 0), Vector2(26, 0), Vector2(8, h - 7), Vector2(w - 26, h - 7), Vector2(w - 30, h), Vector2(0, h)]), Visual.ACCENT)
	draw_string(Visual.EMPHASIS, Vector2(left, 28), "PRECISIÓN", HORIZONTAL_ALIGNMENT_LEFT, width, 18, Visual.INK)
	draw_string(Visual.BODY, Vector2(left, 28), "POTENCIA %d%%" % roundi(power * 100), HORIZONTAL_ALIGNMENT_RIGHT, width, 16, Visual.INK)
	var colors := [Visual.ACCENT, Visual.ENERGY, Visual.SUCCESS, Visual.ENERGY, Visual.ACCENT]
	for i in range(5):
		draw_rect(Rect2(left + i * width / 5.0, 44, width / 5.0 - 1, 25), colors[i])
	var cursor := left + indicator * width
	draw_circle(Vector2(cursor, 56.5), 24, Visual.BASE, false, 6, true)
	draw_circle(Vector2(cursor, 56.5), 20, Visual.INK, false, 3, true)
	draw_line(Vector2(cursor, 30), Vector2(cursor, 84), Visual.INK, 2, true)
	draw_rect(Rect2(cursor - 4, 41, 8, 31), Visual.BASE)
	draw_rect(Rect2(cursor - 2, 43, 4, 27), Visual.INK)
	if active or feedback in ["¡PERFECTO!", "BUEN TIRO", "DESVIADO"]:
		draw_string(Visual.BODY, Vector2(left, 90), feedback, HORIZONTAL_ALIGNMENT_LEFT, width, 14, Visual.INK)
		draw_rect(Rect2(left + width * 0.65, 84, width * 0.35 * power, 4), Visual.ENERGY)
