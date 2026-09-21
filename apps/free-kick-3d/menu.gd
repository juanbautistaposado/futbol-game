extends Control

const SAVE_PATH := "user://free_kick_3d.cfg"
const INK := Color("d7f7ff")
var profile := ConfigFile.new()
var page: Control
var content: Control
var play_button: Button
var difficulty_buttons: Array[Button] = []
var difficulty := "medio"
var shot_count := 7
var player_count := 1
var start_button: Button
var shot_value: Label
var player_value: Label
var setup_summary: Label
var shot_minus: Button
var shot_plus: Button
var player_minus: Button
var player_plus: Button

func _ready() -> void:
	profile.load(SAVE_PATH)
	shot_count = clampi(int(profile.get_value("settings", "shots", 7)), 5, 15)
	player_count = clampi(int(profile.get_value("settings", "players", 1)), 1, 4)
	difficulty = str(profile.get_value("settings", "difficulty", "medio"))
	if difficulty not in ["facil", "medio", "dificil"]:
		difficulty = "medio"
	content = Control.new()
	content.size = Vector2(1024, 640)
	add_child(content)
	resized.connect(layout_content)
	layout_content()
	show_menu()

func layout_content() -> void:
	var ratio := minf(size.x / 1024.0, size.y / 640.0)
	content.scale = Vector2.ONE * ratio
	content.position = (size - Vector2(1024, 640) * ratio) * 0.5
	queue_redraw()

func _draw() -> void:
	# Same dusk backdrop and stylized pitch geometry as the HTML menu.
	for row in range(64):
		var amount := float(row) / 63.0
		draw_rect(Rect2(0, size.y * row / 64.0, size.x, size.y / 64.0 + 1), Color("0a1720").lerp(Color("123827"), amount))
	var ratio := minf(size.x / 1024.0, size.y / 640.0)
	var origin := (size - Vector2(1024, 640) * ratio) * 0.5
	draw_rect(Rect2(0, origin.y + 460 * ratio, size.x, size.y), Color("1f7a3a"))
	var points := PackedVector2Array()
	for i in range(81):
		var angle := PI + PI * i / 80.0
		points.append(origin + Vector2(512 + cos(angle) * 310, 640 + sin(angle) * 105) * ratio)
	draw_polyline(points, Color(0.9, 0.97, 0.87, 0.35), 3 * ratio, true)
	draw_line(origin + Vector2(252, 640) * ratio, origin + Vector2(382, 460) * ratio, Color(0.9, 0.97, 0.87, 0.35), 3 * ratio, true)
	draw_line(origin + Vector2(772, 640) * ratio, origin + Vector2(642, 460) * ratio, Color(0.9, 0.97, 0.87, 0.35), 3 * ratio, true)

func new_page() -> void:
	if page:
		content.remove_child(page)
		page.queue_free()
	page = Control.new()
	page.size = Vector2(1024, 640)
	content.add_child(page)

func label(text: String, rect: Rect2, font_size: int, color := INK) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(item)
	return item

func style(fill: Color, border: Color, width := 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(4)
	return box

func button(text: String, rect: Rect2, action: Callable, primary := false) -> Button:
	var item := Button.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.add_theme_font_size_override("font_size", 30 if primary else 20)
	item.add_theme_color_override("font_color", Color("111827") if primary else INK)
	item.add_theme_color_override("font_focus_color", Color("111827") if primary else INK)
	item.add_theme_color_override("font_hover_color", Color("111827") if primary else Color.WHITE)
	item.add_theme_color_override("font_pressed_color", Color("111827") if primary else Color.WHITE)
	item.add_theme_stylebox_override("normal", style(Color("f97316") if primary else Color("163142"), Color("ffedd5") if primary else Color("8ecae6")))
	item.add_theme_stylebox_override("hover", style(Color("fb923c") if primary else Color("1f4f68"), Color.WHITE))
	item.add_theme_stylebox_override("pressed", style(Color("facc15"), Color.WHITE))
	var focus := style(Color.TRANSPARENT, Color.WHITE, 3)
	focus.expand_margin_left = 4
	focus.expand_margin_right = 4
	focus.expand_margin_top = 4
	focus.expand_margin_bottom = 4
	item.add_theme_stylebox_override("focus", focus)
	item.pressed.connect(action)
	page.add_child(item)
	return item

func show_menu() -> void:
	new_page()
	label("TIROS LIBRES", Rect2(160, 78, 704, 86), 64, Color("f8fafc"))
	label("Apuntá, cargá el tiro y soltá en verde.", Rect2(110, 171, 804, 42), 24)
	label("Mejor marca (%s tiros): %s goles" % [shot_count, profile.get_value("scores", "shots_%s" % shot_count, 0)], Rect2(100, 237, 824, 46), 26, Color("ffe08a"))
	label("Dificultad del arquero", Rect2(220, 304, 584, 46), 24)
	difficulty_buttons.clear()
	var values := ["facil", "medio", "dificil"]
	var captions := ["FÁCIL", "MEDIO", "DIFÍCIL"]
	for i in range(3):
		var option := button(captions[i], Rect2(313 + i * 140, 354, 118, 48), select_difficulty.bind(values[i]))
		option.set_meta("difficulty", values[i])
		difficulty_buttons.append(option)
	refresh_difficulty()
	var aspect := button("⚙\nASPECTO", Rect2(828, 44, 96, 108), show_appearance)
	aspect.add_theme_font_size_override("font_size", 17)
	play_button = button("JUGAR", Rect2(372, 459, 280, 70), show_setup, true)
	label("Tip: los tiros muy centrados son más fáciles de atajar.", Rect2(62, 558, 900, 48), 20, Color("b7d4df"))
	play_button.grab_focus()

func select_difficulty(value: String) -> void:
	difficulty = value
	profile.set_value("settings", "difficulty", value)
	profile.save(SAVE_PATH)
	refresh_difficulty()

func refresh_difficulty() -> void:
	for option in difficulty_buttons:
		var selected: bool = option.get_meta("difficulty") == difficulty
		option.add_theme_stylebox_override("normal", style(Color("facc15") if selected else Color("163142"), Color("fffbeb") if selected else Color("8ecae6")))
		option.add_theme_color_override("font_color", Color("111827") if selected else INK)
		option.add_theme_color_override("font_focus_color", Color("111827") if selected else INK)

func start_game() -> void:
	start_button.disabled = true
	profile.set_value("settings", "shots", shot_count)
	profile.set_value("settings", "players", player_count)
	profile.save(SAVE_PATH)
	get_tree().change_scene_to_file("res://Main.tscn")

func show_appearance() -> void:
	new_page()
	label("CONFIGURACIÓN", Rect2(100, 55, 824, 76), 54, Color("f8fafc"))
	label("Aspecto de tu arquero", Rect2(200, 128, 624, 46), 24)
	var panel := Panel.new()
	panel.position = Vector2(232, 205)
	panel.size = Vector2(560, 278)
	panel.add_theme_stylebox_override("panel", style(Color("0e2230"), Color("8ecae6")))
	page.add_child(panel)
	label("Número", Rect2(265, 225, 150, 48), 21)
	var number := SpinBox.new()
	number.position = Vector2(452, 225)
	number.size = Vector2(250, 48)
	number.min_value = 1
	number.max_value = 99
	number.value = int(profile.get_value("appearance", "number", 10))
	number.add_theme_font_size_override("font_size", 24)
	number.value_changed.connect(func(value: float) -> void: save_appearance("number", int(value)))
	page.add_child(number)
	label("Cabello", Rect2(265, 300, 150, 48), 21)
	var hair := OptionButton.new()
	hair.position = Vector2(452, 300)
	hair.size = Vector2(250, 48)
	hair.add_theme_font_size_override("font_size", 20)
	for caption in ["RUBIO", "MOROCHO", "NEGRO"]:
		hair.add_item(caption)
	hair.select(clampi(int(profile.get_value("appearance", "hair", 1)), 0, 2))
	hair.item_selected.connect(func(value: int) -> void: save_appearance("hair", value))
	page.add_child(hair)
	label("Nombre", Rect2(265, 375, 150, 48), 21)
	var player_name := LineEdit.new()
	player_name.position = Vector2(452, 375)
	player_name.size = Vector2(250, 48)
	player_name.max_length = 16
	player_name.text = str(profile.get_value("appearance", "name", "Jugador"))
	player_name.add_theme_font_size_override("font_size", 20)
	player_name.text_changed.connect(func(value: String) -> void: save_appearance("name", value.strip_edges() if not value.strip_edges().is_empty() else "Jugador"))
	page.add_child(player_name)
	button("VOLVER", Rect2(382, 508, 260, 60), show_menu, true).grab_focus()

func save_appearance(key: String, value: Variant) -> void:
	profile.set_value("appearance", key, value)
	profile.save(SAVE_PATH)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		show_menu()
		get_viewport().set_input_as_handled()

func show_setup() -> void:
	new_page()
	label("CONFIGURAR RONDA", Rect2(60, 64, 904, 80), 54, Color("f8fafc"))
	label("Elegí cuántos jugadores y cuántos tiros tendrá cada uno.", Rect2(40, 144, 944, 46), 22)
	for x in [80, 544]:
		var card := Panel.new()
		card.position = Vector2(x, 220)
		card.size = Vector2(400, 176)
		card.add_theme_stylebox_override("panel", style(Color("0e2230"), Color("8ecae6")))
		page.add_child(card)
	label("Cantidad de tiros", Rect2(90, 230, 380, 40), 26, Color.WHITE)
	label("Cantidad de jugadores", Rect2(554, 230, 380, 40), 26, Color.WHITE)
	shot_minus = button("−", Rect2(110, 283, 54, 54), change_setup.bind(-1, 0))
	shot_plus = button("+", Rect2(396, 283, 54, 54), change_setup.bind(1, 0))
	player_minus = button("−", Rect2(574, 283, 54, 54), change_setup.bind(0, -1))
	player_plus = button("+", Rect2(860, 283, 54, 54), change_setup.bind(0, 1))
	shot_value = label("", Rect2(174, 270, 212, 76), 60, Color("fde68a"))
	player_value = label("", Rect2(638, 270, 212, 76), 60, Color("93c5fd"))
	label("De 5 a 15 tiros por persona", Rect2(90, 348, 380, 40), 18)
	label("De 1 a 4 personas, en este dispositivo", Rect2(554, 348, 380, 40), 18)
	setup_summary = label("", Rect2(40, 404, 944, 60), 20)
	start_button = button("EMPEZAR", Rect2(372, 477, 280, 66), start_game, true)
	button("VOLVER", Rect2(402, 559, 220, 54), show_menu)
	refresh_setup()
	start_button.grab_focus()

func change_setup(shots_delta: int, players_delta: int) -> void:
	shot_count = clampi(shot_count + shots_delta, 5, 15)
	player_count = clampi(player_count + players_delta, 1, 4)
	refresh_setup()

func refresh_setup() -> void:
	shot_value.text = str(shot_count)
	player_value.text = str(player_count)
	shot_minus.disabled = shot_count == 5
	shot_plus.disabled = shot_count == 15
	player_minus.disabled = player_count == 1
	player_plus.disabled = player_count == 4
	setup_summary.text = "%s tiros y atajadas contra la IA · Desempate por muerte súbita" % shot_count if player_count == 1 else "Un tiro por jugador en cada vuelta · %s remates en total" % (shot_count * player_count)
