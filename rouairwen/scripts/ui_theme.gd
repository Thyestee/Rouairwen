class_name UiTheme
## Builds the interface Theme from HordeStyle's palette, fonts and border style.
##
## Scenes refer to these label variations through theme_type_variation:
## TitleLabel, BarTitle, SectionTitle, RowTitle, RowCount, ResourceLabel, MutedLabel, CostLabel, Toast.
## And to these panel variations: Bar (top bar), Frame (border around the settlement), RosterRow,
## Solid (opaque, for windows over the page).


static func build() -> Theme:
	var p := HordeStyle.PALETTE
	var style := HordeStyle.BORDER
	var body := _font(HordeStyle.BODY_FONTS, HordeStyle.BODY_WEIGHT)
	var heading := _font(HordeStyle.HEADING_FONTS, HordeStyle.HEADING_WEIGHT)

	var theme := Theme.new()
	theme.default_font = body
	theme.default_font_size = 17

	theme.set_color("font_color", "Label", p.text)
	_label_variation(theme, "TitleLabel", heading, 40, p.accent)
	theme.set_color("font_outline_color", "TitleLabel", p.outline)
	theme.set_constant("outline_size", "TitleLabel", 8)
	_label_variation(theme, "BarTitle", heading, 26, p.accent)
	_label_variation(theme, "SectionTitle", heading, 16, p.accent)
	_label_variation(theme, "RowTitle", heading, 19, p.text)
	_label_variation(theme, "RowCount", heading, 24, p.accent)
	_label_variation(theme, "ResourceLabel", heading, 22, p.text)
	_label_variation(theme, "MutedLabel", body, 14, p.muted)
	_label_variation(theme, "CostLabel", body, 14, p.text)

	theme.set_stylebox("panel", "PanelContainer", _box(p.panel, p.border, style, 14))
	theme.set_type_variation("Bar", "PanelContainer")
	theme.set_stylebox("panel", "Bar", _box(p.panel, p.border, style, 10))
	theme.set_type_variation("Frame", "PanelContainer")
	var frame := _box(Color.TRANSPARENT, p.border, style, 0)
	frame.set_corner_radius_all(0)
	frame.set_content_margin_all(style.border_width)
	theme.set_stylebox("panel", "Frame", frame)
	theme.set_type_variation("Solid", "PanelContainer")
	theme.set_stylebox("panel", "Solid", _box(p.panel_solid, p.border, style, 16))
	theme.set_type_variation("RosterRow", "PanelContainer")
	var roster_row := _box(p.button, Color(p.border, 0.7), style, 8)
	roster_row.set_border_width_all(2)
	theme.set_stylebox("panel", "RosterRow", roster_row)

	var button_states := {
		"normal": _box(p.button, p.border, style, 10, true),
		"hover": _box(p.button_hover, p.accent, style, 10, true),
		"pressed": _box(p.primary, p.accent, style, 10, true),
		"disabled": _box(Color(p.button, p.button.a * 0.5), Color(p.border, 0.35), style, 10, true),
	}
	for state in button_states:
		theme.set_stylebox(state, "Button", button_states[state])
	theme.set_stylebox("hover_pressed", "Button", button_states.pressed)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_font("font", "Button", heading)
	theme.set_color("font_color", "Button", p.text)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", p.muted)

	theme.set_type_variation("Toast", "Label")
	theme.set_stylebox("normal", "Toast", _box(p.panel_solid, p.accent, style, 14))
	theme.set_color("font_color", "Toast", p.text)

	theme.set_stylebox("panel", "TooltipPanel", _box(p.panel_solid, p.border, style, 8))
	theme.set_color("font_color", "TooltipLabel", p.text)
	theme.set_stylebox("panel", "AcceptDialog", _box(p.panel_solid, p.border, style, 14))
	return theme


static func _font(names: Array, weight: int) -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(names)
	font.font_weight = weight
	return font


static func _label_variation(theme: Theme, type: String, font: Font, font_size: int, color: Color) -> void:
	theme.set_type_variation(type, "Label")
	theme.set_font("font", type, font)
	theme.set_font_size("font_size", type, font_size)
	theme.set_color("font_color", type, color)


static func _box(bg: Color, border: Color, style: Dictionary, margin: float, is_button := false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(style.border_width)
	box.set_corner_radius_all(style.corner_radius)
	box.corner_detail = style.corner_detail
	box.set_content_margin_all(margin)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 4
	if is_button:
		box.skew = Vector2(style.button_skew, 0.0)
	return box
