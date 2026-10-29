class_name UnitFrame
extends Control
## A raid-style party frame: health, shields, incoming heal, buffs and debuffs, with a cast bar on
## top (CastBar). Click to target.

signal clicked(frame)
signal hover_changed(frame, inside: bool)

const BUFF_COLORS := {
	"renew": Color("6ee06e"), "pws": Color("e8f0ff"), "pom": Color("ffd86b"), "grace": Color("fff0a0"), "inspiration": Color("a0d0ff"),
	"aegis": Color("ffcf5a"), "power_infusion": Color("ff9a3c"), "pain_suppression": Color("b088ff"),
	"shield_wall": Color("b0b0b0"), "evasion": Color("fff569"), "barkskin": Color("a07040"),
	"weakened_soul": Color("7a5a5a"), "ward": Color("ffe9a8"), "overflow": Color("fff6c0"), "clearcasting": Color("8ac4ff"),
	"fervor": Color("ff9a3c"), "echo": Color("b8ff9a"),
}
const BUFF_LETTERS := {"renew": "R", "pws": "S", "pom": "M", "grace": "G", "inspiration": "I", "aegis": "A", "power_infusion": "P",
	"pain_suppression": "Ps", "shield_wall": "W", "evasion": "E", "barkskin": "B", "ward": "L", "overflow": "O", "clearcasting": "C",
	"fervor": "F", "echo": "Ec"}

const AURA := 18.0
## The cast bar strip above the frame itself.
const TOP := CastBar.H + 3.0

var unit
var engine: CombatEngine
var selected := false
var hovered := false
var _flash := 0.0
var _aura_rects: Array = []
## The frame below the cast bar strip; it is drawn from (0, TOP).
var _body := Vector2(196, 66)


func _init() -> void:
	custom_minimum_size = Vector2(196, 66 + TOP)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func _set_hover(inside: bool) -> void:
	hovered = inside
	hover_changed.emit(self, inside)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()


func flash() -> void:
	_flash = 0.25


func _draw() -> void:
	if unit == null:
		return
	CastBar.draw(self, Rect2(2, 0, size.x - 4, CastBar.H), unit, engine)
	_body = Vector2(size.x, size.y - TOP)
	draw_set_transform(Vector2(0, TOP))
	var r := Rect2(Vector2.ZERO, _body)
	var font := Style.bold_font()
	var cls_col := ClassData.color(unit.class_id)
	draw_rect(r, Color(0.04, 0.03, 0.03, 0.92))
	var bar := Rect2(3, 3, _body.x - 6, _body.y - 24)
	draw_rect(bar, Color(0.12, 0.08, 0.08))
	if unit.alive:
		var f: float = unit.frac()
		var col := cls_col.darkened(0.15)
		if unit.spirit > 0.0:
			col = Color("fff4cf")
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * f, bar.size.y)), col)
		# Incoming heal from the priest's current cast
		var inc := _incoming()
		if inc > 0.0:
			var w: float = minf(bar.size.x * (1.0 - f), bar.size.x * inc / unit.max_hp)
			draw_rect(Rect2(bar.position.x + bar.size.x * f, bar.position.y, w, bar.size.y), Color(0.5, 1.0, 0.5, 0.45))
		# Absorb shields
		var ab: float = unit.absorb()
		if ab > 0.0:
			var aw: float = minf(bar.size.x, bar.size.x * ab / unit.max_hp)
			draw_rect(Rect2(bar.position.x, bar.end.y - 6, aw, 6), Color(0.9, 0.95, 1.0, 0.85))
		# Low health warning
		if f < 0.3:
			var a := 0.25 + 0.2 * sin(Time.get_ticks_msec() / 120.0)
			draw_rect(bar, Color(1, 0, 0, a), false, 3.0)
	# Name & health text
	var name_col := cls_col if unit.alive else Color(0.5, 0.5, 0.5)
	if unit.class_id == "shaman" and unit.alive:
		name_col = Color("ffffff")
	draw_string_outline(font, Vector2(8, 22), unit.name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 15, 4, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(8, 22), unit.name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 15, Color.WHITE if unit.alive else Color(0.6, 0.6, 0.6))
	var status := ""
	if not unit.alive:
		status = "Dead"
	elif unit.spirit > 0.0:
		status = "Spirit"
	elif unit.cc():
		status = "Feared" if unit.has("fear") else "Hexed"
	else:
		status = "%d" % int(unit.hp)
	draw_string_outline(font, Vector2(size.x - 64, 40), status, HORIZONTAL_ALIGNMENT_RIGHT, 56, 13, 4, Color(0, 0, 0, 0.9))
	draw_string(font, Vector2(size.x - 64, 40), status, HORIZONTAL_ALIGNMENT_RIGHT, 56, 13, Color(1, 0.6, 0.6) if status in ["Dead", "Feared", "Hexed"] else Color(1, 1, 1, 0.85))
	# Role glyph
	_role_glyph(Vector2(size.x - 14, 14), unit.role, name_col)
	_draw_auras(font)
	# Borders
	var border := Color(0, 0, 0)
	var width := 1.0
	if selected:
		border = Color("ffd86b")
		width = 2.5
	elif hovered:
		border = Color(1, 1, 1, 0.8)
		width = 2.0
	draw_rect(r, border, false, width)
	if _flash > 0.0:
		draw_rect(r, Color(1, 1, 0.7, _flash * 2.0), false, 3.0)
	if not unit.alive:
		draw_rect(r, Color(0, 0, 0, 0.45))


## Buffs on the left, debuffs on the right. Harmful debuffs glow in their type's colour
## (magic, curse, disease, poison, physical), and every aura shows its time left.
func _draw_auras(font: Font) -> void:
	_aura_rects.clear()
	var bx := 3.0
	var dx := size.x - 3.0
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
	for au in unit.auras:
		if au.get("hidden", false):
			continue
		var is_debuff: bool = au.get("harmful", false) or au.get("debuff", false)
		var ar: Rect2
		if is_debuff:
			dx -= AURA + 2
			ar = Rect2(dx, _body.y - AURA - 2, AURA, AURA)
		else:
			ar = Rect2(bx, _body.y - AURA - 2, AURA, AURA)
			bx += AURA + 2
		_aura_rects.append([ar, au])
		var col := aura_color(au)
		var tex := WowIcons.texture(WowIcons.for_aura(au))
		var count := ""
		if tex != null:
			draw_texture_rect_region(tex, ar, Rect2(Vector2.ONE * tex.get_width() * 0.08, Vector2.ONE * tex.get_width() * 0.84))
		else:
			draw_rect(ar, col.darkened(0.35))
			count = BUFF_LETTERS.get(au["id"], String(au.get("name", "?")).substr(0, 1))
		if au.get("harmful", false):
			draw_rect(ar.grow(2.5), Color(col, 0.2 + 0.35 * pulse), false, 2.0)
			draw_rect(ar, Color(col.lightened(0.25), 0.75 + 0.25 * pulse), false, 1.5)
		else:
			draw_rect(ar, Color(0.55, 0.55, 0.55) if is_debuff else Color.BLACK, false, 1.0)
		if au.has("charges"):
			count = str(au["charges"])
		elif au.has("stacks"):
			count = str(au["stacks"])
		if count != "":
			draw_string_outline(font, Vector2(ar.position.x + 1, ar.position.y + 9), count, HORIZONTAL_ALIGNMENT_LEFT, AURA, 9, 3, Color.BLACK)
			draw_string(font, Vector2(ar.position.x + 1, ar.position.y + 9), count, HORIZONTAL_ALIGNMENT_LEFT, AURA, 9, Color.WHITE)
		var left: float = au.get("remaining", 0.0)
		if left > 0.0 and left < 100.0:
			var t := str(int(ceil(left)))
			var tc := Color(1, 0.45, 0.4) if left < 3.0 else Color.WHITE
			draw_string_outline(font, Vector2(ar.position.x, ar.end.y - 1), t, HORIZONTAL_ALIGNMENT_RIGHT, AURA, 10, 3, Color.BLACK)
			draw_string(font, Vector2(ar.position.x, ar.end.y - 1), t, HORIZONTAL_ALIGNMENT_RIGHT, AURA, 10, tc)


static func aura_color(au: Dictionary) -> Color:
	if au.get("harmful", false):
		if au.has("bomb"):
			return Color("ff8000")
		return CombatEngine.DISPEL_COLORS.get(au.get("dispel", ""), Color("b02020"))
	if au.get("debuff", false):
		return Color("9a8a8a")
	return BUFF_COLORS.get(au["id"], Color("c0c0c0"))


func _get_tooltip(at_position: Vector2) -> String:
	for pair in _aura_rects:
		if pair[0].grow(1.0).has_point(at_position - Vector2(0, TOP)):
			return UnitFrame.aura_tooltip(pair[1])
	return ""


func _make_custom_tooltip(for_text: String) -> Object:
	return TipButton.make_tip(for_text, 260)


const TYPE_NAMES := {"magic": "Magic", "curse": "Curse", "disease": "Disease", "poison": "Poison", "": "Physical"}
const REMOVED_BY := {
	"magic": "[color=#6ee06e]Your Dispel Magic removes it.[/color]",
	"disease": "[color=#6ee06e]Your Dispel Magic removes it.[/color]",
	"poison": "A shaman's Poison Cleansing Totem removes it.",
	"curse": "A mage's or druid's Remove Curse removes it.",
	"": "It cannot be dispelled.",
}


## The hover description of a buff or debuff, built from its live numbers.
static func aura_tooltip(au: Dictionary) -> String:
	var col := aura_color(au).to_html(false)
	var s := "[b][color=#%s]%s[/color][/b]" % [col, au.get("name", "")]
	# Guildmates' debuffs on enemies: who put it there, no dispel type.
	if au.get("kind", "") == "guild":
		var src = au.get("source")
		s = "[b][color=#8fd3ff]%s[/color][/b]" % au.get("name", "")
		if src != null:
			s += "  [color=#c0c0c0]from %s[/color]" % src.name
		if au.has("desc"):
			s += "\n" + au["desc"]
		if au.has("pdot"):
			s += "\nTakes %d damage every %d sec." % [int(au["pdot"]), int(au.get("period", 3.0))]
		return s + "\n[color=#c0c0c0]%d sec remaining[/color]" % int(ceil(au.get("remaining", 0.0)))
	var harmful: bool = au.get("harmful", false)
	if harmful:
		s += "    [color=#%s]%s[/color]" % [col, TYPE_NAMES.get(au.get("dispel", ""), "Physical")]
	var d := ""
	if au.has("desc"):
		d = au["desc"]
	elif au.has("dot"):
		d = "Takes %d damage every %d sec." % [int(au["dot"]), int(au.get("period", 3.0))]
	elif au.has("bomb"):
		d = "Explodes when it ends, hitting the whole party for about %d." % int(au["bomb"])
	elif au["id"] == "pom":
		d = "Heals %d the next time they take damage, then jumps to another party member. %d jumps left." % [int(au["heal"]), au["charges"]]
	elif au.has("heal") and au.has("period"):
		d = "Heals %d every %d sec." % [int(au["heal"]), int(au["period"])]
	elif au.has("absorb"):
		d = "Absorbs %d more damage." % int(au["absorb"])
	elif au.has("per_stack"):
		d = "Your healing on them is increased by %d%%." % int(au["stacks"] * au["per_stack"])
	elif au.has("dps_mult"):
		d = "Deals %d%% more damage." % int(round((au["dps_mult"] - 1.0) * 100.0))
	elif au.has("heal_taken"):
		d = "Healing received is reduced by %d%%." % int(round((1.0 - au["heal_taken"]) * 100.0))
	elif au.has("dmg_taken"):
		d = "Takes %d%% less damage." % int(round((1.0 - au["dmg_taken"]) * 100.0))
	elif au.get("kind", "") == "fear":
		d = "Feared: can't attack until it ends."
	elif au.get("cc", false):
		d = "Can't attack until it ends or is dispelled."
	if d != "":
		s += "\n" + d
	if au.get("remaining", 0.0) > 0.0:
		s += "\n[color=#c0c0c0]%d sec remaining[/color]" % int(ceil(au["remaining"]))
	if harmful:
		s += "\n" + REMOVED_BY.get(au.get("dispel", ""), REMOVED_BY[""])
	return s


func _incoming() -> float:
	if engine == null or engine.casting.is_empty():
		return 0.0
	var id: String = engine.casting["id"]
	if id in ["heal", "flash_heal"] and engine.casting["target"] == unit:
		return engine._base_heal(id)
	if id == "penance" and engine.casting["target"] == unit:
		return engine._base_heal(id)
	if id == "prayer_of_healing":
		return engine._base_heal(id)
	return 0.0


func _role_glyph(c: Vector2, role: String, col: Color) -> void:
	match role:
		"tank":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -6), c + Vector2(6, -6), c + Vector2(5, 2), c + Vector2(0, 7), c + Vector2(-5, 2)]), Color("8ab0ff"))
		"healer", "priest":
			draw_rect(Rect2(c.x - 2, c.y - 6, 4, 12), Color("6ee06e"))
			draw_rect(Rect2(c.x - 6, c.y - 2, 12, 4), Color("6ee06e"))
		"melee":
			draw_line(c + Vector2(-6, 6), c + Vector2(6, -6), Color("ff8a6a"), 2.5)
			draw_line(c + Vector2(-6, 0), c + Vector2(0, 6), Color("ff8a6a"), 2.0)
		"ranged":
			draw_arc(c, 6, -PI * 0.5, PI * 0.5, 8, Color("ffd86b"), 2.0)
			draw_line(c + Vector2(0, -6), c + Vector2(0, 6), Color("ffd86b"), 1.0)


## Floating combat text: your heals rise above the frame, other events float inside it.
func pop(text: String, kind: String) -> void:
	var above := kind in ["heal", "crit_heal", "hot"]
	var start := Vector2(size.x * 0.5, -6.0 if above else TOP + _body.y * 0.45)
	UnitFrame.float_text(self, text, kind, start)


const FLOAT_COLORS := {"heal": Color("6ee06e"), "crit_heal": Color("b8ff6a"), "hot": Color("a0e8a0"), "heal_other": Color("8ad0a0"),
	"damage": Color("ff5a4a"), "absorb": Color("e8f0ff"), "mana": Color("6aa8ff"), "mana_burn": Color("a070ff"), "info": Color("ffd86b"),
	"spell_damage": Color("fff2b0"), "spell_crit": Color("ffd24a")}


## Spawns a rising, fading number centered on `start` (local to `parent`), drawn above neighbouring frames.
static func float_text(parent: Control, text: String, kind: String, start: Vector2) -> void:
	var big := kind in ["crit_heal", "spell_crit"]
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Style.bold_font())
	l.add_theme_font_size_override("font_size", 24 if big else (14 if kind in ["hot", "heal_other"] else 18))
	l.add_theme_color_override("font_color", FLOAT_COLORS.get(kind, Color.WHITE))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 20
	parent.add_child(l)
	var sz := l.get_minimum_size()
	l.position = start - Vector2(sz.x / 2.0, sz.y) + Vector2(randf_range(-28, 28), randf_range(-6, 6))
	if big:
		l.scale = Vector2(1.4, 1.4)
		l.pivot_offset = sz / 2.0
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 38, 1.2)
	if big:
		tw.tween_property(l, "scale", Vector2.ONE, 0.25)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)
