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


## The spells in action bar order: drag one (or use its arrows) to give it another slot and key.
func _spellbook() -> Control:
	var p := Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)
	p.custom_minimum_size.x = 360
	var v := Style.vbox(6)
	p.add_child(v)
	var head := Style.hbox(8)
	var t := Style.title("Spellbook", 22)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(Style.button("Key bindings", Callable(get_tree().current_scene, "open_key_bindings")))
	v.add_child(head)
	var keys := []
	for a in Settings.ACTION_NAMES:
		if Settings.key_label(a) != "":
			keys.append("%s %s" % [Settings.key_label(a), "drinks a mana potion" if a == "potion" else "pauses"])
	var help := Style.label("Drag a spell, or use its arrows, to move it to another action bar slot. Hover a party frame and press the key to cast on it, or click a frame to target it. %s." %
		", ".join(keys), 12, Style.C["muted"])
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(help)
	var list := Style.vbox(4)
	var bar := Game.action_bar()
	var ps := Game.priest_combat_spec({})
	for i in bar.size():
		list.add_child(_spell_row(bar[i], i, bar.size(), ps))
	if Game.priest().has("bar"):
		var rs := Style.button("Default order", Game.reset_action_bar)
		rs.size_flags_horizontal = Control.SIZE_SHRINK_END
		list.add_child(rs)
	var upcoming := []
	for id in Spells.ORDER:
		var s: Dictionary = Spells.BOOK[id]
		if not s.get("talent", false) and s["level"] > Game.level():
			upcoming.append("%s (level %d)" % [s["name"], s["level"]])
	if not upcoming.is_empty():
		var u := Style.label("Coming later: " + ", ".join(upcoming), 12, Style.C["dim"])
		u.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(u)
	var sc := Style.scroll(list)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	return p


## One spell of the bar: slot key, icon, what it does now, and arrows to move it.
func _spell_row(id: String, i: int, count: int, ps: Dictionary) -> Control:
	var s: Dictionary = Spells.BOOK[id]
	var lvl := Game.level()
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", Style.box(Color(0, 0, 0, 0.22), Color(0.36, 0.17, 0.1), 1, 4, 5))
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_DRAG
	row.set_drag_forwarding(_drag_spell.bind(id, row), _can_drop_spell, _drop_spell.bind(i))
	var h := Style.hbox(8)
	row.add_child(h)
	var ic := SpellIcon.new(s["icon"], WowIcons.spell(id, lvl))
	ic.custom_minimum_size = Vector2(36, 36)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	var tv := Style.vbox(1)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cast_txt := "Instant" if s["cast"] == 0.0 else ("Channeled %.1fs" % s["cast"] if s.get("channel", 0) else "%.1fs cast" % s["cast"])
	var key := Settings.key_label(Settings.slot_action(i)) if i < Settings.SLOTS else ""
	var lines := ["[b]%s[/b]  [color=#8a7262][%s][/color]" % [Spells.display_name(id, lvl), key if key != "" else "no key"]]
	var amount := CombatEngine.spell_text(id, lvl, ps["heal_power"], 1.0, Game.priest()["talents"])
	if amount != "":
		lines.append("[font_size=12]%s[/font_size]" % amount)
	lines.append("[font_size=12][color=#c09f86]%s · %d mana. %s[/color][/font_size]" % [cast_txt, int(s["mana"] * Balance.scale(lvl)), s["desc"]])
	var d := Style.rich("\n".join(lines), 14)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(d)
	h.add_child(tv)
	var arrows := Style.vbox(2)
	for step in [-1, 1]:
		var b := Style.button("▲" if step < 0 else "▼", Game.move_spell.bind(id, i + step))
		b.custom_minimum_size = Vector2(26, 22)
		b.add_theme_font_size_override("font_size", 10)
		b.disabled = i + step < 0 or i + step >= count
		b.tooltip_text = "Move up a slot" if step < 0 else "Move down a slot"
		arrows.add_child(b)
	h.add_child(arrows)
	return row


func _drag_spell(_at: Vector2, id: String, row: Control) -> Variant:
	var ic := SpellIcon.new(Spells.BOOK[id]["icon"], WowIcons.spell(id, Game.level()))
	ic.size = Vector2(40, 40)
	row.set_drag_preview(ic)
	return {"spell": id}


func _can_drop_spell(_at: Vector2, data) -> bool:
	return data is Dictionary and data.has("spell")


func _drop_spell(_at: Vector2, data, i: int) -> void:
	Game.move_spell(data["spell"], i)
