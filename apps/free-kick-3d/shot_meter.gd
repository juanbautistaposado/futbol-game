extends Control

# Same red / amber / green timing challenge as the Phaser prototype.
var elapsed := 0.0
var indicator := 0.5
var power := 0.0
var active := false
var feedback := "Mantené clic para cargar · soltá en el centro"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	var font := ThemeDB.fallback_font
	var width := size.x - 40.0
	draw_style_box(panel_style(), Rect2(Vector2.ZERO, size))
	draw_string(font, Vector2(20, 26), feedback, HORIZONTAL_ALIGNMENT_CENTER, width, 18, Color("f8fafc"))
	var colors := [Color("ef5350"), Color("ffb547"), Color("55d98b"), Color("ffb547"), Color("ef5350")]
	for i in range(5):
		draw_rect(Rect2(20 + i * width / 5.0, 43, width / 5.0, 20), colors[i])
	draw_line(Vector2(size.x / 2, 39), Vector2(size.x / 2, 67), Color.WHITE, 2)
	var cursor := 20 + indicator * width
	draw_rect(Rect2(cursor - 5, 37, 10, 32), Color("102132"))
	draw_rect(Rect2(cursor - 3, 39, 6, 28), Color.WHITE)
	draw_string(font, Vector2(20, 89), "PRECISIÓN", HORIZONTAL_ALIGNMENT_LEFT, width, 12, Color("b6cbdc"))
	draw_string(font, Vector2(20, 89), "POTENCIA %d%%" % roundi(power * 100), HORIZONTAL_ALIGNMENT_RIGHT, width, 12, Color("b6cbdc"))
	draw_rect(Rect2(20, 99, width, 5), Color("20394d"))
	draw_rect(Rect2(20, 99, width * power, 5), Color("64c7ff"))

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.065, 0.1, 0.94)
	style.set_corner_radius_all(12)
	return style
