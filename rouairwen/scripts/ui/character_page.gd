class_name CharacterPage
extends VBoxContainer
## Character sheet: stats (hover a stat's name for what it means), effects, gear, and talents,
## for Thyeste or any guildmate picked from the dropdown.

const STAT_HELP := {
	"Stamina": "Raises maximum health.",
	"Spirit": "Raises Thyeste's mana regeneration. Guildmates don't use it in fights.",
	"Health": "How much damage they can take before dying. Grows with Stamina.",
	"Mana": "Thyeste's pool for casting spells. Every heal costs mana. Grows with Intellect.",
	"Mana regeneration": "Mana regained per second, from Spirit. While casting (within 5 sec of spending mana) only a part of it continues; Meditation raises that part.",
	"Healing power": "Added to every heal, like in WoW: each spell adds a share of it, its coefficient. A direct heal gets its cast time / 3.5 sec (Lesser Heal 71%, Flash Heal 43%), Renew 100% split between its ticks, party-wide heals half of that. From Healing and Spell Damage on gear.",
	"Healing bonus": "How much more your heals restore from Spiritual Healing, healing power included, and how much more your instant spells (Renew, Power Word: Shield, Prayer of Mending, Circle of Healing) restore or absorb from Twin Disciplines. Elixirs add more in fights.",
	"Spell critical strike": "Chance for a heal to restore 50% more. From Intellect, gear and Holy Specialization.",
	"Grade": "Their grade, F to SSS+. It multiplies their damage, and (square-rooted) their health. B adds a perk, A a class spell, S a racial. Recruits come up to A; training goes further.",
	"Role": "Tanks hold enemies' attention, melee fight up close, ranged fight from afar.",
	"Damage per second": "Average damage dealt each second against a single target, crits and attack speed included.",
	"Critical damage": "How hard their critical strikes hit, as a multiple of a normal hit.",
	"Attack speed": "How much faster than normal their attacks come.",
	"Damage taken": "Share of incoming damage that actually hurts them, after armor and effects. Lower is better.",
	"Threat hold": "For tanks: how well they keep enemies attacking them instead of the rest of the party.",
	"Attention drawn": "How likely enemies are to pick them when switching targets. Lower is safer.",
	"Interrupt chance": "Chance to stop an enemy spell before it is cast (once every 8 sec), on top of interrupt abilities.",
	"Gear bonus": "How much their equipped items add to their damage (healing for Thyeste), for their level and role.",
	"Average item level": "Average level of their equipped items. Gear falls behind as they level up.",
	"Power": "Overall strength used for recommended power: grade x stats, plus talents, abilities, traits and affixes.",
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
	card.custom_minimum_size.x = 370
	var cv := Style.vbox(4)
	card.add_child(cv)
	cv.add_child(Style.label(m["name"], 26, Style.class_color(cls), true))
	if is_p:
		cv.add_child(Style.label("Level %d %s Priest · guild leader" % [Game.level(), ClassData.RACES.get(m["race"], "")], 14, Style.C["muted"]))
	else:
		var sp: Dictionary = ClassData.SPECS[m["spec"]]
		cv.add_child(Style.label("Level %d %s %s %s" % [Game.level(), ClassData.RACES.get(m["race"], ""), sp["name"], ClassData.class_name_of(cls)], 14, Style.C["muted"]))
	var v := Style.vbox(3)
	var sc := Style.scroll(v)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cv.add_child(sc)
	for row in _attributes(m) + (_priest_stats(m) if is_p else _member_stats(m)):
		if row.size() == 1:
			var sec := Style.label(row[0], 16, Style.C["gold"], true)
			v.add_child(sec)
		else:
			v.add_child(_stat_row(row[0], row[1], row[2] if row.size() > 2 else STAT_HELP.get(row[0], "")))
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
		mv.add_child(Style.label("Abilities", 18, Style.C["gold"], true))
		mv.add_child(_abilities(m))
		mv.add_child(Style.label("Grade", 18, Style.C["gold"], true))
		mv.add_child(_wrap(Style.rich(MemberText.grade_bb(m), 13)))
		mv.add_child(Style.label("Traits & affixes", 18, Style.C["gold"], true))
		mv.add_child(_wrap(Style.rich(MemberText.traits_bb(m), 13)))
		mv.add_child(Style.label("Utilities", 18, Style.C["gold"], true))
		mv.add_child(_wrap(Style.rich(MemberText.utils_bb(m["spec"]), 13)))
		mv.add_child(Style.label("All effects (talents, traits, affixes, grade)", 18, Style.C["gold"], true))
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


## The five attributes, like WoW's character pane: total, with what gear and talents add in the tooltip.
## Rows are [name, value, help]; a one-element row is a section title.
func _attributes(m: Dictionary) -> Array:
	var cls := Game.member_class(m)
	var lvl := Game.level()
	var st := Game.member_stats(m)
	var gear := Stats.gear_stats(m["gear"])
	var base := Stats.base(cls, lvl)
	var apf: Array = Stats.AP_FROM.get(cls, [1, 0])
	var caster := Game.member_kind(m) in ["spell", "priest"]
	var help := {
		"str": ("Raises Attack Power by %d per point." % apf[0] if apf[0] > 0 else "No use to them.") + \
			(" Casters don't use Attack Power." if caster else ""),
		"agi": "Raises critical strike chance by 1%% per %.1f Agility, dodge, and armor (2 per point)." % Stats.agi_per_crit(lvl, cls) + \
			(" Raises Attack Power by %d per point." % apf[1] if apf[1] > 0 else ""),
		"sta": STAT_HELP["Stamina"],
		"int": "Raises spell critical strike chance by 1%% per %.1f Intellect." % Stats.int_per_crit(lvl) + \
			(" Raises maximum mana." if Game.is_priest(m) else ""),
		"spi": STAT_HELP["Spirit"],
	}
	var rows := [["Attributes"]]
	for k in Stats.PRIMARY:
		var from_gear: float = gear.get(k, 0.0)
		var detail := "Base %d, gear +%d" % [int(base[k]), int(from_gear)]
		var pct: float = Game.member_mods(m).get(k + "%", 0.0)
		if pct != 0.0:
			detail += ", talents and traits %+d%%" % int(pct)
		rows.append([Stats.NAMES[k], "%d" % int(st[k]), "%s\n%s." % [help[k], detail]])
	return rows


func _priest_stats(m: Dictionary) -> Array:
	var lvl := Game.level()
	var spec := Game.priest_combat_spec({})
	var st := Game.member_stats(m)
	var tal: Dictionary = m["talents"]
	var mana: float = spec["max_mana"] * (1.0 + Talents.value(tal, "mental_strength") / 100.0)
	var keep := 0.15 + Talents.value(tal, "meditation") / 100.0
	var heal_bonus: float = Talents.value(tal, "spiritual_healing")
	var instant_bonus: float = Talents.value(tal, "twin_disciplines")
	return [
		["Spell"],
		["Healing power", "%d" % int(spec["heal_power"]), STAT_HELP["Healing power"] + "\n\n%s: %s" % [Spells.display_name("heal", lvl),
			RegEx.create_from_string("\\[[^\\]]*\\]").sub(CombatEngine.spell_text("heal", lvl, spec["heal_power"], 1.0, tal), "", true)]],
		["Healing", "+%d" % int(st["heal"]), "Healing from gear. It adds to your healing power."],
		["Spell Damage", "+%d" % int(st["sp"]),
			"Spell Damage from gear. It adds to your healing power like Healing does."],
		["Healing bonus", ("+%d%%, instants +%d%% more" % [int(round(heal_bonus)), int(round(instant_bonus))]) if instant_bonus > 0.0 else "+%d%%" % int(round(heal_bonus))],
		["Spell critical strike", "%.1f%%" % (spec["crit"] * 100.0 + Talents.value(tal, "holy_specialization"))],
		["Mana", "%d" % int(mana)],
		["Mana regeneration", "%.1f / sec (%.1f while casting)" % [spec["regen"], spec["regen"] * keep]],
		["Defense"],
		["Health", "%d" % int(spec["max_hp"])],
		_armor_row(st, lvl),
		["Dodge", "%.1f%%" % st["dodge"], "Chance to dodge an enemy's melee swing entirely. From Agility and Defense."],
		["Overall"],
		["Gear bonus", "+%d%%" % int(round(Game.gear_bonus(m) * 100.0))],
		["Average item level", _avg_ilvl(m)],
		["Talent points", "%d spent, %d free" % [Talents.spent(tal), Game.talent_points_free()]],
		["Power", "%d" % int(round(100.0 * Game.member_power(m)))],
	]


func _member_stats(m: Dictionary) -> Array:
	var lvl := Game.level()
	var spec := Game.member_combat_spec(m, {})
	var st := Game.member_stats(m)
	var mods: Dictionary = spec["mods"]
	var caster := Game.member_kind(m) == "spell"
	var crit: float = spec["crit"] + mods.get("crit", 0.0)
	var crit_mult: float = 2.0 + mods.get("crit_dmg", 0.0) / 100.0
	var haste: float = mods.get("haste", 0.0)
	var dps: float = spec["dps"] * Balance.scale(lvl) * (1.0 + crit / 100.0 * (crit_mult - 1.0)) * (1.0 + haste / 100.0)
	var rows := [["Offense"]]
	if caster:
		rows.append(["Spell Damage", "+%d" % int(st["sp"]),
			"Raises their spells' damage by 1%% per %.1f Spell Damage at this level (x%.2f now)." % [Stats.spell_power_ref(lvl) / 100.0, st["offense"]]])
		rows.append(["Spell critical strike", "%.1f%%" % crit,
			"Chance for a spell to deal double damage. From Intellect, gear, talents and traits."])
	else:
		rows.append(["Attack Power", "%d" % int(st["attack_power"]),
			"Raises their physical damage: x%.2f now, against %d Attack Power without gear." % [st["offense"], int(st["attack_power_base"])]])
		rows.append(["Critical strike", "%.1f%%" % crit,
			"Chance for an attack to deal double damage. From Agility, gear, talents and traits."])
	rows.append(["Critical damage", "x%.2f" % crit_mult])
	rows.append(["Attack speed", "+%d%%" % int(haste)])
	rows.append(["Damage per second", "%d" % int(dps)])
	rows.append(["Defense"])
	rows.append(["Health", "%d" % int(spec["max_hp"])])
	rows.append(_armor_row(st, lvl))
	if st.get("def", 0.0) > 0.0:
		rows.append(["Defense", "+%d" % int(st["def"]), "Raises dodge by 0.04% per point."])
	rows.append(["Dodge", "%.1f%%" % (spec["dodge"] + mods.get("dodge", 0.0)),
		"Chance to dodge an enemy's melee swing entirely. From Agility, Defense, talents and traits."])
	rows.append(["Damage taken", "%d%%" % int(round(spec["mit"] * 100.0))])
	if spec["role"] == "tank":
		rows.append(["Threat hold", "%d%%" % int(round(spec["aggro"] * 100.0))])
	else:
		rows.append(["Attention drawn", "%d%%" % int(round(clampf(100.0 - mods.get("threat", 0.0), 20.0, 200.0)))])
	rows.append(["Overall"])
	rows.append(["Grade", "%s  (x%.2f)" % [Tiers.name_of(m["tier"]), Tiers.power(m["tier"])]])
	rows.append(["Role", Style.role_label(spec["role"])])
	if mods.get("interrupt", 0.0) > 0.0:
		rows.append(["Interrupt chance", "%d%%" % int(mods["interrupt"])])
	rows.append(["Gear bonus", "+%d%%" % int(round(Game.gear_bonus(m) * 100.0))])
	rows.append(["Average item level", _avg_ilvl(m)])
	rows.append(["Talent points", "%d spent, %d free" % [SpecTalents.spent(m.get("talents", {})), Game.member_talent_points_free(m)]])
	rows.append(["Power", "%d" % int(round(100.0 * Game.member_power(m)))])
	return rows


func _armor_row(st: Dictionary, lvl: int) -> Array:
	return ["Armor", "%d" % int(st["armor"]), "Reduces physical damage taken by %.1f%% against enemies of your level. From gear and Agility." \
		% (st["armor_reduction"] * 100.0)]


## A guildmate's abilities, with what each does after their talents.
func _abilities(m: Dictionary) -> Control:
	var v := Style.vbox(6)
	var list := Game.member_abilities(m)
	if list.is_empty():
		v.add_child(Style.label("None yet: abilities come from talents (from level 10).", 13, Style.C["dim"]))
		return v
	for a in list:
		var h := Style.hbox(8)
		var ic := SpellIcon.new(a["name"], WowIcons.guild_ability(a["id"]))
		ic.tint = Style.class_color(m["class"])
		ic.custom_minimum_size = Vector2(32, 32)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(ic)
		var tag := "  [color=#%s](grade %s)[/color]" % [Tiers.color_of(Tiers.A if a["grade"] == "A" else Tiers.S).to_html(false), a["grade"]] if a.has("grade") else ""
		var t := _wrap(Style.rich("[b]%s[/b]%s\n[color=#c09f86]%s[/color]" % [a["name"], tag, SpecTalents.ability_text(a)], 13))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		v.add_child(h)
	return v


func _avg_ilvl(m: Dictionary) -> String:
	var total := 0
	for slot in m["gear"]:
		total += m["gear"][slot]["ilvl"]
	return "%d" % (total / m["gear"].size()) if not m["gear"].is_empty() else "—"


## A stat line; hovering the name explains the stat.
func _stat_row(stat: String, value: String, help: String) -> Control:
	var h := Style.hbox(8)
	var lbl := Style.label(stat, 15, Style.C["muted"])
	if help != "":
		lbl.tooltip_text = help
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
	var cc := CenterContainer.new()
	cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cc.add_child(MemberTalentTree.new().setup(m))
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
	var lv := Style.vbox(8)
	lv.add_child(Style.label("Abilities", 16, Style.C["gold"], true))
	lv.add_child(_abilities(m))
	lv.add_child(Style.label("Effects of these talents", 16, Style.C["gold"], true))
	var mods := {}
	for id in tal:
		var t := SpecTalents.find(spec_id, id)
		if not t.is_empty():
			SpecTalents.add_effects(mods, t[5], tal[id])
	lv.add_child(_wrap(Style.rich(MemberText.mods_bb(mods), 13)))
	var ls := Style.scroll(lv)
	ls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(ls)
	h.add_child(side)
	return h


# ---------------------------------------------------------------- helpers

func _card() -> PanelContainer:
	return Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)


func _wrap(r: RichTextLabel) -> RichTextLabel:
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return r
