extends Control
## The editor owns presentation; the menu persists changes and renders the 3D preview.

signal appearance_changed(key: String, value: Variant)
signal close_requested
signal preview_mode_changed(mode: String)
signal rotation_requested(amount: float)

const Visual = preload("res://ui/visual_theme.gd")
const BODY: Font = Visual.BODY
const EMPHASIS: Font = Visual.EMPHASIS
const DISPLAY: Font = Visual.DISPLAY
const CHECK: Texture2D = Visual.CHECK
const WHITE := Visual.INK
const MUTED := Visual.MUTED
const ENERGY := Visual.ENERGY
const SURFACE := Visual.BASE
const FIELD := Visual.SURFACE
const LINE := Visual.LINE
const TAB_NAMES: Array[String] = ["Identidad", "Aspecto", "Indumentaria"]
const SKIN_COLORS: Array[String] = ["efc9ab", "deb294", "cfa183", "bb8868", "aa7858", "986345", "805135", "6b432e", "573722"]
const HAIR_COLORS: Array[String] = ["171616", "29221f", "70513a", "a08050", "c5aa6a", "c6c5c2"]
const KIT_COLORS: Array[String] = ["ebebdf", "245baa", "c53938", "22724f", "774ba3", "172438"]

var profile: ConfigFile
var role := "striker"
var active_tab := 0
var active_field := "skin"
var _values: Dictionary = {}
var _tabs: Array[Button] = []
var _content: Control
var _title: Label
var _content_focus: Array[Control] = []
var _footer_focus: Array[Control] = []
var _swatches: Array[Button] = []
var _picker: ColorPickerButton
var _selection_label: Label
var _built := false

func configure(config: ConfigFile, editing_role: String) -> void:
	profile = config
	role = editing_role
	var section := "custom_" + role
	var name_key := "keeper_name" if role == "keeper" else "name"
	var number_key := "keeper_number" if role == "keeper" else "number"
	_values = {
		name_key: str(profile.get_value("appearance", name_key, profile.get_value("appearance", "name", "Jugador"))),
		number_key: int(profile.get_value("appearance", number_key, profile.get_value("appearance", "number", 10))),
		"skin": str(profile.get_value(section, "skin", "bb8868")),
		"hair": str(profile.get_value(section, "hair", "29221f")),
		"shirt": str(profile.get_value(section, "shirt", "245baa")),
		"shorts": str(profile.get_value(section, "shorts", "172f58")),
		"beard": bool(profile.get_value(section, "beard", false)),
	}
	if _built:
		_title.text = "TU ARQUERO" if role == "keeper" else "TU DELANTERO"
		_show_tab(active_tab)

func _ready() -> void:
	if profile == null:
		configure(ConfigFile.new(), role)
	size = Vector2(1024, 640)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _create_theme()
	_title = _label("TU ARQUERO" if role == "keeper" else "TU DELANTERO", Rect2(46, 31, 700, 45), 32, WHITE, true)
	for i in range(TAB_NAMES.size()):
		var tab := _button(TAB_NAMES[i], Rect2(46 + i * 150, 101, 142, 45), _show_tab.bind(i))
		tab.name = ["CategoryIdentity", "CategoryAppearance", "CategoryKit"][i]
		_tabs.append(tab)
	_panel(Rect2(46, 150, 932, 1), LINE)
	_content = Control.new()
	_content.name = "CategoryContent"
	_content.position = Vector2(46, 188)
	_content.size = Vector2(348, 348)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_panel(Rect2(46, 574, 932, 1), LINE)
	var done := _button("LISTO", Rect2(46, 589, 124, 38), func() -> void: close_requested.emit())
	_style_button(done, true)
	done.add_theme_font_override("font", DISPLAY)
	done.add_theme_font_size_override("font_size", 18)
	_footer_focus.append(done)
	var back := _button("VOLVER", Rect2(184, 589, 116, 38), func() -> void: close_requested.emit())
	_footer_focus.append(back)
	var rotate_left := _button("Girar −", Rect2(674, 589, 94, 38), func() -> void: rotation_requested.emit(-0.3))
	var rotate_right := _button("Girar +", Rect2(778, 589, 94, 38), func() -> void: rotation_requested.emit(0.3))
	_footer_focus.append(rotate_left)
	_footer_focus.append(rotate_right)
	_label("Esc · Volver", Rect2(884, 596, 94, 24), 13, MUTED)
	_built = true
	_show_tab(active_tab)
	_tabs[active_tab].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_show_tab(posmod(active_tab - 1, TAB_NAMES.size()))
			_tabs[active_tab].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_show_tab((active_tab + 1) % TAB_NAMES.size())
			_tabs[active_tab].grab_focus()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_PAGEUP or event.keycode == KEY_PAGEDOWN:
			_show_tab(posmod(active_tab + (-1 if event.keycode == KEY_PAGEUP else 1), TAB_NAMES.size()))
			_tabs[active_tab].grab_focus()
			get_viewport().set_input_as_handled()

func _show_tab(index: int) -> void:
	active_tab = index
	for i in range(_tabs.size()):
		_style_tab(_tabs[i], i == active_tab)
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_content_focus.clear()
	_swatches.clear()
	_picker = null
	_selection_label = null
	match active_tab:
		0: _build_identity()
		1:
			if active_field not in ["skin", "hair", "beard"]: active_field = "skin"
			_build_appearance()
		2:
			if active_field not in ["shirt", "shorts"]: active_field = "shirt"
			_build_kit()
	_wire_focus()
	_tabs[active_tab].grab_focus()
	preview_mode_changed.emit("face" if active_tab == 1 else "body")

func _build_identity() -> void:
	_content_label("IDENTIDAD DEL JUGADOR", Rect2(0, 0, 348, 28), 18, WHITE, true)
	_content_label("Nombre en la camiseta", Rect2(0, 59, 348, 24), 16)
	var name_key := "keeper_name" if role == "keeper" else "name"
	var entry := LineEdit.new()
	entry.name = "NameInput"
	entry.position = Vector2(0, 89)
	entry.size = Vector2(348, 49)
	entry.max_length = 16
	entry.text = str(_values[name_key])
	entry.placeholder_text = "Jugador"
	entry.text_changed.connect(func(value: String) -> void: _change(name_key, "Jugador" if value.strip_edges().is_empty() else value.strip_edges()))
	_content.add_child(entry)
	_content_focus.append(entry)
	_content_label("Hasta 16 caracteres", Rect2(0, 143, 348, 24), 13)
	_content_label("Número", Rect2(0, 197, 240, 24), 16)
	var number_key := "keeper_number" if role == "keeper" else "number"
	var number := SpinBox.new()
	number.name = "NumberInput"
	number.position = Vector2(0, 228)
	number.size = Vector2(348, 49)
	number.min_value = 1
	number.max_value = 99
	number.value = int(_values[number_key])
	number.value_changed.connect(func(value: float) -> void: _change(number_key, int(value)))
	_content.add_child(number)
	_content_focus.append(number.get_line_edit())
	_content_label("Los cambios se guardan automáticamente.", Rect2(0, 306, 348, 24), 13)

func _build_appearance() -> void:
	_field_tabs(["Piel", "Cabello", "Barba"], ["skin", "hair", "beard"])
	if active_field == "beard":
		_build_facial_hair("BARBA Y BIGOTE", "beard", "Beard", "barba", 67)
		_content_label("El color sigue el tono del cabello.", Rect2(0, 199, 348, 24), 14)
	else:
		_build_colors("TONO DE PIEL" if active_field == "skin" else "COLOR DEL CABELLO", SKIN_COLORS if active_field == "skin" else HAIR_COLORS)

func _build_facial_hair(caption: String, key: String, node_prefix: String, label: String, top: float) -> void:
	_content_label(caption, Rect2(0, top, 348, 30), 18, WHITE, true)
	for i in range(2):
		var enabled := i == 1
		var option := _content_button(("Con " if enabled else "Sin ") + label, Rect2(i * 178, top + 43, 170, 62), _set_facial_hair.bind(key, enabled))
		option.name = node_prefix + ("On" if enabled else "Off")
		_style_button(option, bool(_values[key]) == enabled)

func _build_kit() -> void:
	_field_tabs(["Camiseta", "Short"], ["shirt", "shorts"])
	_build_colors("COLOR DE CAMISETA" if active_field == "shirt" else "COLOR DEL SHORT", KIT_COLORS)

func _field_tabs(captions: Array, keys: Array) -> void:
	var width := (348.0 - 8.0 * (keys.size() - 1)) / keys.size()
	for i in range(keys.size()):
		var key: String = keys[i]
		var item := _content_button(str(captions[i]), Rect2(i * (width + 8), 0, width, 44), _select_field.bind(key))
		item.name = "Field" + key.capitalize()
		_style_button(item, key == active_field)

func _select_field(key: String) -> void:
	active_field = key
	_show_tab(active_tab)
	var selected := _content.get_node_or_null("Field" + key.capitalize()) as Control
	if selected != null: selected.grab_focus()

func _build_colors(caption: String, colors: Array[String]) -> void:
	_content_label(caption, Rect2(0, 65, 348, 30), 18, WHITE, true)
	var grid := GridContainer.new()
	grid.position = Vector2(0, 108)
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_content.add_child(grid)
	var dense := colors.size() > 6
	var swatch_height := 48 if dense else 66
	for i in range(colors.size()):
		var hex := colors[i]
		var item := Button.new()
		item.name = "Field" + active_field.capitalize() + "Swatch" + str(i)
		item.custom_minimum_size = Vector2(108, swatch_height)
		item.tooltip_text = caption.capitalize() + " · " + str(i + 1)
		item.set_meta("color_hex", hex)
		item.pressed.connect(_set_color.bind(hex))
		grid.add_child(item)
		var mark := TextureRect.new()
		mark.name = "SelectedMark"
		mark.texture = CHECK
		mark.position = Vector2(80, 7)
		mark.size = Vector2(20, 20)
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.modulate = SURFACE if Color(hex).get_luminance() > 0.4 else WHITE
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(mark)
		_swatches.append(item)
		_content_focus.append(item)
	var picker_top := 296 if dense else 262
	_content_label("Color personalizado", Rect2(0, picker_top + 9, 240, 30), 16, WHITE)
	_picker = ColorPickerButton.new()
	_picker.name = active_field.capitalize() + "Picker"
	_picker.position = Vector2(270, picker_top)
	_picker.size = Vector2(78, 44)
	_picker.edit_alpha = false
	_picker.color = Color(str(_values[active_field]))
	_picker.tooltip_text = "Elegir cualquier color"
	_picker.color_changed.connect(func(color: Color) -> void: _set_color(color.to_html(false)))
	_content.add_child(_picker)
	_picker.get_popup().theme = theme
	_picker.get_picker().theme = theme
	_content_focus.append(_picker)
	_selection_label = _content_label("", Rect2(0, picker_top + 56, 348, 24), 13)
	_update_color_selection()

func _set_color(hex: String) -> void:
	_change(active_field, hex)
	if _picker != null: _picker.color = Color(hex)
	_update_color_selection()

func _update_color_selection() -> void:
	var chosen := str(_values[active_field]).to_lower()
	var preset := false
	for item in _swatches:
		var hex := str(item.get_meta("color_hex"))
		var selected := hex == chosen
		preset = preset or selected
		var fill := Color(hex)
		item.add_theme_stylebox_override("normal", _box(fill, ENERGY if selected else LINE, 3 if selected else 1))
		item.add_theme_stylebox_override("hover", _box(fill.lightened(0.08), WHITE, 2))
		item.add_theme_stylebox_override("pressed", _box(fill, ENERGY, 3))
		item.get_node("SelectedMark").visible = selected
	_selection_label.text = "Muestra seleccionada" if preset else "Color personalizado seleccionado"

func _set_facial_hair(key: String, enabled: bool) -> void:
	_change(key, enabled)
	_build_refresh()

func _build_refresh() -> void:
	_show_tab(active_tab)
	if not _content_focus.is_empty(): _content_focus[0].grab_focus()

func _change(key: String, value: Variant) -> void:
	_values[key] = value
	appearance_changed.emit(key, value)

func _wire_focus() -> void:
	var controls: Array[Control] = []
	controls.append_array(_tabs)
	controls.append_array(_content_focus)
	controls.append_array(_footer_focus)
	for i in range(controls.size()):
		controls[i].focus_next = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[posmod(i - 1, controls.size())])
	for item in _tabs:
		if not _content_focus.is_empty(): item.focus_neighbor_bottom = item.get_path_to(_content_focus[0])
	for item in _footer_focus:
		if not _content_focus.is_empty(): item.focus_neighbor_top = item.get_path_to(_content_focus.back())

func _create_theme() -> Theme:
	var result := Visual.create()
	result.default_font_size = 17
	result.set_stylebox("normal", "LineEdit", _box(FIELD, LINE))
	result.set_stylebox("focus", "LineEdit", _box(FIELD, ENERGY, 2))
	for kind in ["Button", "ColorPickerButton"]:
		result.set_stylebox("normal", kind, _box(FIELD, LINE))
		result.set_stylebox("hover", kind, _box(Visual.BLUE, WHITE))
		result.set_stylebox("pressed", kind, _box(FIELD, ENERGY))
		result.set_stylebox("disabled", kind, _box(SURFACE, LINE))
		result.set_color("font_hover_color", kind, WHITE)
		result.set_color("font_pressed_color", kind, WHITE)
		result.set_color("font_disabled_color", kind, MUTED)
		result.set_stylebox("focus", kind, _box(Color.TRANSPARENT, ENERGY, 2))
	result.set_stylebox("panel", "PopupPanel", _box(FIELD, LINE))
	result.set_stylebox("panel", "Panel", _box(FIELD, LINE))
	return result

func _box(fill: Color, edge: Color = Color.TRANSPARENT, border: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func _style_button(item: Button, selected: bool = false) -> void:
	Visual.style_button(item, selected)
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed"]:
		if selected:
			# Scale the complete plate, preserving the cut at compact field widths.
			var plate := StyleBoxTexture.new()
			plate.texture = Visual.HOVER_PLATE if state == "hover" else Visual.PRESSED_PLATE if state == "pressed" else Visual.ACTION_PLATE
			plate.content_margin_left = 12
			plate.content_margin_right = 16
			plate.content_margin_top = 6
			plate.content_margin_bottom = 8
			item.add_theme_stylebox_override(state, plate)
		else:
			var box := _box(Visual.BLUE if state == "hover" else FIELD, WHITE if state == "hover" else LINE)
			box.border_width_bottom = 3
			item.add_theme_stylebox_override(state, box)
	var focus := _box(Color.TRANSPARENT, ENERGY, 2)
	item.add_theme_stylebox_override("focus", focus)

func _style_tab(item: Button, selected: bool) -> void:
	_style_button(item)
	for state in ["normal", "hover", "pressed"]:
		var box := _box(Visual.BLUE if selected or state != "normal" else Color.TRANSPARENT, ENERGY if selected else WHITE, 0)
		box.border_width_bottom = 3 if selected else (1 if state == "hover" else 0)
		item.add_theme_stylebox_override(state, box)
	item.add_theme_color_override("font_color", WHITE if selected else MUTED)
	item.add_theme_color_override("font_pressed_color", WHITE)

func _panel(rect: Rect2, color: Color) -> void:
	var item := ColorRect.new()
	item.position = rect.position
	item.size = rect.size
	item.color = color
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item)

func _label(text: String, rect: Rect2, font_size: int, color: Color = MUTED, emphasis: bool = false, parent: Control = self) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_override("font", DISPLAY if emphasis else BODY)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func _content_label(text: String, rect: Rect2, font_size: int, color: Color = MUTED, emphasis: bool = false) -> Label:
	return _label(text, rect, font_size, color, emphasis, _content)

func _button(text: String, rect: Rect2, callback: Callable, parent: Control = self) -> Button:
	var item := Button.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.pressed.connect(callback)
	parent.add_child(item)
	_style_button(item)
	return item

func _content_button(text: String, rect: Rect2, callback: Callable) -> Button:
	var item := _button(text, rect, callback, _content)
	_content_focus.append(item)
	return item
