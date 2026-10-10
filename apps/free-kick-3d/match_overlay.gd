extends CanvasLayer
const Visual = preload("res://ui/visual_theme.gd")
signal exit_requested
signal pause_changed(paused: bool)
var result_label: Label
var pause_panel: Control
var pause_button: Button
var resume_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	var root := Control.new()
	root.theme = Visual.create()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	result_label = Label.new()
	root.add_child(result_label)
	result_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_label.anchor_left = 0.0
	result_label.anchor_right = 1.0
	result_label.offset_left = 24
	result_label.offset_right = -24
	result_label.offset_top = -65
	result_label.offset_bottom = 65
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_override("font", Visual.DISPLAY)
	result_label.add_theme_font_size_override("font_size",80)
	result_label.add_theme_color_override("font_outline_color",Visual.BASE)
	result_label.add_theme_constant_override("outline_size",8)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_label.hide()
	pause_button = button("Pausa",root)
	pause_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pause_button.icon = Visual.PAUSE
	pause_button.add_theme_stylebox_override("normal", preload("res://ui/visual_theme.gd").box(Visual.BASE, Visual.BASE))
	var pause_plate := StyleBoxTexture.new()
	pause_plate.texture = preload("res://ui/plates/pause.svg")
	pause_plate.texture_margin_left = 0
	pause_plate.texture_margin_right = 0
	pause_plate.texture_margin_top = 0
	pause_plate.texture_margin_bottom = 0
	pause_plate.content_margin_left = 24
	pause_plate.content_margin_right = 22
	pause_button.add_theme_stylebox_override("normal", pause_plate)
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -200
	pause_button.offset_right = -24
	pause_button.offset_top = 24
	pause_button.offset_bottom = 80
	pause_button.pressed.connect(func() -> void: set_paused(true))
	pause_panel = Control.new()
	root.add_child(pause_panel)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.129, 0.102, 0.169, 0.97)
	pause_panel.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	pause_panel.add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.offset_left = -220
	stack.offset_right = 220
	stack.offset_top = -140
	stack.offset_bottom = 140
	stack.add_theme_constant_override("separation",24)
	var title := Label.new()
	title.text = "EN PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", Visual.DISPLAY)
	title.add_theme_font_size_override("font_size",48)
	stack.add_child(title)
	resume_button = button("CONTINUAR",stack)
	resume_button.pressed.connect(func() -> void: set_paused(false))
	var exit_button := button("SALIR AL INICIO",stack)
	exit_button.pressed.connect(func() -> void:
		get_tree().paused = false
		exit_requested.emit()
	)
	pause_panel.hide()

func button(text: String, parent: Node) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size = Vector2(0,56)
	Visual.style_button(control, text == "CONTINUAR")
	parent.add_child(control)
	return control

func show_result(text: String, color: Color, winner := false) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color",color)
	result_label.add_theme_font_size_override("font_size",44 if winner else 68)
	# Keep the victory message above the celebrating players.
	result_label.anchor_top = 0.0 if winner else 0.5
	result_label.anchor_bottom = result_label.anchor_top
	result_label.offset_top = 175 if winner else -65
	result_label.offset_bottom = 305 if winner else 65
	result_label.show()

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_panel.visible = value
	pause_button.visible = not value
	pause_changed.emit(value)
	if value: resume_button.grab_focus()
	else: get_viewport().gui_release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
