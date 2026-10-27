class_name ItemButton
extends TipButton
## An item in a gear slot, the bank or a loot list: quality-coloured name with a Classic tooltip.

var item := {}
var slot := ""


func setup(it: Dictionary, slot_name := "", compare := "", compact := false) -> ItemButton:
	item = it
	slot = slot_name
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_theme_font_size_override("font_size", 13 if compact else 14)
	if it.is_empty():
		text = "%s: —" % Items.SLOT_NAMES.get(slot_name, slot_name) if slot_name != "" else "—"
		add_theme_color_override("font_color", Style.C["dim"])
		set_tip("")
		var s := Style.box(Color(0.05, 0.03, 0.03, 0.7), Color(0.25, 0.15, 0.1), 1, 4, 5)
		add_theme_stylebox_override("normal", s)
	else:
		var col := Items.color(it)
		text = it["name"] if slot_name == "" or compact else "%s" % it["name"]
		add_theme_color_override("font_color", col)
		add_theme_color_override("font_hover_color", col.lightened(0.3))
		var s := Style.box(Color(0.06, 0.04, 0.05, 0.9), col.darkened(0.35), 1, 4, 5)
		add_theme_stylebox_override("normal", s)
		var h := s.duplicate()
		h.border_color = col
		h.bg_color = Color(0.12, 0.08, 0.08, 0.95)
		add_theme_stylebox_override("hover", h)
		set_tip(Items.tooltip_bb(it, compare))
	return self
