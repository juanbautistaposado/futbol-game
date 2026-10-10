extends RefCounted

const BODY = preload("res://ui/fonts/Archivo-Body.tres")
const EMPHASIS = preload("res://ui/fonts/Archivo-Emphasis.tres")
const DISPLAY = preload("res://ui/fonts/Bungee-Regular.ttf")
const ARROW = preload("res://ui/icons/arrow.svg")
const CHECK = preload("res://ui/icons/check.svg")
const PAUSE = preload("res://ui/icons/pause.svg")
const ACTION_PLATE = preload("res://ui/plates/action.svg")
const HOVER_PLATE = preload("res://ui/plates/hover.svg")
const PRESSED_PLATE = preload("res://ui/plates/pressed.svg")
const INK := Color("fff2d0")
const MUTED := Color("cbbfd3")
const ACCENT := Color("f05b3f")
const BASE := Color("211a2b")
const SURFACE := Color("30253c")
const LINE := Color("695674")
const BLUE := Color("3456e8")
const ENERGY := Color("f5d547")
const SUCCESS := Color("62c58d")

static func box(fill: Color = SURFACE, border: Color = LINE, radius: int = 0) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.content_margin_left = 18
	result.content_margin_right = 18
	result.content_margin_top = 10
	result.content_margin_bottom = 10
	return result

static func style_button(item: Button, primary: bool = false) -> void:
	item.add_theme_font_override("font", EMPHASIS)
	item.add_theme_font_size_override("font_size", 22 if primary else 20)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := ACCENT if primary else SURFACE
		var edge := BASE if primary else LINE
		var ink := BASE if primary else INK
		if state == "hover":
			fill = ENERGY if primary else BLUE
			edge = INK
		elif state == "pressed":
			fill = Color("ea543c") if primary else Color("263fad")
		elif state == "disabled":
			fill = Color("292230")
			edge = Color("46394f")
			ink = Color("a294ae")
		var plate: StyleBox
		if primary and state != "disabled":
			var cut := StyleBoxTexture.new()
			cut.texture = HOVER_PLATE if state == "hover" else PRESSED_PLATE if state == "pressed" else ACTION_PLATE
			cut.texture_margin_left = 20
			cut.texture_margin_right = 32
			cut.texture_margin_top = 6
			cut.texture_margin_bottom = 10
			cut.content_margin_left = 24
			cut.content_margin_right = 30
			cut.content_margin_top = 10
			cut.content_margin_bottom = 14
			plate = cut
		else:
			var flat := box(fill, edge)
			flat.border_width_bottom = 3
			plate = flat
		item.add_theme_stylebox_override(state, plate)
		item.add_theme_color_override("font_color" if state == "normal" else "font_" + state + "_color", ink)
		item.add_theme_color_override("icon_" + state + "_color", ink)
	item.add_theme_color_override("font_focus_color", BASE if primary else INK)
	item.add_theme_color_override("icon_focus_color", BASE if primary else INK)
	item.add_theme_constant_override("h_separation", 14)
	var focus := box(Color.TRANSPARENT, ENERGY)
	focus.set_border_width_all(2)
	focus.set_expand_margin_all(4)
	if primary:
		var cut_focus := StyleBoxTexture.new()
		cut_focus.texture = preload("res://ui/plates/focus.svg")
		cut_focus.texture_margin_left = 20
		cut_focus.texture_margin_right = 32
		cut_focus.texture_margin_top = 6
		cut_focus.texture_margin_bottom = 10
		item.add_theme_stylebox_override("focus", cut_focus)
	else:
		item.add_theme_stylebox_override("focus", focus)

static func style_link(item: Button) -> void:
	style_button(item)
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal", "hover", "pressed"]:
		var plate := box(Color.TRANSPARENT, ENERGY if state != "normal" else Color.TRANSPARENT)
		plate.set_border_width_all(0)
		plate.border_width_bottom = 2 if state != "normal" else 0
		plate.content_margin_left = 0
		item.add_theme_stylebox_override(state, plate)

static func create() -> Theme:
	var result := Theme.new()
	result.default_font = BODY
	result.default_font_size = 20
	result.set_color("font_color", "Label", INK)
	var template := Button.new()
	style_button(template)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var color_key: String = "font_color" if state == "normal" else "font_" + state + "_color"
		result.set_stylebox(state, "Button", template.get_theme_stylebox(state))
		result.set_color(color_key, "Button", template.get_theme_color(color_key))
	result.set_font("font", "Button", EMPHASIS)
	result.set_font_size("font_size", "Button", 20)
	template.free()
	result.set_stylebox("panel", "PopupMenu", box())
	result.set_stylebox("hover", "PopupMenu", box(BLUE, INK))
	result.set_color("font_color", "PopupMenu", INK)
	result.set_color("font_hover_color", "PopupMenu", INK)
	result.set_stylebox("panel", "Panel", box())
	result.set_stylebox("panel", "PanelContainer", box())
	for kind in ["LineEdit", "OptionButton", "SpinBox"]:
		result.set_stylebox("normal", kind, box())
		result.set_stylebox("focus", kind, box(SURFACE, ENERGY))
		result.set_color("font_color", kind, INK)
		result.set_color("font_placeholder_color", kind, MUTED)
		result.set_color("caret_color", kind, ENERGY)
		result.set_color("font_selected_color", kind, BASE)
		result.set_color("selection_color", kind, ENERGY)
	var rail := box(LINE, LINE)
	rail.content_margin_top = 3
	rail.content_margin_bottom = 3
	result.set_stylebox("slider", "HSlider", rail)
	var track := box(ACCENT, ACCENT)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	result.set_stylebox("grabber_area", "HSlider", track)
	result.set_stylebox("grabber_area_highlight", "HSlider", track)
	return result
