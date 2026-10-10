extends Control

@export var save_path := "user://free_kick_3d.cfg"
const Visual = preload("res://ui/visual_theme.gd")
const INK := Visual.INK
const GraphicsQuality = preload("res://graphics_quality.gd")
const SmoothPolygon = preload("res://ui/smooth_polygon.gd")
const HOME_POSTER_SCALE := 0.8
const HOME_POSTER_OFFSET := Vector2(0, 80)
var smooth_polygons := SmoothPolygon.new()
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
	theme = Visual.create()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	if is_instance_valid(page) and page.has_meta("poster_home"):
		content.position.x = 0
	smooth_polygons.clear()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(content):
		return
	if not home_screen:
		draw_rect(Rect2(Vector2.ZERO, size), Visual.BASE)
	draw_set_transform(content.position, 0.0, content.scale)
	# Controls stay centered; the artwork bleeds to every viewport edge.
	var top := -content.position.y / content.scale.y
	var bottom := (size.y - content.position.y) / content.scale.y
	var left := -content.position.x / content.scale.x
	var right := (size.x - content.position.x) / content.scale.x
	if home_screen and page.has_meta("poster_home"):
		# The frame follows the viewport edges; the poster stays at the left edge.
		var edge_width := clampf((size.x / size.y - 1.0) / (16.0 / 9.0 - 1.0), 0.35, 1.0)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(0, top), Vector2(300, top), Vector2(60, bottom), Vector2(0, bottom)]), Visual.BASE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(0, top), Vector2(268, top), Vector2(237, 36), Vector2(63, 30), Vector2(0, 170)]), Visual.BLUE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(0, 204), Vector2(54, 105), Vector2(72, 105), Vector2(27, 217), Vector2(48, 213), Vector2(0, 334)]), Visual.ACCENT)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(0, 370), Vector2(95, 343), Vector2(0, bottom)]), Visual.BLUE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(20, bottom), Vector2(104, 479), Vector2(125, 473), Vector2(45, bottom)]), Visual.ACCENT)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(68, 534), Vector2(402, 510), Vector2(340, bottom), Vector2(28, bottom)]), Visual.BASE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(right, 174), Vector2(right, bottom), Vector2(right - 150 * edge_width, bottom)]), Visual.BASE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(right, 165), Vector2(right, 315), Vector2(right - 79 * edge_width, 496), Vector2(right - 108 * edge_width, 512), Vector2(right - 172 * edge_width, bottom), Vector2(right - 245 * edge_width, bottom)]), Visual.BLUE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(right - 126 * edge_width, bottom), Vector2(right - 59 * edge_width, 541), Vector2(right - 43 * edge_width, 534), Vector2(right - 107 * edge_width, bottom)]), Visual.ACCENT)
	elif home_screen:
		smooth_polygons.draw(self, PackedVector2Array([Vector2(left, top), Vector2(500 - top * 90 / 640, top), Vector2(500 - bottom * 90 / 640, bottom), Vector2(left, bottom)]), Visual.BASE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(left, top), Vector2(226 - top * 226 / 352, top), Vector2(left, 352 - left * 352 / 226)]), Visual.BLUE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(left, 348 - left * 178 / 112), Vector2(112, 170), Vector2(132, 170), Vector2(left, 380 - left * 210 / 132)]), Visual.ACCENT)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(right, bottom - 392), Vector2(right, bottom), Vector2(right - 180, bottom)]), Visual.BLUE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(right - 118, bottom), Vector2(right, bottom - 254), Vector2(right, bottom - 223), Vector2(right - 98, bottom)]), Visual.ACCENT)
	else:
		smooth_polygons.draw(self, PackedVector2Array([Vector2(left, top), Vector2(left + 42, top), Vector2(left, top + 92)]), Visual.BLUE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(right - 134, bottom), Vector2(right, bottom - 230), Vector2(right, bottom)]), Visual.BLUE)
		smooth_polygons.draw(self, PackedVector2Array([Vector2(right - 154, bottom), Vector2(right, bottom - 263), Vector2(right, bottom - 245), Vector2(right - 140, bottom)]), Visual.ACCENT)
	draw_set_transform(Vector2.ZERO)

func new_page() -> void:
	background.frame_home_poster(false)
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
	layout_content()

func label(text: String, rect: Rect2, font_size: int, color := INK) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.add_theme_font_override("font", Visual.DISPLAY if font_size >= 32 else Visual.BODY)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(item)
	return item

func separator(rect: Rect2) -> void:
	var line := ColorRect.new()
	line.color = Visual.LINE
	line.position = rect.position
	line.size = rect.size
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(line)

func style(fill: Color, border: Color, width := 1) -> StyleBoxFlat:
	var box := Visual.box(fill, border)
	box.set_border_width_all(width)
	return box

func button(text: String, rect: Rect2, action: Callable, primary := false, icon: Texture2D = null) -> Button:
	var item := Button.new()
	item.text = text
	item.icon = icon
	item.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item.position = rect.position
	item.size = rect.size
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Visual.style_button(item, primary)
	item.pressed.connect(action)
	page.add_child(item)
	return item

func show_menu() -> void:
	background.refresh_player(profile)
	new_page()
	home_screen = true
	page.set_meta("poster_home", true)
	background.frame_home_poster(true)
	layout_content()
	var poster := Control.new()
	poster.name = "HomePoster"
	poster.size = Vector2(540, 560)
	poster.position = HOME_POSTER_OFFSET
	poster.scale = Vector2.ONE * HOME_POSTER_SCALE
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(poster)
	var mark := preload("res://ui/poster_mark.gd").new()
	mark.position = Vector2(0, 36)
	mark.size = Vector2(530, 354)
	poster.add_child(mark)
	play_button = preload("res://ui/raster_action.gd").new()
	play_button.position = Vector2(24, 354)
	play_button.size = Vector2(514, 142)
	play_button.pressed.connect(show_setup)
	poster.add_child(play_button)
	var settings := preload("res://ui/raster_action.gd").new()
	settings.name = "ConfigureButton"
	settings.caption = "Configurar"
	settings.artwork = preload("res://ui/brand/configure-raster.png")
	settings.position = Vector2(74, 500)
	settings.size = Vector2(378, 64)
	settings.pressed.connect(show_settings)
	poster.add_child(settings)
	var best := int(profile.get_value("scores", "shots_%s" % shot_count, 0))
	# Dynamic record keeps its readable type size, outside the scaled artwork.
	var prefix := label("Mejor marca  ·", Rect2(80, 540, 152, 34), 19, Visual.INK)
	prefix.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	prefix.add_theme_font_override("font", Visual.EMPHASIS)
	var value := label(str(best), Rect2(235, 536, 58, 42), 32, Visual.ENERGY)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label("goles", Rect2(291, 541, 80, 34), 19, Visual.INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	play_button.grab_focus()

func show_settings() -> void:
	new_page()
	var heading := label("AJUSTES DE JUEGO", Rect2(80, 52, 864, 72), 56, Visual.INK)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var subtitle := label("Elegí el desafío, tu equipo y el sonido.", Rect2(80, 118, 864, 32), 19, Visual.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	separator(Rect2(80, 178, 864, 1))
	label("Desafío", Rect2(80, 202, 400, 36), 26).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label("Dificultad del arquero", Rect2(80, 251, 400, 30), 18, Visual.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var values := ["facil", "medio", "dificil"]
	var captions := ["FÁCIL", "MEDIO", "DIFÍCIL"]
	for i in range(3):
		var option := button(captions[i], Rect2(80 + i * 138, 296, 124, 48), select_difficulty.bind(values[i]))
		option.set_meta("difficulty", values[i])
		difficulty_buttons.append(option)
	refresh_difficulty()
	button("ELEGIR ARQUERO", Rect2(80, 374, 400, 48), show_keepers, false, Visual.ARROW)
	button("ELEGIR DELANTERO", Rect2(80, 438, 400, 48), show_strikers, false, Visual.ARROW)
	label("Imagen y sonido", Rect2(544, 202, 400, 36), 26).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label("Calidad gráfica", Rect2(544, 251, 400, 30), 18, Visual.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for i in range(3):
		var quality: String = GraphicsQuality.PROFILES[i]
		var option := button(quality.to_upper(), Rect2(544 + i * 138, 296, 124, 48), select_graphics_quality.bind(quality))
		option.set_meta("graphics_quality", quality)
		graphics_buttons.append(option)
	refresh_graphics_quality()
	label("Volumen", Rect2(544, 374, 200, 34), 20).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var volume_readout := label("%d%%" % roundi(sound_volume * 100.0), Rect2(864, 374, 80, 34), 22, Visual.MUTED)
	var volume_slider := HSlider.new()
	volume_slider.position = Vector2(544, 429)
	volume_slider.size = Vector2(400, 32)
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.value = roundf(sound_volume * 100.0)
	page.add_child(volume_slider)
	volume_slider.value_changed.connect(func(value: float) -> void:
		set_sound_volume(value / 100.0)
		volume_readout.text = "%d%%" % roundi(value)
	)
	button("CRÉDITOS", Rect2(544, 486, 400, 40), show_asset_credits)
	button("VOLVER", Rect2(80, 546, 230, 52), show_menu).grab_focus()
	label("Los ajustes se guardan automáticamente.", Rect2(350, 552, 594, 40), 17, Visual.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func show_asset_credits() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Créditos de personajes"
	var credits := RichTextLabel.new()
	credits.custom_minimum_size = Vector2(minf(580, get_viewport_rect().size.x - 48), 210)
	credits.bbcode_enabled = true
	credits.text = "[b]PLAYER: personaje completo y uniformes v4[/b]\nGenerados con [url=https://www.meshy.ai/]Meshy AI[/url] (Meshy 6 Lite), bajo [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url].\nAdaptación de malla, texturas, UV y skinning realizada por este proyecto.\n\n[b]Otros personajes y esqueleto compartido[/b]\nBase [url=https://static.makehumancommunity.org/about/license.html]MPFB / MakeHuman, CC0[/url]. Animaciones originales del proyecto."
	credits.meta_clicked.connect(func(link: Variant) -> void: OS.shell_open(str(link)))
	dialog.add_child(credits)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func select_graphics_quality(value: String) -> void:
	graphics_quality = GraphicsQuality.normalized(value)
	profile.set_value("settings", "graphics_quality", graphics_quality)
	profile.save(save_path)
	GraphicsQuality.apply(self, graphics_quality)
	refresh_graphics_quality()

func refresh_graphics_quality() -> void:
	for option in graphics_buttons:
		var selected: bool = option.get_meta("graphics_quality") == graphics_quality
		Visual.style_button(option, selected)
		option.add_theme_font_size_override("font_size", 19)
		option.icon = Visual.CHECK if selected else null
		option.add_theme_constant_override("h_separation", 6)
		option.add_theme_constant_override("icon_max_width", 18)

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
		Visual.style_button(option, selected)
		option.add_theme_font_size_override("font_size", 19)
		option.icon = Visual.CHECK if selected else null
		option.add_theme_constant_override("h_separation", 6)
		option.add_theme_constant_override("icon_max_width", 18)

func start_game() -> void:
	start_button.disabled = true
	profile.set_value("settings", "shot_mode", "tiro_libre")
	profile.set_value("settings", "shots", shot_count)
	profile.set_value("settings", "players", player_count)
	profile.save(save_path)
	get_tree().change_scene_to_file("res://Main.tscn")

func show_appearance() -> void:
	new_page()
	label("CONFIGURACIÓN", Rect2(100, 55, 824, 76), 54, Visual.INK)
	label("Nombre y número para tus camisetas", Rect2(200, 128, 624, 46), 24)
	var panel := Panel.new()
	panel.position = Vector2(232, 205)
	panel.size = Vector2(560, 278)
	panel.add_theme_stylebox_override("panel", style(Visual.SURFACE, Visual.LINE))
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
		if page.has_meta("editor"):
			if editing_role == "keeper": show_keepers()
			else: show_strikers()
		elif page.has_meta("roster"):
			show_settings()
		else:
			show_menu()
		get_viewport().set_input_as_handled()

func show_setup() -> void:
	new_page()
	label("PREPARÁ TU RONDA", Rect2(60, 64, 904, 80), 54, Visual.INK)
	label("Elegí cuántos jugadores y cuántos tiros tendrá cada uno.", Rect2(40, 144, 944, 46), 22)
	for x in [80, 544]:
		var card := preload("res://ui/poster_panel.gd").new()
		card.position = Vector2(x, 220)
		card.size = Vector2(400, 176)
		page.add_child(card)
	label("Cantidad de tiros", Rect2(90, 230, 380, 40), 26, Visual.INK)
	label("Cantidad de jugadores", Rect2(554, 230, 380, 40), 26, Visual.INK)
	shot_minus = button("−", Rect2(110, 283, 54, 54), change_setup.bind(-1, 0))
	shot_plus = button("+", Rect2(396, 283, 54, 54), change_setup.bind(1, 0))
	player_minus = button("−", Rect2(574, 283, 54, 54), change_setup.bind(0, -1))
	player_plus = button("+", Rect2(860, 283, 54, 54), change_setup.bind(0, 1))
	shot_value = label("", Rect2(174, 270, 212, 76), 60, Visual.ENERGY)
	player_value = label("", Rect2(638, 270, 212, 76), 60, Visual.INK)
	label("De 5 a 15 tiros por persona", Rect2(90, 348, 380, 40), 18)
	label("De 1 a 4 personas, en este dispositivo", Rect2(554, 348, 380, 40), 18)
	setup_summary = label("", Rect2(40, 405, 944, 32), 20)
	label("TIROS LIBRES · 24 metros", Rect2(312, 434, 400, 36), 20, Visual.ENERGY)
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
	var heading := label("ELEGÍ TU\nDELANTERO",Rect2(60,70,460,135),46,Visual.INK)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	page.set_meta("roster", true)
	var profiles = preload("res://footballer_model.gd").PROFILES
	var selected := int(profile.get_value("appearance","striker",0))
	for i in range(profiles.size()):
		var option := button(profiles[i].name,Rect2(64,225+i*68,300,54),select_striker.bind(i),i==selected,Visual.CHECK if i == selected else null)
		option.add_theme_font_size_override("font_size", 20)
		if i == selected: option.grab_focus()
	var custom := button("PERSONALIZADO",Rect2(64,429,300,54),show_custom_striker,selected==3,Visual.CHECK if selected == 3 else null)
	custom.add_theme_font_size_override("font_size", 20)
	if selected == 3: custom.grab_focus()
	var meshy_index: int = preload("res://footballer_model.gd").MESHY_STRIKER_INDEX
	var generated := button("PLAYER",Rect2(64,497,300,54),select_striker.bind(meshy_index),selected==meshy_index,Visual.CHECK if selected == meshy_index else null)
	generated.add_theme_font_size_override("font_size", 20)
	if selected == meshy_index: generated.grab_focus()
	button("VOLVER",Rect2(64,565,300,54),show_settings)

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
	var heading := label("ELEGÍ TU ARQUERO",Rect2(60,70,490,90),40,Visual.INK)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var selected := int(profile.get_value("appearance","keeper",0))
	page.set_meta("roster", true)
	var names := ["MATEO","BRUNO","NICOLÁS"]
	for i in range(3):
		var option := button(names[i],Rect2(64,205+i*65,300,54),select_keeper.bind(i),selected==i,Visual.CHECK if i == selected else null)
		option.add_theme_font_size_override("font_size", 20)
		if selected == i: option.grab_focus()
	button("AL AZAR",Rect2(64,400,300,54),func() -> void: select_keeper(randi_range(0,2)))
	var custom := button("PERSONALIZADO",Rect2(64,465,300,54),show_custom_keeper,selected==3,Visual.CHECK if selected == 3 else null)
	custom.add_theme_font_size_override("font_size", 20)
	if selected == 3: custom.grab_focus()
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
	page.set_meta("editor", true)
	label("TU ARQUERO" if role == "keeper" else "TU DELANTERO",Rect2(64,35,420,65),38,Visual.INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label("Nombre", Rect2(64, 99, 300, 24), 16, Visual.MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
		label(captions[i],Rect2(64,188+i*58,140,44),20).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	button("LISTO",Rect2(64,515,300,58),show_keepers if role == "keeper" else show_strikers,true).grab_focus()

func save_custom(key: String,value: Variant) -> void:
	profile.set_value("custom_"+editing_role,key,value)
	profile.save(save_path)
	refresh_character_preview()
