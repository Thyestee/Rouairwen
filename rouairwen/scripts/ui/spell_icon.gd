class_name SpellIcon
extends Control
## Procedurally drawn icons for spells, talents and consumables.

const PALETTE := {
	"heal": [Color("1d3f7a"), Color("ffe9a8")], "flash": [Color("6a4a10"), Color("fff6c0")], "renew": [Color("1f5a2a"), Color("b8ff9a")],
	"shield": [Color("1a2f5a"), Color("cfe6ff")], "penance": [Color("5a4410"), Color("ffd86b")], "pom": [Color("4a3a1a"), Color("ffe08a")],
	"coh": [Color("3a2a5a"), Color("fff0b0")], "poh": [Color("5a3a1a"), Color("ffe6a0")], "dispel": [Color("10305a"), Color("8ac4ff")],
	"infusion": [Color("5a2a10"), Color("ffb060")], "suppression": [Color("2a1a4a"), Color("d0b0ff")],
	"focus": [Color("2a2a4a"), Color("e0e0ff")], "lightwell": [Color("3a3a2a"), Color("fffbe0")],
	"mana_potion": [Color("101a3a"), Color("4a8aff")], "healing_potion": [Color("3a1010"), Color("ff4a4a")],
	"elixir_red": [Color("3a1a10"), Color("ff7a3a")], "elixir_green": [Color("103a1a"), Color("5aff7a")], "elixir_blue": [Color("10203a"), Color("7ac0ff")],
	"food": [Color("3a2a10"), Color("e0a060")],
}

var icon := "heal"
var dim := false
## The real WoW icon to show instead of the drawn glyph, when it has been downloaded.
var wow := ""
## Colours a drawn glyph (guildmate talents use their class colour).
var tint := Color(0, 0, 0, 0)


func _init(id := "heal", wow_name := "") -> void:
	icon = id
	wow = wow_name
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_icon(id: String, wow_name := "") -> void:
	icon = id
	wow = wow_name
	queue_redraw()


func _draw() -> void:
	var s := size
	var r := Rect2(Vector2.ZERO, s)
	var tex := WowIcons.texture(wow)
	if tex != null:
		# WoW icons carry a dark built-in border; trim it a little so the art fills the slot.
		var src := Rect2(Vector2.ONE * tex.get_width() * 0.06, Vector2.ONE * tex.get_width() * 0.88)
		draw_texture_rect_region(tex, r, src, Color(0.35, 0.35, 0.35) if dim else Color.WHITE)
		draw_rect(r, Color(0, 0, 0, 0.9), false, 2.0)
		return
	var pal: Array = PALETTE.get(icon, [Color("3a2a2a"), Color("ffe0a0")])
	var bg: Color = pal[0]
	var fg: Color = pal[1]
	if tint.a > 0.0:
		bg = tint.darkened(0.6)
		fg = tint.lightened(0.35)
	if dim:
		bg = bg.darkened(0.5)
		fg = fg.darkened(0.5)
	draw_rect(r, bg.darkened(0.3))
	# Soft radial glow
	var c := s / 2.0
	var m := minf(s.x, s.y)
	for i in 5:
		draw_circle(c, m * (0.48 - i * 0.07), bg.lerp(fg, 0.08 * i))
	var w := maxf(2.0, m * 0.09)
	match icon:
		"heal", "spiritual", "imp_heal", "empowered":
			draw_rect(Rect2(c.x - m * 0.1, c.y - m * 0.32, m * 0.2, m * 0.64), fg)
			draw_rect(Rect2(c.x - m * 0.32, c.y - m * 0.1, m * 0.64, m * 0.2), fg)
		"flash", "surge":
			var pts := PackedVector2Array([c + Vector2(m * 0.08, -m * 0.38), c + Vector2(-m * 0.18, m * 0.04), c + Vector2(m * 0.02, m * 0.04),
				c + Vector2(-m * 0.08, m * 0.38), c + Vector2(m * 0.2, -m * 0.06), c + Vector2(0, -m * 0.06)])
			draw_colored_polygon(pts, fg)
		"renew":
			draw_arc(c, m * 0.28, PI * 0.2, PI * 1.7, 18, fg, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(m * 0.3, -m * 0.1), c + Vector2(m * 0.12, -m * 0.12), c + Vector2(m * 0.26, m * 0.08)]), fg)
			draw_circle(c, m * 0.08, fg)
		"shield", "reflect", "aegis", "rapture":
			var pts := PackedVector2Array([c + Vector2(-m * 0.28, -m * 0.3), c + Vector2(m * 0.28, -m * 0.3), c + Vector2(m * 0.26, m * 0.02),
				c + Vector2(0, m * 0.36), c + Vector2(-m * 0.26, m * 0.02)])
			draw_colored_polygon(pts, fg.darkened(0.15))
			draw_polyline(pts + PackedVector2Array([pts[0]]), fg.lightened(0.4), w * 0.6)
			draw_line(c + Vector2(0, -m * 0.24), c + Vector2(0, m * 0.26), bg, w * 0.5)
		"penance", "twin", "grace":
			for i in 3:
				var a := -PI / 2 + (i - 1) * 0.55
				draw_line(c + Vector2.from_angle(a) * m * 0.42, c + Vector2(0, m * 0.18), fg, w)
			draw_circle(c + Vector2(0, m * 0.2), m * 0.1, fg.lightened(0.4))
		"pom", "prayers":
			draw_arc(c, m * 0.3, 0, TAU, 24, fg, w * 0.6)
			for i in 5:
				draw_circle(c + Vector2.from_angle(-PI / 2 + i * TAU / 5) * m * 0.3, m * 0.07, fg)
			draw_circle(c, m * 0.1, fg.lightened(0.3))
		"coh":
			for i in 5:
				draw_circle(c + Vector2.from_angle(-PI / 2 + i * TAU / 5) * m * 0.26, m * 0.09, fg)
			draw_rect(Rect2(c.x - m * 0.05, c.y - m * 0.14, m * 0.1, m * 0.28), fg)
			draw_rect(Rect2(c.x - m * 0.14, c.y - m * 0.05, m * 0.28, m * 0.1), fg)
		"poh":
			for i in 8:
				var a := i * TAU / 8
				draw_line(c + Vector2.from_angle(a) * m * 0.16, c + Vector2.from_angle(a) * m * 0.4, fg, w * 0.6)
			draw_circle(c, m * 0.15, fg)
		"dispel":
			draw_arc(c, m * 0.28, 0, TAU * 0.8, 20, fg, w)
			draw_line(c + Vector2(-m * 0.14, -m * 0.14), c + Vector2(m * 0.14, m * 0.14), fg, w)
			draw_line(c + Vector2(m * 0.14, -m * 0.14), c + Vector2(-m * 0.14, m * 0.14), fg, w)
		"fury", "holy_spec":
			draw_line(c + Vector2(0, -m * 0.4), c + Vector2(0, m * 0.25), fg, w * 1.4)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-m * 0.18, m * 0.12), c + Vector2(m * 0.18, m * 0.12), c + Vector2(0, m * 0.38)]), fg)
		"infusion", "strength":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -m * 0.38), c + Vector2(m * 0.24, -m * 0.02), c + Vector2(m * 0.08, -m * 0.02),
				c + Vector2(m * 0.08, m * 0.34), c + Vector2(-m * 0.08, m * 0.34), c + Vector2(-m * 0.08, -m * 0.02), c + Vector2(-m * 0.24, -m * 0.02)]), fg)
		"suppression", "inspiration":
			draw_arc(c, m * 0.3, 0, TAU, 24, fg, w * 0.7)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, m * 0.26), c + Vector2(m * 0.18, 0), c + Vector2(m * 0.07, 0),
				c + Vector2(m * 0.07, -m * 0.24), c + Vector2(-m * 0.07, -m * 0.24), c + Vector2(-m * 0.07, 0), c + Vector2(-m * 0.18, 0)]), fg)
		"focus", "meditation", "agility":
			var pts := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				pts.append(c + Vector2(lerpf(-m * 0.36, m * 0.36, t), -sin(t * PI) * m * 0.2))
			for i in 17:
				var t := 1.0 - float(i) / 16.0
				pts.append(c + Vector2(lerpf(-m * 0.36, m * 0.36, t), sin(t * PI) * m * 0.2))
			draw_colored_polygon(pts, fg)
			draw_circle(c, m * 0.12, bg.darkened(0.2))
			draw_circle(c, m * 0.05, fg.lightened(0.5))
		"lightwell", "spirit":
			draw_rect(Rect2(c.x - m * 0.24, c.y + m * 0.08, m * 0.48, m * 0.26), fg.darkened(0.3))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-m * 0.12, m * 0.08), c + Vector2(m * 0.12, m * 0.08),
				c + Vector2(m * 0.06, -m * 0.4), c + Vector2(-m * 0.06, -m * 0.4)]), fg)
		"time", "serendipity":
			draw_arc(c, m * 0.3, 0, TAU, 24, fg, w * 0.7)
			draw_line(c, c + Vector2(0, -m * 0.22), fg, w * 0.7)
			draw_line(c, c + Vector2(m * 0.16, m * 0.06), fg, w * 0.7)
		"mana_potion", "healing_potion", "elixir_red", "elixir_green", "elixir_blue":
			draw_rect(Rect2(c.x - m * 0.07, c.y - m * 0.36, m * 0.14, m * 0.2), Color("c0a080"))
			draw_circle(c + Vector2(0, m * 0.1), m * 0.26, fg)
			draw_circle(c + Vector2(-m * 0.08, m * 0.02), m * 0.07, fg.lightened(0.5))
		"food":
			draw_circle(c + Vector2(-m * 0.06, -m * 0.04), m * 0.24, fg)
			draw_line(c + Vector2(m * 0.1, m * 0.1), c + Vector2(m * 0.32, m * 0.32), Color("f0e0c0"), w * 1.2)
		_:
			var ch := SpellIcon.initials(icon)
			var fs := int(m * (0.5 if ch.length() == 1 else 0.38))
			draw_string_outline(Style.heading_font(), Vector2(0, c.y + fs * 0.36), ch, HORIZONTAL_ALIGNMENT_CENTER, s.x, fs, 3, Color(0, 0, 0, 0.8))
			draw_string(Style.heading_font(), Vector2(0, c.y + fs * 0.36), ch, HORIZONTAL_ALIGNMENT_CENTER, s.x, fs, fg)
	draw_rect(r, Color(0, 0, 0, 0.9), false, 2.0)
	draw_rect(r.grow(-2), Color(1, 1, 1, 0.12), false, 1.0)


## "Improved Shield Block" -> "SB": up to two initials, skipping filler words.
static func initials(text: String) -> String:
	var out := ""
	for w in text.replace("-", " ").replace("(", "").replace(")", "").split(" ", false):
		if w in ["Improved", "of", "the", "and", "Summon"]:
			continue
		out += w.substr(0, 1).to_upper()
		if out.length() == 2:
			break
	return out if out != "" else text.substr(0, 1).to_upper()
