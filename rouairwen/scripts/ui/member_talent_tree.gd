class_name MemberTalentTree
extends Control
## A guildmate's talent tree laid out like WoW's: tiers from top to bottom, arrows from a talent to
## the ones it unlocks, abilities framed in gold, and each talent's rank in the corner of its icon.

const CELL := 42
const GAP_X := 34
const GAP_Y := 20
const GOLD := Color("ffd86b")
const GREEN := Color("6ee06e")
const LOCKED := Color(0.32, 0.27, 0.22)

var m: Dictionary
var _rects := {}


func setup(member: Dictionary) -> MemberTalentTree:
	m = member
	var tree := SpecTalents.tree(m["spec"])
	var cols := 1
	for t in tree:
		cols = maxi(cols, t[3] + 1)
	custom_minimum_size = Vector2(cols * CELL + (cols - 1) * GAP_X, SpecTalents.TIERS * CELL + (SpecTalents.TIERS - 1) * GAP_Y)
	for t in tree:
		var r := Rect2(Vector2(t[3] * (CELL + GAP_X), t[2] * (CELL + GAP_Y)), Vector2(CELL, CELL))
		_rects[t[0]] = r
		var cell := _cell(t)
		cell.position = r.position
		add_child(cell)
	return self


func _talents() -> Dictionary:
	return m.get("talents", {})


func _maxed(id: String) -> bool:
	var t := SpecTalents.find(m["spec"], id)
	return not t.is_empty() and _talents().get(id, 0) >= t[4]


## Prerequisite arrows, under the icons: gold once the prerequisite is maxed.
func _draw() -> void:
	for t in SpecTalents.tree(m["spec"]):
		var req := SpecTalents.req(t)
		if req == "" or not _rects.has(req):
			continue
		var a: Rect2 = _rects[req]
		var b: Rect2 = _rects[t[0]]
		var pts := PackedVector2Array()
		if is_equal_approx(a.position.x, b.position.x):
			pts = [Vector2(a.get_center().x, a.end.y), Vector2(b.get_center().x, b.position.y - 3)]
		else:
			var y := a.get_center().y
			var sx := a.end.x if b.position.x > a.position.x else a.position.x
			if is_equal_approx(a.position.y, b.position.y):
				pts = [Vector2(sx, y), Vector2(b.position.x - 3 if b.position.x > a.position.x else b.end.x + 3, y)]
			else:
				pts = [Vector2(sx, y), Vector2(b.get_center().x, y), Vector2(b.get_center().x, b.position.y - 3)]
		var c := GOLD if _maxed(req) else LOCKED
		draw_polyline(pts, Color(0, 0, 0, 0.7), 7.0)
		draw_polyline(pts, c, 3.0)
		var tip := pts[pts.size() - 1]
		var dir := (tip - pts[pts.size() - 2]).normalized()
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([tip, tip - dir * 9.0 + side * 6.0, tip - dir * 9.0 - side * 6.0]), c)


func _cell(t: Array) -> Control:
	var spec_id: String = m["spec"]
	var tal := _talents()
	var rank: int = tal.get(t[0], 0)
	var max_rank: int = t[4]
	var fx: Dictionary = t[5]
	var is_ability := fx.has("ability")
	var req := SpecTalents.req(t)
	var tier_ok: bool = SpecTalents.spent(tal) >= t[2] * SpecTalents.POINTS_PER_TIER and Game.level() >= SpecTalents.START_LEVEL
	var req_ok := req == "" or _maxed(req)
	var can := SpecTalents.can_learn(spec_id, tal, t[0], Game.level())
	var border := GOLD if rank >= max_rank else (GREEN if can or rank > 0 else LOCKED)
	var b := TipButton.new()
	b.custom_minimum_size = Vector2(CELL, CELL)
	b.size = Vector2(CELL, CELL)
	# Abilities get a thicker, rounded gold-tinted frame, like a spell rather than a passive.
	var width := 3 if is_ability else 2
	var radius := 9 if is_ability else 3
	var frame := border if rank > 0 or can else (Color("8a6a2a") if is_ability else LOCKED)
	b.add_theme_stylebox_override("normal", Style.box(Color.BLACK, frame, width, radius, 0))
	b.add_theme_stylebox_override("hover", Style.box(Color.BLACK, Color.WHITE, width, radius, 0))
	b.add_theme_stylebox_override("pressed", Style.box(Color.BLACK, Color.WHITE, width, radius, 0))
	var icon := SpellIcon.new(t[1], WowIcons.guild_talent(m["class"], t[0]))
	icon.tint = Style.class_color(m["class"])
	icon.dim = rank == 0 and not can
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = width + 1
	icon.offset_top = width + 1
	icon.offset_right = -width - 1
	icon.offset_bottom = -width - 1
	b.add_child(icon)
	# Rank in the bottom-right corner
	var rp := PanelContainer.new()
	rp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rp.add_theme_stylebox_override("panel", Style.box(Color(0, 0, 0, 0.88), border.darkened(0.2), 1, 3, 0))
	var rl := Style.label("%d/%d" % [rank, max_rank], 11, border if rank > 0 or can else Style.C["dim"])
	rl.add_theme_constant_override("outline_size", 0)
	rp.add_child(rl)
	rp.position = Vector2(CELL - 22, CELL - 9)
	b.add_child(rp)
	b.set_tip(_tip(t, rank, tier_ok, req_ok, can))
	b.pressed.connect(Game.learn_member_talent.bind(m, t[0]))
	return b


func _tip(t: Array, rank: int, tier_ok: bool, req_ok: bool, can: bool) -> String:
	var fx: Dictionary = t[5]
	var tip := "[b][color=#ffffff]%s[/color][/b]\n[color=#c0c0c0]Rank %d/%d[/color]\n" % [t[1], rank, t[4]]
	if fx.has("ability"):
		var ab: Dictionary = SpecTalents.ABILITIES[fx["ability"]].duplicate(true)
		ab["id"] = fx["ability"]
		for a in Game.member_abilities(m):
			if a["id"] == ab["id"]:
				ab = a
		tip += "[color=#ffd86b]Ability: used on their own in fights.[/color]\n" + SpecTalents.ability_text(ab)
		var rest := fx.duplicate()
		rest.erase("ability")
		if not rest.is_empty():
			tip += "\n" + SpecTalents.effects_text(rest)
	else:
		tip += ("Per rank: " if t[4] > 1 else "") + SpecTalents.effects_text(fx)
		if rank > 0 and t[4] > 1:
			var now := {}
			SpecTalents.add_effects(now, fx, rank)
			tip += "\n[color=#6ee06e]Now: %s[/color]" % SpecTalents.effects_text(now)
	if not tier_ok:
		tip += "\n\n[color=#ff5a4a]Requires %d points spent.[/color]" % (t[2] * SpecTalents.POINTS_PER_TIER)
	if not req_ok:
		var r := SpecTalents.find(m["spec"], SpecTalents.req(t))
		tip += "\n[color=#ff5a4a]Requires %d point%s in %s.[/color]" % [r[4], "" if r[4] == 1 else "s", r[1]]
	elif can:
		tip += "\n\n[color=#6ee06e]Click to learn.[/color]"
	return tip
