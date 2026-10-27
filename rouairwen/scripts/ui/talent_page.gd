class_name TalentPage
extends HBoxContainer
## Discipline and Holy talent trees, and the spellbook with keybinds.

const CELL := 40


func rebuild() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.clear(self)
	var left := Style.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(left)
	var head := Style.hbox(10)
	var hv := Style.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(Style.title("Talents", 26))
	var free := Game.talent_points_free()
	var spent := Talents.spent(Game.priest()["talents"])
	var info := "You earn one talent point per level from level 10. " + ("[color=#6ee06e]%d point%s to spend.[/color]" % [free, "" if free == 1 else "s"] if free > 0 else "%d spent." % spent)
	if Game.level() < Balance.TALENT_START_LEVEL:
		info = "Talents unlock at level 10."
	hv.add_child(Style.rich(info, 14))
	head.add_child(hv)
	if spent > 0:
		head.add_child(Style.button("Reset talents (%s)" % Balance.money(Balance.respec_cost(Game.level(), Game.priest()["respecs"])), _respec))
	left.add_child(head)
	var trees := Style.hbox(12)
	trees.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for tree_id in ["discipline", "holy"]:
		trees.add_child(_tree(tree_id))
	left.add_child(trees)
	add_child(_spellbook())


func _respec() -> void:
	var main = get_tree().current_scene
	main.confirm("Unlearn all your talents for %s?" % Balance.money(Balance.respec_cost(Game.level(), Game.priest()["respecs"])), Game.respec, "Reset")


func _tree(tree_id: String) -> Control:
	var tree: Dictionary = Talents.TREES[tree_id]
	var talents: Dictionary = Game.priest()["talents"]
	var p := Style.panel(Color(0.07, 0.04, 0.06, 0.92), tree["color"].darkened(0.5), 2, 10)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Style.vbox(6)
	p.add_child(v)
	var spent_here := Talents.spent_in(talents, tree_id)
	var h := Style.hbox(6)
	var t := Style.label(tree["name"], 20, tree["color"], true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(Style.label("%d points" % spent_here, 14, Style.C["muted"]))
	v.add_child(h)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 2)
	var cells := {}
	for tal in tree["talents"]:
		cells[Vector2i(tal["col"], tal["tier"])] = tal
	for tier in 7:
		for col in 3:
			var key := Vector2i(col, tier)
			if cells.has(key):
				grid.add_child(_talent_cell(cells[key], tree_id, talents))
			else:
				var empty := Control.new()
				empty.custom_minimum_size = Vector2(CELL, CELL + 14)
				grid.add_child(empty)
	var c := CenterContainer.new()
	c.add_child(grid)
	v.add_child(c)
	return p


func _talent_cell(tal: Dictionary, tree_id: String, talents: Dictionary) -> Control:
	var rank: int = talents.get(tal["id"], 0)
	var max_rank: int = tal["ranks"]
	var reachable: bool = Talents.spent_in(talents, tree_id) >= tal["tier"] * Talents.POINTS_PER_TIER and Game.level() >= Balance.TALENT_START_LEVEL
	var can := Talents.can_learn(talents, tal["id"], Game.level())
	var v := Style.vbox(1)
	var b := TipButton.new()
	b.custom_minimum_size = Vector2(CELL, CELL)
	var border := Color("ffd86b") if rank >= max_rank else (Color("6ee06e") if can or rank > 0 else Color(0.3, 0.25, 0.2))
	b.add_theme_stylebox_override("normal", Style.box(Color.BLACK, border, 2, 4, 0))
	b.add_theme_stylebox_override("hover", Style.box(Color.BLACK, Color.WHITE, 2, 4, 0))
	b.add_theme_stylebox_override("pressed", Style.box(Color.BLACK, Color.WHITE, 2, 4, 0))
	var icon := SpellIcon.new(tal["icon"], WowIcons.talent(tal["id"]))
	icon.dim = not reachable and rank == 0
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 3
	icon.offset_top = 3
	icon.offset_right = -3
	icon.offset_bottom = -3
	b.add_child(icon)
	var tip := "[b][color=#ffffff]%s[/color][/b]\n[color=#c0c0c0]Rank %d/%d[/color]\n" % [tal["name"], rank, max_rank]
	if tal.get("spell", false):
		tip += "[color=#ffd86b]Grants a new spell.[/color]\n"
	tip += Talents.describe(tal, maxi(rank, 1))
	if rank > 0 and rank < max_rank:
		tip += "\n\n[color=#c0c0c0]Next rank:[/color]\n" + Talents.describe(tal, rank + 1)
	if not reachable:
		tip += "\n\n[color=#ff5a4a]Requires %d points in %s.[/color]" % [tal["tier"] * Talents.POINTS_PER_TIER, Talents.TREES[tree_id]["name"]]
	elif can:
		tip += "\n\n[color=#6ee06e]Click to learn.[/color]"
	b.set_tip(tip)
	b.pressed.connect(Game.learn.bind(tal["id"]))
	v.add_child(b)
	var r := Style.label("%d/%d" % [rank, max_rank], 12, border if rank > 0 or can else Style.C["dim"])
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	return v


func _spellbook() -> Control:
	var p := Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)
	p.custom_minimum_size.x = 330
	var v := Style.vbox(6)
	p.add_child(v)
	v.add_child(Style.title("Spellbook", 22))
	v.add_child(Style.label("Hover a party frame and press the key to cast on it, or click a frame to target it. F drinks a mana potion, Space pauses.", 12, Style.C["muted"]))
	v.get_child(1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var list := Style.vbox(6)
	var known := Spells.known(Game.level(), Game.priest()["talents"])
	for i in known.size():
		var id: String = known[i]
		var s: Dictionary = Spells.BOOK[id]
		var h := Style.hbox(8)
		var ic := SpellIcon.new(s["icon"], WowIcons.spell(id, Game.level()))
		ic.custom_minimum_size = Vector2(36, 36)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(ic)
		var tv := Style.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cast_txt := "Instant" if s["cast"] == 0.0 else ("Channeled %.1fs" % s["cast"] if s.get("channel", 0) else "%.1fs cast" % s["cast"])
		tv.add_child(Style.rich("[b]%s[/b]  [color=#8a7262][%s][/color]" % [Spells.display_name(id, Game.level()), Spells.key_label(i)], 14))
		var d := Style.label("%s · %d mana. %s" % [cast_txt, int(s["mana"] * Balance.scale(Game.level())), s["desc"]], 12, Style.C["muted"])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(d)
		h.add_child(tv)
		list.add_child(h)
	var upcoming := []
	for id in Spells.ORDER:
		var s: Dictionary = Spells.BOOK[id]
		if not s.get("talent", false) and s["level"] > Game.level():
			upcoming.append("%s (level %d)" % [s["name"], s["level"]])
	if not upcoming.is_empty():
		var u := Style.label("Coming later: " + ", ".join(upcoming), 12, Style.C["dim"])
		u.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(u)
	v.add_child(Style.scroll(list))
	return p
