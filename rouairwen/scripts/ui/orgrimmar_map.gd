class_name OrgrimmarMap
extends Control
## The hub's menu: a painted map of Orgrimmar, north up, from the Valley of Wisdom down to the gates.
## Each place opens a page; hover one for what it holds. The hub's backdrop shows the place you're at.

## Places, in map coordinates (0..1 of the map, north up), with where their label goes.
const PLACES := [
	{"page": "raids", "name": "Grommash Hold", "district": "wisdom", "at": Vector2(0.40, 0.10), "label": "right",
		"desc": "Thrall's seat. Raids set out from here."},
	{"page": "missions", "name": "War Table", "district": "wisdom", "at": Vector2(0.16, 0.21), "label": "right",
		"desc": "Send guildmates on missions, even while you're away."},
	{"page": "recruit", "name": "Recruitment", "district": "honor", "at": Vector2(0.84, 0.245), "label": "below",
		"desc": "Warriors, hunters and rogues train here: recruit and train guildmates."},
	{"page": "prestige", "name": "Hall of Legends", "district": "honor", "at": Vector2(0.72, 0.36), "label": "below",
		"desc": "Where the Horde's greatest guilds are ranked by prestige."},
	{"page": "shop", "name": "Supplies", "district": "drag", "at": Vector2(0.53, 0.53), "label": "right",
		"desc": "Potions, elixirs and food from the Drag's merchants."},
	{"page": "dungeons", "name": "Dungeons", "district": "cleft", "at": Vector2(0.23, 0.48), "label": "below",
		"desc": "Ragefire Chasm opens under the Cleft of Shadow. Every dungeon, from level 10."},
	{"page": "talents", "name": "Talents & Spells", "district": "spirits", "at": Vector2(0.17, 0.71), "label": "below",
		"desc": "Your talents and runes, your spellbook and its key bindings."},
	{"page": "quests", "name": "Quest Board", "district": "strength", "at": Vector2(0.55, 0.69), "label": "right",
		"desc": "Quests posted for your level, with gold and gear for rewards."},
	{"page": "hall", "name": "Guild Hall", "district": "strength", "at": Vector2(0.84, 0.81), "label": "above",
		"desc": "<Lumens>' own hall: upgrades and the guild's chronicle."},
]
const DISTRICTS := {
	"wisdom": {"name": "Valley of Wisdom", "at": Vector2(0.36, 0.025)},
	"honor": {"name": "Valley of Honor", "at": Vector2(0.80, 0.17)},
	"drag": {"name": "The Drag", "at": Vector2(0.28, 0.335)},
	"cleft": {"name": "Cleft of Shadow", "at": Vector2(0.25, 0.60)},
	"spirits": {"name": "Valley of Spirits", "at": Vector2(0.20, 0.91)},
	"strength": {"name": "Valley of Strength", "at": Vector2(0.52, 0.86)},
}
## The scene the backdrop paints for each page (the Character Sheet and Roster are at the guild hall).
const SCENES := {"quests": "strength", "shop": "drag", "dungeons": "cleft", "recruit": "honor", "prestige": "legends",
	"talents": "spirits", "raids": "grommash", "missions": "war_table", "hall": "guild_hall", "guild": "guild_hall",
	"character": "guild_hall"}

const R := 12.0
const ROCK := Color("3a160d")
const CLIFF := Color("5c2414")
const FLOOR := Color("9a6a40")
const PATH := Color("c79a62")

var hub
var _hover := ""
var _t := 0.0
## [page, center, label rect] of each place as last drawn.
var _spots: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(240, 380)
	mouse_exited.connect(_set_hover.bind(""))


static func scene_for(page: String) -> String:
	return SCENES.get(page, "strength")


static func place(page: String) -> Dictionary:
	for p in PLACES:
		if p["page"] == page:
			return p
	return {}


func _process(delta: float) -> void:
	_t += delta
	if is_visible_in_tree():
		queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_set_hover(_spot_at(ev.position))
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var page := _spot_at(ev.position)
		if page != "" and hub != null:
			hub.open_page(page)
			accept_event()


func _set_hover(page: String) -> void:
	_hover = page
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if page != "" else Control.CURSOR_ARROW


func _spot_at(pos: Vector2) -> String:
	for s in _spots:
		if pos.distance_to(s[1]) <= R + 5.0 or s[2].grow(2.0).has_point(pos):
			return s[0]
	return ""


func _get_tooltip(at_position: Vector2) -> String:
	var page := _spot_at(at_position)
	if page == "":
		return ""
	var p := place(page)
	var s := "[b][color=#ffd86b]%s[/color][/b]  [color=#c09f86]%s[/color]\n%s" % [p["name"], DISTRICTS[p["district"]]["name"], p["desc"]]
	var lock := _locked(page)
	if lock > 0:
		s += "\n[color=#ff8a6a]Opens at level %d.[/color]" % lock
	elif page == "prestige":
		s += "\n[color=#d8a8ff]Rank #%d · %d prestige to spend[/color]" % [Prestige.rank(Game.prestige_total()), Game.prestige()]
	elif page == "talents" and (Game.talent_points_free() > 0 or Game.empty_rune_slots() > 0):
		if Game.talent_points_free() > 0:
			s += "\n[color=#6ee06e]%d talent point(s) to spend![/color]" % Game.talent_points_free()
		if Game.empty_rune_slots() > 0:
			s += "\n[color=#6ee06e]%d empty rune slot(s) to engrave![/color]" % Game.empty_rune_slots()
	elif page == "hall":
		s += "\n[color=#c09f86]%s[/color]" % Balance.HALL_NAMES[Game.hall()]
	return s


func _make_custom_tooltip(for_text: String) -> Object:
	return TipButton.make_tip(for_text, 260)


## The level a place opens at, or 0 when it is open.
func _locked(page: String) -> int:
	if page == "dungeons" and Game.level() < 10:
		return 10
	if page in ["raids", "prestige"] and Game.level() < Balance.MAX_LEVEL:
		return Balance.MAX_LEVEL
	return 0


## Map coordinates to pixels, with a margin for the labels.
func _px(p: Vector2) -> Vector2:
	return Vector2(6, 6) + p * (size - Vector2(12, 12))


func _draw() -> void:
	if size.x <= 0:
		return
	_draw_land()
	_draw_landmarks()
	var font := Style.bold_font()
	for k in DISTRICTS:
		var d: Dictionary = DISTRICTS[k]
		var c := _px(d["at"])
		var tw := font.get_string_size(d["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var x := clampf(c.x - tw / 2.0, 2.0, size.x - tw - 2.0)
		draw_string_outline(font, Vector2(x, c.y + 4), d["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color(0, 0, 0, 0.75))
		draw_string(font, Vector2(x, c.y + 4), d["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.93, 0.82, 0.62, 0.8))
	_spots.clear()
	for p in PLACES:
		_draw_place(p, font)


# ---------------------------------------------------------------- land

func _blob(center: Vector2, radius: Vector2, color: Color, seed_value: int, grow := 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pts := PackedVector2Array()
	var n := 22
	for i in n:
		var a := TAU * i / n
		var k := 1.0 + rng.randf_range(-0.12, 0.1)
		pts.append(_px(center) + Vector2(cos(a) * (radius.x * k + grow) * size.x, sin(a) * (radius.y * k + grow * 0.6) * size.y))
	draw_colored_polygon(pts, color)


func _road(points: Array, width: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for p in points:
		pts.append(_px(p))
	draw_polyline(pts, color, width * size.x, true)
	for p in pts:
		draw_circle(p, width * size.x * 0.5, color)


const AREAS := [
	["wisdom", Vector2(0.37, 0.13), Vector2(0.31, 0.10)],
	["honor", Vector2(0.79, 0.29), Vector2(0.19, 0.13)],
	["cleft", Vector2(0.26, 0.50), Vector2(0.15, 0.065)],
	["spirits", Vector2(0.20, 0.75), Vector2(0.18, 0.12)],
	["strength", Vector2(0.62, 0.74), Vector2(0.24, 0.11)],
]
const ROADS := [
	[[Vector2(0.58, 0.70), Vector2(0.52, 0.55), Vector2(0.47, 0.38), Vector2(0.42, 0.22)], 0.075],
	[[Vector2(0.49, 0.44), Vector2(0.64, 0.34)], 0.055],
	[[Vector2(0.50, 0.52), Vector2(0.36, 0.50)], 0.045],
	[[Vector2(0.44, 0.76), Vector2(0.32, 0.75)], 0.05],
	[[Vector2(0.66, 0.80), Vector2(0.70, 0.99)], 0.06],
]


func _draw_land() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ROCK)
	# Rocky texture
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 70:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		draw_circle(p, rng.randf_range(2.0, 9.0), Color(0.3, 0.1, 0.05, 0.35))
	# Cliffs, then the canyon floor inside them
	for a in AREAS:
		_blob(a[1], a[2], CLIFF, hash(a[0]), 0.035)
	for r in ROADS:
		_road(r[0], r[1] + 0.05, CLIFF)
	for a in AREAS:
		var col := FLOOR
		if a[0] == "cleft":
			col = Color("3a2030")
		elif a[0] == "spirits":
			col = Color("8a6a48")
		_blob(a[1], a[2], col, hash(a[0]))
	for r in ROADS:
		_road(r[0], r[1], PATH.darkened(0.15))
	# The Drag's cobbles stand out
	_road(ROADS[0][0], 0.03, PATH)


func _draw_landmarks() -> void:
	# Grommash Hold
	var gh := _px(Vector2(0.40, 0.10))
	var s := size.x * 0.07
	draw_colored_polygon(PackedVector2Array([gh + Vector2(-s * 1.4, s * 0.5), gh + Vector2(s * 1.4, s * 0.5), gh + Vector2(s * 0.6, -s * 0.7),
		gh + Vector2(-s * 0.6, -s * 0.7)]), Color("6b4424"))
	for i in 5:
		var x := gh.x - s + s * 0.5 * i
		draw_line(Vector2(x, gh.y - s * 0.6), Vector2(x + (i - 2) * 1.5, gh.y - s * 1.2), Color("eadcc0"), 2.0)
	# Huts
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for c in [Vector2(0.62, 0.66), Vector2(0.70, 0.78), Vector2(0.48, 0.80), Vector2(0.80, 0.70), Vector2(0.10, 0.80), Vector2(0.26, 0.82),
			Vector2(0.88, 0.33), Vector2(0.70, 0.24), Vector2(0.20, 0.10), Vector2(0.58, 0.16)]:
		var p := _px(c)
		var hs := size.x * rng.randf_range(0.022, 0.032)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-hs, hs * 0.6), p + Vector2(hs, hs * 0.6), p + Vector2(0, -hs * 0.8)]), Color("6b4424"))
		draw_line(p + Vector2(-hs, hs * 0.6), p + Vector2(hs, hs * 0.6), Color("3d2614"), 1.5)
	# Valley of Spirits pond
	var pond := _px(Vector2(0.22, 0.79))
	draw_set_transform(pond, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, size.x * 0.085, Color("2f5f7a"))
	draw_circle(Vector2.ZERO, size.x * 0.06, Color("3f7a96"))
	draw_set_transform(Vector2.ZERO)
	# Valley of Honor's arena ring
	var ring := _px(Vector2(0.78, 0.31))
	draw_set_transform(ring, 0.0, Vector2(1.0, 0.6))
	draw_arc(Vector2.ZERO, size.x * 0.06, 0.0, TAU, 24, Color("5a3418"), 3.0)
	draw_set_transform(Vector2.ZERO)
	# Ragefire Chasm's glow in the Cleft of Shadow
	var rf := _px(Vector2(0.22, 0.52))
	var pulse := 0.5 + 0.5 * sin(_t * 2.0)
	draw_circle(rf, size.x * 0.05, Color(1.0, 0.35, 0.1, 0.18 + 0.1 * pulse))
	draw_circle(rf, size.x * 0.022, Color(1.0, 0.5, 0.15, 0.6))
	# The front gate and the walls beside it
	var gate := _px(Vector2(0.70, 0.975))
	var gs := size.x * 0.05
	draw_rect(Rect2(gate.x - gs * 2.2, gate.y - gs * 0.5, gs * 4.4, gs * 0.7), Color("4a2a16"))
	for dx in [-gs * 1.6, gs * 1.6]:
		draw_rect(Rect2(gate.x + dx - gs * 0.45, gate.y - gs * 1.2, gs * 0.9, gs * 1.4), Color("6b4424"))
		draw_line(Vector2(gate.x + dx, gate.y - gs * 1.2), Vector2(gate.x + dx, gate.y - gs * 1.8), Color("eadcc0"), 2.0)
	draw_rect(Rect2(gate.x - gs * 0.6, gate.y - gs * 0.5, gs * 1.2, gs * 0.7), Color("1a0a05"))


# ---------------------------------------------------------------- places

func _draw_place(p: Dictionary, font: Font) -> void:
	var page: String = p["page"]
	var c := _px(p["at"])
	var current: bool = hub != null and hub.page == page
	var hovered := _hover == page
	var locked := _locked(page) > 0
	if current:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		draw_circle(c, R + 7.0 + 2.0 * pulse, Color(1.0, 0.85, 0.4, 0.18 + 0.12 * pulse))
	draw_circle(c, R + 1.5, Color.BLACK)
	draw_circle(c, R, Color("2a0f08") if not locked else Color("221a18"))
	var ring := Color("ffd86b") if current else (Color.WHITE if hovered else Color("b08a50"))
	if locked and not current:
		ring = Color("6a5a50")
	draw_arc(c, R, 0.0, TAU, 28, ring, 2.5 if current or hovered else 1.8, true)
	_glyph(page, c, Color(0.55, 0.5, 0.45) if locked else Color.WHITE)
	# Talent points waiting, or an empty rune slot ("R")
	if page == "talents" and (Game.talent_points_free() > 0 or Game.empty_rune_slots() > 0):
		var b := c + Vector2(R * 0.8, -R * 0.8)
		draw_circle(b, 7.0, Color("2f8a2f"))
		var badge := str(Game.talent_points_free()) if Game.talent_points_free() > 0 else "R"
		draw_string(font, b + Vector2(-7, 4), badge, HORIZONTAL_ALIGNMENT_CENTER, 14, 10, Color.WHITE)
	# Label
	var text: String = p["name"]
	var fs := 13
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := Vector2.ZERO
	match p["label"]:
		"right":
			pos = Vector2(c.x + R + 5.0, c.y + ts.y * 0.3)
		"left":
			pos = Vector2(c.x - R - 5.0 - ts.x, c.y + ts.y * 0.3)
		"above":
			pos = Vector2(c.x - ts.x / 2.0, c.y - R - 5.0)
		_:
			pos = Vector2(c.x - ts.x / 2.0, c.y + R + ts.y * 0.85)
	pos.x = clampf(pos.x, 2.0, size.x - ts.x - 2.0)
	var col := Color("ffd86b") if current else (Color.WHITE if hovered else Color(0.96, 0.9, 0.8))
	if locked:
		col = Color(0.7, 0.62, 0.55)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if locked:
		var lt := "Level %d" % _locked(page)
		draw_string_outline(font, pos + Vector2(0, 12), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, Color(0, 0, 0, 0.9))
		draw_string(font, pos + Vector2(0, 12), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.55, 0.45, 0.9))
	_spots.append([page, c, Rect2(pos - Vector2(0, ts.y * 0.8), ts)])


## A small picture for each place, drawn in the marker.
func _glyph(page: String, c: Vector2, col: Color) -> void:
	var gold := Color("ffd24a") if col == Color.WHITE else col
	match page:
		"quests":
			draw_rect(Rect2(c.x - 1.8, c.y - 7, 3.6, 9), gold)
			draw_rect(Rect2(c.x - 1.8, c.y + 4, 3.6, 3.4), gold)
		"shop":
			draw_circle(c, 6.5, gold)
			draw_arc(c, 4.2, 0.0, TAU, 16, Color("8a5a10"), 1.2)
		"dungeons":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(5, 0), c + Vector2(4, 5), c + Vector2(0, 7),
				c + Vector2(-4, 5), c + Vector2(-5, 0)]), Color("ff7a2a") if col == Color.WHITE else col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(2.5, 3), c + Vector2(0, 6), c + Vector2(-2.5, 3)]),
				Color("ffd24a") if col == Color.WHITE else col.lightened(0.2))
		"recruit":
			draw_line(c + Vector2(-6, 6), c + Vector2(6, -6), col, 2.2)
			draw_line(c + Vector2(6, 6), c + Vector2(-6, -6), col, 2.2)
			draw_line(c + Vector2(-6, 2), c + Vector2(-2, 6), gold, 2.0)
			draw_line(c + Vector2(6, 2), c + Vector2(2, 6), gold, 2.0)
		"prestige":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-7, 5), c + Vector2(-7, -4), c + Vector2(-3.5, 0), c + Vector2(0, -6),
				c + Vector2(3.5, 0), c + Vector2(7, -4), c + Vector2(7, 5)]), Color("d8a8ff") if col == Color.WHITE else col)
		"talents":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(2, -2), c + Vector2(8, 0), c + Vector2(2, 2),
				c + Vector2(0, 8), c + Vector2(-2, 2), c + Vector2(-8, 0), c + Vector2(-2, -2)]), Color("fff2b0") if col == Color.WHITE else col)
		"raids":
			draw_circle(c + Vector2(0, -1), 6.0, col)
			draw_rect(Rect2(c.x - 3.5, c.y + 3, 7, 4), col)
			draw_circle(c + Vector2(-2.3, -1.5), 1.7, Color.BLACK)
			draw_circle(c + Vector2(2.3, -1.5), 1.7, Color.BLACK)
		"missions":
			draw_line(c + Vector2(-4, 8), c + Vector2(-4, -8), col, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -8), c + Vector2(7, -5), c + Vector2(-3, -1)]), Color("e04a3a") if col == Color.WHITE else col)
		"hall":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-7, 0), c + Vector2(0, -7), c + Vector2(7, 0)]), gold)
			draw_rect(Rect2(c.x - 5, c.y, 10, 7), col)
			draw_rect(Rect2(c.x - 1.5, c.y + 2.5, 3, 4.5), Color("2a0f08"))
