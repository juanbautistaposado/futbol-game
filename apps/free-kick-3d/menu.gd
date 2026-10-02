extends Control

@export var save_path := "user://free_kick_3d.cfg"
const INK := Color("d7f7ff")
const GraphicsQuality = preload("res://graphics_quality.gd")
var background: Node3D
var editing_role := "striker"
var home_screen := true
var profile := ConfigFile.new()
var page: Control
var content: Control
var play_button: Button
var difficulty_buttons: Array[Button] = []
var graphics_buttons: Array[Button] = []
var difficulty := "medio"
var graphics_quality := "alto"
var sound_volume := 0.8
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
	profile.load(save_path)
	shot_count = clampi(int(profile.get_value("settings", "shots", 7)), 5, 15)
	player_count = clampi(int(profile.get_value("settings", "players", 1)), 1, 4)
	difficulty = str(profile.get_value("settings", "difficulty", "medio"))
	graphics_quality = GraphicsQuality.normalized(str(profile.get_value("settings", "graphics_quality", "alto")))
	sound_volume = clampf(float(profile.get_value("settings", "sound_volume", 0.8)), 0.0, 1.0)
	preload("res://match_audio.gd").set_global_volume(sound_volume)
	if difficulty not in ["facil", "medio", "dificil"]:
		difficulty = "medio"
	background = preload("res://menu_background.gd").new()
	add_child(background)
	GraphicsQuality.apply(self, graphics_quality)
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
	# Transparent shading keeps the live stadium visible behind the menu.
	if not home_screen:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.035,0.065,0.9))
		return
	draw_polygon(PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]),PackedColorArray([Color(0.015,0.035,0.065,0.85),Color(0.015,0.035,0.065,0),Color(0.015,0.035,0.065,0),Color(0.015,0.035,0.065,0.85)]))

func new_page() -> void:
	home_screen = false
	difficulty_buttons.clear()
	graphics_buttons.clear()
	queue_redraw()
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
	background.refresh_player(profile)
	new_page()
	home_screen = true
	queue_redraw()
	var title := label("TIROS
LIBRES",Rect2(60,70,410,165),72,Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var subtitle := label("TU CANCHA. TU MOMENTO.",Rect2(64,278,410,36),20,Color("8ed9f2"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	play_button = button("JUGAR",Rect2(64,380,300,66),show_setup,true)
	button("CONFIGURAR",Rect2(64,460,300,60),show_settings)
	var record := label("MEJOR MARCA  ·  %s GOLES" % profile.get_value("scores","shots_%s" % shot_count,0),Rect2(64,548,410,36),18,Color("b7d4df"))
	record.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	play_button.grab_focus()

func show_settings() -> void:
	new_page()
	label("CONFIGURAR",Rect2(100,43,824,76),52,Color.WHITE)
	label("Dificultad del arquero",Rect2(200,132,624,42),26)
	var values := ["facil","medio","dificil"]
	var captions := ["FÁCIL","MEDIO","DIFÍCIL"]
	for i in range(3):
		var option := button(captions[i],Rect2(262+i*180,181,160,47),select_difficulty.bind(values[i]))
		option.set_meta("difficulty",values[i])
		difficulty_buttons.append(option)
	refresh_difficulty()
	label("Calidad gráfica",Rect2(200,241,624,38),26)
	for i in range(3):
		var quality: String = GraphicsQuality.PROFILES[i]
		var option := button(quality.to_upper(),Rect2(262+i*180,284,160,46),select_graphics_quality.bind(quality))
		option.set_meta("graphics_quality",quality)
		graphics_buttons.append(option)
	refresh_graphics_quality()
	button("ELEGIR ARQUERO",Rect2(302,355,420,48),show_keepers)
	button("ELEGIR DELANTERO",Rect2(302,413,420,48),show_strikers)
	label("Volumen",Rect2(270,475,180,38),24)
	var volume_slider := HSlider.new()
	volume_slider.position = Vector2(448,479)
	volume_slider.size = Vector2(244,32)
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.value = roundf(sound_volume * 100.0)
	page.add_child(volume_slider)
	var volume_readout := label("%d%%" % roundi(sound_volume * 100.0),Rect2(700,473,80,42),22)
	volume_slider.value_changed.connect(func(value: float) -> void:
		set_sound_volume(value / 100.0)
		volume_readout.text = "%d%%" % roundi(value)
	)
	button("VOLVER",Rect2(382,550,260,58),show_menu,true).grab_focus()

func select_graphics_quality(value: String) -> void:
	graphics_quality = GraphicsQuality.normalized(value)
	profile.set_value("settings", "graphics_quality", graphics_quality)
	profile.save(save_path)
	GraphicsQuality.apply(self, graphics_quality)
	refresh_graphics_quality()

func refresh_graphics_quality() -> void:
	for option in graphics_buttons:
		var selected: bool = option.get_meta("graphics_quality") == graphics_quality
		option.add_theme_stylebox_override("normal", style(Color("facc15") if selected else Color("163142"), Color("fffbeb") if selected else Color("8ecae6")))
		option.add_theme_color_override("font_color", Color("111827") if selected else INK)
		option.add_theme_color_override("font_focus_color", Color("111827") if selected else INK)

func set_sound_volume(value: float) -> void:
	sound_volume = clampf(value, 0.0, 1.0)
	profile.set_value("settings", "sound_volume", sound_volume)
	profile.save(save_path)
	preload("res://match_audio.gd").set_global_volume(sound_volume)

func select_difficulty(value: String) -> void:
	difficulty = value
	profile.set_value("settings", "difficulty", value)
	profile.save(save_path)
	refresh_difficulty()

func refresh_difficulty() -> void:
	for option in difficulty_buttons:
		var selected: bool = option.get_meta("difficulty") == difficulty
		option.add_theme_stylebox_override("normal", style(Color("facc15") if selected else Color("163142"), Color("fffbeb") if selected else Color("8ecae6")))
		option.add_theme_color_override("font_color", Color("111827") if selected else INK)
		option.add_theme_color_override("font_focus_color", Color("111827") if selected else INK)

func start_game() -> void:
	start_button.disabled = true
	profile.set_value("settings", "shot_mode", "tiro_libre")
	profile.set_value("settings", "shots", shot_count)
	profile.set_value("settings", "players", player_count)
	profile.save(save_path)
	get_tree().change_scene_to_file("res://Main.tscn")

func show_appearance() -> void:
	new_page()
	label("CONFIGURACIÓN", Rect2(100, 55, 824, 76), 54, Color("f8fafc"))
	label("Nombre y número para tus camisetas", Rect2(200, 128, 624, 46), 24)
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
	button("VOLVER", Rect2(382, 508, 260, 60), show_settings, true).grab_focus()

func save_appearance(key: String, value: Variant) -> void:
	profile.set_value("appearance", key, value)
	profile.save(save_path)

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
	setup_summary = label("", Rect2(40, 392, 944, 36), 20)
	label("TIROS LIBRES · 24 metros", Rect2(312, 434, 400, 36), 20, Color("fde68a"))
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

func show_strikers() -> void:
	background.refresh_player(profile)
	new_page()
	home_screen = true
	queue_redraw()
	var heading := label("ELEGÍ TU\nDELANTERO",Rect2(60,70,460,135),46,Color.WHITE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var profiles = preload("res://footballer_model.gd").PROFILES
	var selected := int(profile.get_value("appearance","striker",0))
	for i in range(profiles.size()):
		var option := button(profiles[i].name+ (" ✓" if i == selected else ""),Rect2(64,225+i*68,300,54),select_striker.bind(i),i==selected)
		if i == selected: option.grab_focus()
	button("PERSONALIZADO",Rect2(64,429,300,54),show_custom_striker,selected==3)
	button("VOLVER",Rect2(64,515,300,54),show_settings)

func select_striker(index: int) -> void:
	profile.set_value("appearance","striker",index)
	profile.save(save_path)
	background.refresh_player(profile)
	show_strikers()

func show_keepers() -> void:
	new_page()
	home_screen = true
	queue_redraw()
	background.show_keeper(profile)
	var heading := label("ELEGÍ TU ARQUERO",Rect2(60,70,490,90),40,Color.WHITE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var selected := int(profile.get_value("appearance","keeper",0))
	var names := ["MATEO","BRUNO","NICOLÁS"]
	for i in range(3):
		button(names[i]+(" ✓" if selected==i else ""),Rect2(64,205+i*65,300,54),select_keeper.bind(i),selected==i)
	button("AL AZAR",Rect2(64,400,300,54),func() -> void: select_keeper(randi_range(0,2)))
	button("PERSONALIZADO",Rect2(64,465,300,54),show_custom_keeper,selected==3)
	button("VOLVER",Rect2(64,545,300,54),show_settings)

func select_keeper(index: int) -> void:
	profile.set_value("appearance","keeper",index)
	profile.set_value("appearance","hair",[2,2,1][index])
	profile.save(save_path)
	show_keepers()

func show_custom_striker() -> void:
	show_character_editor("striker")

func show_custom_keeper() -> void:
	show_character_editor("keeper")

func refresh_character_preview() -> void:
	if editing_role == "keeper": background.show_keeper(profile)
	else: background.refresh_player(profile)

func show_character_editor(role: String) -> void:
	editing_role = role
	var section := "custom_"+role
	var name_key := "keeper_name" if role == "keeper" else "name"
	var number_key := "keeper_number" if role == "keeper" else "number"
	if not profile.has_section_key("appearance",name_key):
		profile.set_value("appearance",name_key,profile.get_value("appearance","name","Jugador"))
	if not profile.has_section_key("appearance",number_key):
		profile.set_value("appearance",number_key,profile.get_value("appearance","number",10))
	profile.set_value("appearance",role,3)
	profile.save(save_path)
	refresh_character_preview()
	new_page()
	home_screen = true
	queue_redraw()
	label("TU ARQUERO" if role == "keeper" else "TU DELANTERO",Rect2(40,35,420,75),38,Color.WHITE)
	var name_input := LineEdit.new()
	name_input.position = Vector2(64,125)
	name_input.size = Vector2(300,44)
	name_input.placeholder_text = "Tu nombre"
	name_input.max_length = 16
	name_input.text = str(profile.get_value("appearance",name_key,profile.get_value("appearance","name","Jugador")))
	name_input.text_changed.connect(func(value: String) -> void:
		save_appearance(name_key,value.strip_edges() if not value.strip_edges().is_empty() else "Jugador")
		refresh_character_preview()
	)
	page.add_child(name_input)
	var fields := ["skin","hair","shirt","shorts"]
	var captions := ["Piel","Cabello","Camiseta","Short"]
	var defaults := ["bb8868","29221f","245baa","172f58"]
	for i in range(4):
		label(captions[i],Rect2(64,188+i*58,140,44),22)
		var picker := ColorPickerButton.new()
		picker.position = Vector2(224,188+i*58)
		picker.size = Vector2(140,44)
		picker.edit_alpha = false
		picker.color = Color(str(profile.get_value(section,fields[i],defaults[i])))
		picker.color_changed.connect(func(color: Color) -> void: save_custom(fields[i],color.to_html(false)))
		page.add_child(picker)
	var beard := CheckButton.new()
	beard.text = "Barba"
	beard.position = Vector2(64,430)
	beard.size = Vector2(150,44)
	beard.button_pressed = bool(profile.get_value(section,"beard",false))
	beard.toggled.connect(func(value: bool) -> void: save_custom("beard",value))
	page.add_child(beard)
	var number := SpinBox.new()
	number.position = Vector2(224,430)
	number.size = Vector2(140,44)
	number.min_value = 1
	number.max_value = 99
	number.prefix = "N° "
	number.value = int(profile.get_value("appearance",number_key,profile.get_value("appearance","number",10)))
	number.value_changed.connect(func(value: float) -> void:
		save_appearance(number_key,int(value))
		refresh_character_preview()
	)
	page.add_child(number)
	button("LISTO",Rect2(64,515,300,58),show_keepers if role == "keeper" else show_strikers,true)

func save_custom(key: String,value: Variant) -> void:
	profile.set_value("custom_"+editing_role,key,value)
	profile.save(save_path)
	refresh_character_preview()
