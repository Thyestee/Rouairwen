class_name CharacterPage
extends VBoxContainer
## Character sheet: stats (hover a stat's name for what it means), effects, gear, and talents,
## for Thyeste or any guildmate picked from the dropdown.

const CELL := 40

const STAT_HELP := {
	"Health": "How much damage they can take before dying.",
	"Mana": "Thyeste's pool for casting spells. Every heal costs mana.",
	"Mana regeneration": "Mana regained per second. While casting (within 5 sec of spending mana) only a part of it continues; Meditation raises that part.",
	"Healing bonus": "How much more your heals restore than base, from gear, talents and elixirs.",
	"Critical heal chance": "Chance for a heal to restore 50% more. Holy Specialization raises it.",
	"Grade": "Their recruitment grade, F to SSS+. It multiplies their damage, and (square-rooted) their health.",
	"Role": "Tanks hold enemies' attention, melee fight up close, ranged fight from afar.",
	"Damage per second": "Average damage dealt each second against a single target, crits and attack speed included.",
	"Critical strike": "Chance for a hit to deal double damage (more with critical damage effects).",
	"Critical damage": "How hard their critical strikes hit, as a multiple of a normal hit.",
	"Attack speed": "How much faster than normal their attacks come.",
	"Damage taken": "Share of incoming damage that actually hurts them, after armor and effects. Lower is better.",
	"Dodge": "Chance to dodge an enemy's melee swing entirely.",
	"Threat hold": "For tanks: how well they keep enemies attacking them instead of the rest of the party.",
	"Attention drawn": "How likely enemies are to pick them when switching targets. Lower is safer.",
	"Interrupt": "Chance to stop an enemy spell before it is cast (once every 8 sec).",
	"Gear bonus": "How much their equipped items add to their power, for their level and role.",
	"Average item level": "Average level of their equipped items. Gear falls behind as they level up.",
	"Power": "Overall strength used for recommended power: grade x gear, plus talents, traits and affixes.",
	"Talent points": "One point per level from 10, up to 36 for guildmates (51 for Thyeste).",
}

var hub
var body: Control


func rebuild() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	Style.clear(self)
	var m := Game.member(hub.selected_member)
	if m.is_empty():
		hub.selected_member = "priest"
		m = Game.priest()
	var head := Style.hbox(10)
	head.add_child(Style.title("Character Sheet", 26))
	var pick := OptionButton.new()
	pick.focus_mode = Control.FOCUS_NONE
	pick.custom_minimum_size = Vector2(320, 34)
	var ids := ["priest"]
	pick.add_item("%s — Priest (you)" % Game.priest()["name"])
	for g in Game.members():
		ids.append(g["id"])
		pick.add_item("%s — %s %s (%s)" % [g["name"], ClassData.SPECS[g["spec"]]["name"], ClassData.class_name_of(g["class"]), Tiers.name_of(g["tier"])])
	pick.select(ids.find(hub.selected_member) if hub.selected_member in ids else 0)
	pick.item_selected.connect(_pick.bind(ids))
	head.add_child(pick)
	head.add_child(Style.spacer())
	var group := ButtonGroup.new()
	for tab in [["stats", "Stats"], ["talents", "Talents"]]:
		var b := Style.button(tab[1])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = hub.sheet_tab == tab[0]
		b.custom_minimum_size.x = 110
		b.pressed.connect(_tab.bind(tab[0]))
		head.add_child(b)
	add_child(head)
	if hub.sheet_tab == "talents":
		if Game.is_priest(m):
			var tp := TalentPage.new()
			add_child(tp)
			tp.rebuild()
		else:
			add_child(_member_talents(m))
	else:
		add_child(_stats(m))


func _pick(index: int, ids: Array) -> void:
	hub.selected_member = ids[index]
	rebuild()


func _tab(tab: String) -> void:
	hub.sheet_tab = tab
	rebuild()


# ---------------------------------------------------------------- stats

func _stats(m: Dictionary) -> Control:
	var h := Style.hbox(12)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var is_p := Game.is_priest(m)
	var cls := Game.member_class(m)
	var card := _card()
	card.custom_minimum_size.x = 360
	var v := Style.vbox(4)
	card.add_child(v)
	v.add_child(Style.label(m["name"], 26, Style.class_color(cls), true))
	if is_p:
		v.add_child(Style.label("Level %d %s Priest · guild leader" % [Game.level(), ClassData.RACES.get(m["race"], "")], 14, Style.C["muted"]))
	else:
		var sp: Dictionary = ClassData.SPECS[m["spec"]]
		v.add_child(Style.label("Level %d %s %s %s" % [Game.level(), ClassData.RACES.get(m["race"], ""), sp["name"], ClassData.class_name_of(cls)], 14, Style.C["muted"]))
	v.add_child(HSeparator.new())
	for row in (_priest_stats(m) if is_p else _member_stats(m)):
		v.add_child(_stat_row(row[0], row[1]))
	h.add_child(card)

	var mid := _card()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mv := Style.vbox(6)
	mid.add_child(Style.scroll(mv))
	if is_p:
		mv.add_child(Style.label("Talents", 18, Style.C["gold"], true))
		var tal: Dictionary = m["talents"]
		var lines := []
		for id in tal:
			var t := Talents.find(id)
			lines.append("[color=#ffd86b]%s[/color] %d/%d" % [t["name"], tal[id], t["ranks"]])
		mv.add_child(_wrap(Style.rich("\n".join(lines) if not lines.is_empty() else "[color=#8a7262]No talents yet.[/color]", 13)))
	else:
		mv.add_child(Style.label("Traits & affixes", 18, Style.C["gold"], true))
		mv.add_child(_wrap(Style.rich(MemberText.traits_bb(m), 13)))
		mv.add_child(Style.label("Utilities", 18, Style.C["gold"], true))
		mv.add_child(_wrap(Style.rich(MemberText.utils_bb(m["spec"]), 13)))
		mv.add_child(Style.label("All effects (talents, traits, affixes)", 18, Style.C["gold"], true))
		mv.add_child(_wrap(Style.rich(MemberText.mods_bb(Game.member_mods(m)), 13)))
	h.add_child(mid)

	var gear := _card()
	gear.custom_minimum_size.x = 280
	var gv := Style.vbox(3)
	gear.add_child(gv)
	gv.add_child(Style.label("Equipment", 18, Style.C["gold"], true))
	for slot in Items.SLOTS:
		var ib := ItemButton.new().setup(m["gear"].get(slot, {}), slot, "", true)
		ib.custom_minimum_size.y = 24
		gv.add_child(ib)
	h.add_child(gear)
	return h


func _priest_stats(m: Dictionary) -> Array:
	var spec := Game.priest_combat_spec({})
	var tal: Dictionary = m["talents"]
	var mana: float = spec["max_mana"] * (1.0 + Talents.value(tal, "mental_strength") / 100.0)
	var keep := 0.15 + Talents.value(tal, "meditation") / 100.0
	var heal_bonus: float = spec["heal_mult"] * (1.0 + (Talents.value(tal, "twin_disciplines") + Talents.value(tal, "spiritual_healing")) / 100.0) - 1.0
	return [
		["Health", "%d" % int(spec["max_hp"])],
		["Mana", "%d" % int(mana)],
		["Mana regeneration", "%.1f / sec (%.1f while casting)" % [spec["regen"], spec["regen"] * keep]],
		["Healing bonus", "+%d%%" % int(round(heal_bonus * 100.0))],
		["Critical heal chance", "%d%%" % int(5 + Talents.value(tal, "holy_specialization"))],
		["Gear bonus", "+%d%%" % int(round(Game.gear_bonus(m) * 100.0))],
		["Average item level", _avg_ilvl(m)],
		["Talent points", "%d spent, %d free" % [Talents.spent(tal), Game.talent_points_free()]],
		["Power", "%d" % int(round(100.0 * Game.member_power(m)))],
	]


func _member_stats(m: Dictionary) -> Array:
	var spec := Game.member_combat_spec(m, {})
	var mods: Dictionary = spec["mods"]
	var crit: float = 12.0 + mods.get("crit", 0.0)
	var crit_mult: float = 2.0 + mods.get("crit_dmg", 0.0) / 100.0
	var haste: float = mods.get("haste", 0.0)
	var dps: float = spec["dps"] * Balance.scale(Game.level()) * (1.0 + crit / 100.0 * (crit_mult - 1.0)) * (1.0 + haste / 100.0)
	var rows := [
		["Grade", "%s  (x%.2f)" % [Tiers.name_of(m["tier"]), Tiers.power(m["tier"])]],
		["Role", Style.role_label(spec["role"])],
		["Health", "%d" % int(spec["max_hp"])],
		["Damage per second", "%d" % int(dps)],
		["Critical strike", "%.0f%%" % crit],
		["Critical damage", "x%.2f" % crit_mult],
		["Attack speed", "+%d%%" % int(haste)],
		["Damage taken", "%d%%" % int(round(spec["mit"] * 100.0))],
		["Dodge", "%d%%" % int(mods.get("dodge", 0.0))],
	]
	if spec["role"] == "tank":
		rows.append(["Threat hold", "%d%%" % int(round(spec["aggro"] * 100.0))])
	else:
		rows.append(["Attention drawn", "%d%%" % int(round(clampf(100.0 - mods.get("threat", 0.0), 20.0, 200.0)))])
	rows.append(["Interrupt", "%d%%" % int(mods.get("interrupt", 0.0))])
	rows.append(["Gear bonus", "+%d%%" % int(round(Game.gear_bonus(m) * 100.0))])
	rows.append(["Average item level", _avg_ilvl(m)])
	rows.append(["Talent points", "%d spent, %d free" % [SpecTalents.spent(m.get("talents", {})), Game.member_talent_points_free(m)]])
	rows.append(["Power", "%d" % int(round(100.0 * Game.member_power(m)))])
	return rows


func _avg_ilvl(m: Dictionary) -> String:
	var total := 0
	for slot in m["gear"]:
		total += m["gear"][slot]["ilvl"]
	return "%d" % (total / m["gear"].size()) if not m["gear"].is_empty() else "—"


## A stat line; hovering the name explains the stat.
func _stat_row(stat: String, value: String) -> Control:
	var h := Style.hbox(8)
	var lbl := Style.label(stat, 15, Style.C["muted"])
	lbl.tooltip_text = STAT_HELP.get(stat, "")
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.mouse_default_cursor_shape = Control.CURSOR_HELP
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	var val := Style.label(value, 15, Style.C["text"])
	val.add_theme_font_override("font", Style.bold_font())
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(val)
	return h


# ---------------------------------------------------------------- guildmate talents

func _member_talents(m: Dictionary) -> Control:
	var h := Style.hbox(12)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var spec_id: String = m["spec"]
	var tal: Dictionary = m.get("talents", {})
	var col := Style.class_color(m["class"])
	var p := Style.panel(Color(0.07, 0.04, 0.06, 0.92), col.darkened(0.4), 2, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Style.vbox(8)
	p.add_child(v)
	var th := Style.hbox(8)
	var tl := Style.label("%s %s" % [ClassData.SPECS[spec_id]["name"], ClassData.class_name_of(m["class"])], 20, col, true)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tl)
	th.add_child(Style.label("%d points" % SpecTalents.spent(tal), 14, Style.C["muted"]))
	v.add_child(th)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 34)
	grid.add_theme_constant_override("v_separation", 2)
	var cells := {}
	for t in SpecTalents.tree(spec_id):
		cells[Vector2i(t[3], t[2])] = t
	for tier in 7:
		for c in 3:
			if cells.has(Vector2i(c, tier)):
				grid.add_child(_talent_cell(m, cells[Vector2i(c, tier)], col))
			else:
				var empty := Control.new()
				empty.custom_minimum_size = Vector2(CELL, CELL + 16)
				grid.add_child(empty)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	v.add_child(cc)
	h.add_child(p)

	var side := _card()
	side.custom_minimum_size.x = 360
	var sv := Style.vbox(8)
	side.add_child(sv)
	var free := Game.member_talent_points_free(m)
	var info := "Guildmates earn one talent point per level from 10, up to %d." % SpecTalents.MAX_POINTS
	if Game.level() < SpecTalents.START_LEVEL:
		info = "Talents unlock at level 10."
	elif free > 0:
		info += " [color=#6ee06e]%d point%s to spend.[/color]" % [free, "" if free == 1 else "s"]
	var il := Style.rich(info, 14)
	il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(il)
	var auto_txt := "[color=#6ee06e]Auto-assign is on: new points follow the recommended build.[/color]" if m.get("auto_talents", true) \
		else "[color=#c09f86]Customized: new points wait for you to spend them.[/color]"
	var al := Style.rich(auto_txt, 13)
	al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(al)
	var bh := Style.hbox(6)
	bh.add_child(Style.button("Recommended build", Game.auto_member_talents.bind(m), true))
	bh.add_child(Style.button("Reset (free)", Game.reset_member_talents.bind(m)))
	sv.add_child(bh)
	sv.add_child(HSeparator.new())
	sv.add_child(Style.label("Effects of these talents", 16, Style.C["gold"], true))
	var mods := {}
	for id in tal:
		var t := SpecTalents.find(spec_id, id)
		if not t.is_empty():
			SpecTalents.add_effects(mods, t[5], tal[id])
	var ml := Style.rich(MemberText.mods_bb(mods), 13)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(Style.scroll(ml))
	h.add_child(side)
	return h


func _talent_cell(m: Dictionary, t: Array, col: Color) -> Control:
	var spec_id: String = m["spec"]
	var tal: Dictionary = m.get("talents", {})
	var rank: int = tal.get(t[0], 0)
	var max_rank: int = t[4]
	var reachable: bool = SpecTalents.spent(tal) >= t[2] * SpecTalents.POINTS_PER_TIER and Game.level() >= SpecTalents.START_LEVEL
	var can := SpecTalents.can_learn(spec_id, tal, t[0], Game.level())
	var v := Style.vbox(1)
	var b := TipButton.new()
	b.custom_minimum_size = Vector2(CELL, CELL)
	var border := Color("ffd86b") if rank >= max_rank else (Color("6ee06e") if can or rank > 0 else Color(0.3, 0.25, 0.2))
	b.add_theme_stylebox_override("normal", Style.box(Color.BLACK, border, 2, 4, 0))
	b.add_theme_stylebox_override("hover", Style.box(Color.BLACK, Color.WHITE, 2, 4, 0))
	b.add_theme_stylebox_override("pressed", Style.box(Color.BLACK, Color.WHITE, 2, 4, 0))
	var icon := SpellIcon.new(t[1])
	icon.tint = col
	icon.dim = not reachable and rank == 0
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 3
	icon.offset_top = 3
	icon.offset_right = -3
	icon.offset_bottom = -3
	b.add_child(icon)
	var tip := "[b]%s[/b]\n[color=#c0c0c0]Rank %d/%d[/color]\n" % [t[1], rank, max_rank]
	tip += "Per rank: " + SpecTalents.effects_text(t[5])
	if rank > 0:
		var now := {}
		SpecTalents.add_effects(now, t[5], rank)
		tip += "\n[color=#6ee06e]Now: %s[/color]" % SpecTalents.effects_text(now)
	if not reachable:
		tip += "\n\n[color=#ff5a4a]Requires %d points spent.[/color]" % (t[2] * SpecTalents.POINTS_PER_TIER)
	elif can:
		tip += "\n\n[color=#6ee06e]Click to learn.[/color]"
	b.set_tip(tip)
	b.pressed.connect(Game.learn_member_talent.bind(m, t[0]))
	v.add_child(b)
	var r := Style.label("%d/%d" % [rank, max_rank], 12, border if rank > 0 or can else Style.C["dim"])
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	return v


# ---------------------------------------------------------------- helpers

func _card() -> PanelContainer:
	return Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)


func _wrap(r: RichTextLabel) -> RichTextLabel:
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return r
