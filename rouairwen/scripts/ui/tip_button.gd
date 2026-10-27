class_name TipButton
extends Button
## A button with a rich (BBCode) tooltip, used for items, spells and talents.

var tip := ""


func _init() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE


func set_tip(bb: String) -> void:
	tip = bb
	tooltip_text = " " if bb != "" else ""


func _make_custom_tooltip(_for_text: String) -> Object:
	return TipButton.make_tip(tip)


static func make_tip(bb: String, width := 300) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Style.box(Color(0.04, 0.03, 0.07, 0.97), Color("8a8aa8"), 1, 4, 10))
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(width, 0)
	r.add_theme_font_size_override("normal_font_size", 14)
	r.add_theme_font_size_override("bold_font_size", 15)
	r.add_theme_font_override("normal_font", Style.body_font())
	r.add_theme_font_override("bold_font", Style.bold_font())
	r.text = bb
	p.add_child(r)
	return p
