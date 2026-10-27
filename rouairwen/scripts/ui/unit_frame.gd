class_name UnitFrame
extends Control
## A raid-style party frame: health, shields, incoming heal, buffs and debuffs. Click to target.

signal clicked(frame)
signal hover_changed(frame, inside: bool)

const BUFF_COLORS := {
	"renew": Color("6ee06e"), "pws": Color("e8f0ff"), "pom": Color("ffd86b"), "grace": Color("fff0a0"), "inspiration": Color("a0d0ff"),
	"aegis": Color("ffcf5a"), "power_infusion": Color("ff9a3c"), "pain_suppression": Color("b088ff"), "lightwell_renew": Color("fffbe0"),
	"shield_wall": Color("b0b0b0"), "evasion": Color("fff569"), "barkskin": Color("a07040"),
	"weakened_soul": Color("7a5a5a"),
}
const BUFF_LETTERS := {"renew": "R", "pws": "S", "pom": "M", "grace": "G", "inspiration": "I", "aegis": "A", "power_infusion": "P",
	"pain_suppression": "Ps", "lightwell_renew": "L", "shield_wall": "W", "evasion": "E", "barkskin": "B"}

var unit
var engine: CombatEngine
var selected := false
var hovered := false
var _flash := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(196, 66)
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
	var r := Rect2(Vector2.ZERO, size)
	var font := Style.bold_font()
	var cls_col := ClassData.color(unit.class_id)
	draw_rect(r, Color(0.04, 0.03, 0.03, 0.92))
	var bar := Rect2(3, 3, size.x - 6, size.y - 24)
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
	# Auras
	var bx := 4.0
	var dx := size.x - 4.0
	for au in unit.auras:
		if au.get("hidden", false):
			continue
		var harmful: bool = au.get("harmful", false)
		var col: Color
		if harmful:
			col = CombatEngine.DISPEL_COLORS.get(au.get("dispel", ""), Color("b02020"))
			if au.has("bomb"):
				col = Color("ff8000")
			dx -= 17
			var ar := Rect2(dx, size.y - 19, 15, 15)
			draw_rect(ar, col)
			draw_rect(ar, Color.BLACK, false, 1.0)
			if au.get("dispel", "") in ["magic", "disease"]:
				var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
				draw_rect(ar.grow(1), Color(1, 1, 1, pulse), false, 1.0)
		else:
			col = BUFF_COLORS.get(au["id"], Color("c0c0c0"))
			var ar := Rect2(bx, size.y - 19, 15, 15)
			var tex := WowIcons.texture(WowIcons.aura(au["id"]))
			var letter: String = BUFF_LETTERS.get(au["id"], "")
			if tex != null:
				draw_texture_rect_region(tex, ar, Rect2(Vector2.ONE * tex.get_width() * 0.08, Vector2.ONE * tex.get_width() * 0.84))
				draw_rect(ar, Color.BLACK, false, 1.0)
				letter = ""
			else:
				draw_rect(ar, col.darkened(0.3))
				draw_rect(ar, col, false, 1.0)
			if au.has("charges"):
				letter = str(au["charges"])
			elif au.has("stacks"):
				letter = str(au["stacks"])
			draw_string_outline(font, Vector2(bx + 1, size.y - 7), letter, HORIZONTAL_ALIGNMENT_CENTER, 13, 10, 3, Color.BLACK)
			draw_string(font, Vector2(bx + 1, size.y - 7), letter, HORIZONTAL_ALIGNMENT_CENTER, 13, 10, Color.WHITE)
			bx += 17
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
	var start := Vector2(size.x * 0.5, -6.0 if above else size.y * 0.45)
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
