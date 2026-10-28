class_name Style
## The game's look: Horde reds and leather, with the Lumens' violet and gold.
## Also small factories for the controls every screen builds.

const C := {
	"text": Color("f4e8d8"),
	"muted": Color("c09f86"),
	"dim": Color("8a7262"),
	"gold": Color("ffd86b"),
	"accent": Color("ff9a3c"),
	"good": Color("6ee06e"),
	"bad": Color("ff5a4a"),
	"mana": Color("3a7bff"),
	"panel": Color(0.11, 0.045, 0.03, 0.94),
	"panel_light": Color(0.18, 0.08, 0.05, 0.95),
	"inset": Color(0.06, 0.025, 0.02, 0.9),
	"border": Color("8e2a1a"),
	"border_gold": Color("b8892f"),
	"button": Color("3d1a10"),
	"button_hover": Color("5e2616"),
	"button_press": Color("2a0f08"),
	"primary": Color("a3241a"),
	"primary_hover": Color("c4321f"),
	"guild": Color("3b2675"),
	"guild_light": Color("ffd86b"),
	"prestige": Color("d8a8ff"),
}

const HEADING_FONTS := ["Georgia", "Palatino Linotype", "Book Antiqua", "Times New Roman", "serif"]
const BODY_FONTS := ["Segoe UI", "Trebuchet MS", "Verdana", "sans-serif"]

static var _theme: Theme
static var _heading: SystemFont
static var _body: SystemFont
static var _bold: SystemFont


static func heading_font() -> Font:
	if _heading == null:
		_heading = SystemFont.new()
		_heading.font_names = PackedStringArray(HEADING_FONTS)
		_heading.font_weight = 700
	return _heading


static func body_font() -> Font:
	if _body == null:
		_body = SystemFont.new()
		_body.font_names = PackedStringArray(BODY_FONTS)
		_body.font_weight = 500
	return _body


static func bold_font() -> Font:
	if _bold == null:
		_bold = SystemFont.new()
		_bold.font_names = PackedStringArray(BODY_FONTS)
		_bold.font_weight = 700
	return _bold


static func box(bg: Color, border: Color = Color.TRANSPARENT, width := 0, radius := 6, pad := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.corner_detail = 3
	s.set_content_margin_all(pad)
	return s


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 15
	t.set_color("font_color", "Label", C["text"])
	t.set_color("default_color", "RichTextLabel", C["text"])
	t.set_font("bold_font", "RichTextLabel", bold_font())
	t.set_font("normal_font", "RichTextLabel", body_font())

	t.set_stylebox("panel", "PanelContainer", box(C["panel"], C["border"], 2, 8, 10))
	t.set_stylebox("panel", "Panel", box(C["panel"], C["border"], 2, 8, 10))

	var bn := box(C["button"], C["border"], 2, 5, 6)
	bn.content_margin_left = 12
	bn.content_margin_right = 12
	var bh := bn.duplicate()
	bh.bg_color = C["button_hover"]
	bh.border_color = C["accent"]
	var bp := bn.duplicate()
	bp.bg_color = C["button_press"]
	var bd := bn.duplicate()
	bd.bg_color = Color(0.15, 0.1, 0.08, 0.8)
	bd.border_color = Color(0.3, 0.2, 0.15)
	var bf := bh.duplicate()
	bf.draw_center = false
	t.set_stylebox("normal", "Button", bn)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("disabled", "Button", bd)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C["text"])
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", C["gold"])
	t.set_color("font_disabled_color", "Button", C["dim"])
	t.set_font("font", "Button", bold_font())

	t.set_stylebox("panel", "TooltipPanel", box(Color(0.04, 0.03, 0.07, 0.97), Color("6a6a8a"), 1, 4, 8))
	t.set_color("font_color", "TooltipLabel", C["text"])

	t.set_stylebox("normal", "LineEdit", box(C["inset"], C["border"], 2, 4, 8))
	t.set_stylebox("focus", "LineEdit", box(C["inset"], C["accent"], 2, 4, 8))
	t.set_color("font_color", "LineEdit", C["text"])

	t.set_stylebox("background", "ProgressBar", box(Color(0.05, 0.03, 0.03, 0.9), Color(0, 0, 0, 0.8), 1, 3, 0))
	t.set_stylebox("fill", "ProgressBar", box(C["good"], Color.TRANSPARENT, 0, 3, 0))

	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.3), Color.TRANSPARENT, 0, 4, 0))
	t.set_stylebox("grabber", "VScrollBar", box(C["border"], Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(C["accent"], Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(C["gold"], Color.TRANSPARENT, 0, 4, 4))

	t.set_stylebox("panel", "PopupMenu", box(Color(0.08, 0.04, 0.03, 0.98), C["border_gold"], 1, 4, 6))
	t.set_stylebox("hover", "PopupMenu", box(C["button_hover"], Color.TRANSPARENT, 0, 3, 4))
	t.set_color("font_color", "PopupMenu", C["text"])
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("separator", "HSeparator", box(C["border"], Color.TRANSPARENT, 0, 0, 0))
	t.set_constant("separation", "HSeparator", 6)

	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	t.set_color("font_color", "CheckBox", C["text"])
	_theme = t
	return t


# ---------------------------------------------------------------- factories

static func label(text: String, size := 15, color: Color = C["text"], heading := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if heading:
		l.add_theme_font_override("font", heading_font())
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 4)
	return l


static func title(text: String, size := 24) -> Label:
	return label(text, size, C["gold"], true)


static func rich(text: String, size := 14) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = text
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


static func button(text: String, cb: Callable = Callable(), primary := false) -> Button:
	var b := Button.new()
	b.text = text
	if primary:
		b.add_theme_stylebox_override("normal", box(C["primary"], C["gold"], 2, 5, 8))
		b.add_theme_stylebox_override("hover", box(C["primary_hover"], Color.WHITE, 2, 5, 8))
	if cb.is_valid():
		b.pressed.connect(cb)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Mouse-driven UI: a focused button would also react to Space, fighting the pause key.
	b.focus_mode = Control.FOCUS_NONE
	return b


static func panel(bg: Color = C["panel"], border: Color = C["border"], width := 2, pad := 10) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, width, 8, pad))
	return p


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func bar(color: Color, height := 14) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size.y = height
	b.add_theme_stylebox_override("fill", box(color, Color.TRANSPARENT, 0, 3, 0))
	b.max_value = 1.0
	b.step = 0.0
	return b


static func scroll(content: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(content)
	return s


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


static func tier_badge(tier: int, size := 18) -> Label:
	var l := label(Tiers.name_of(tier), size, Tiers.color_of(tier), true)
	l.add_theme_constant_override("outline_size", 5)
	l.tooltip_text = "Grade %s: %.0f%% damage" % [Tiers.name_of(tier), Tiers.power(tier) * 100.0]
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	return l


static func class_color(class_id: String) -> Color:
	return ClassData.color(class_id)


static func role_label(role: String) -> String:
	return ClassData.ROLE_NAMES.get(role, role.capitalize())
