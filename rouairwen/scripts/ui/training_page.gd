class_name TrainingPage
extends VBoxContainer
## Training: raise guildmates one grade at a time, for gold up to A and gold and prestige past it.

var hub


func rebuild() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	Style.clear(self)
	var info := Style.rich(("A grade is how much a guildmate grows. Each one adds the stats their spec fights with, mostly as extra gains " + \
		"every level: Attack Power stats for fighters, Spell Damage and Intellect for casters, Stamina above all for tanks, and Stamina " + \
		"for everyone. [color=#%s]B[/color] also grants a random perk (critical strike or damage), [color=#%s]A[/color] a class spell, " + \
		"[color=#%s]S[/color] a racial spell. Up to A, training costs gold; past A, it also takes [color=#%s]prestige[/color], earned by " + \
		"killing raid bosses.") % [Tiers.color_of(Tiers.B).to_html(false), Tiers.color_of(Tiers.A).to_html(false),
		Tiers.color_of(Tiers.S).to_html(false), Style.C["prestige"].to_html(false)], 14)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	add_child(Style.rich("[color=#c09f86]Gold:[/color] %s    [color=#c09f86]Prestige to spend:[/color] [color=#%s]%d[/color]" % [
		Balance.money_bb(Game.gold()), Style.C["prestige"].to_html(false), Game.prestige()], 15))
	var list := Style.vbox(8)
	var members: Array = Game.members().duplicate()
	members.sort_custom(func(a, b): return a["tier"] > b["tier"])
	for m in members:
		list.add_child(_row(m))
	if members.is_empty():
		list.add_child(Style.label("Recruit guildmates first.", 15, Style.C["muted"]))
	var sc := Style.scroll(list)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(sc)


func _row(m: Dictionary) -> Control:
	var p := Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 10)
	var h := Style.hbox(14)
	p.add_child(h)
	var t: int = m["tier"]
	h.add_child(Style.tier_badge(t, 34))
	var who := Style.vbox(2)
	who.custom_minimum_size.x = 230
	who.add_child(Style.label(m["name"], 18, Style.class_color(m["class"]), true))
	who.add_child(Style.label("%s %s %s" % [ClassData.RACES[m["race"]], ClassData.SPECS[m["spec"]]["name"],
		ClassData.class_name_of(m["class"])], 13, Style.C["muted"]))
	h.add_child(who)
	var mid := Style.vbox(3)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var now := Game.grade_stats(m)
	if Tiers.is_max(t):
		mid.add_child(Style.rich("[color=#%s]%s[/color]: the highest grade. %s at level %d." % [Tiers.color_of(t).to_html(false),
			Tiers.name_of(t), Tiers.stats_text(now), Game.level()], 14))
	else:
		var next := t + 1
		var gain := Game.grade_stats(m, next)
		for k in now:
			gain[k] = gain.get(k, 0.0) - now[k]
		var line := "[color=#%s]%s[/color] → [color=#%s]%s[/color]: %s at level %d" % [Tiers.color_of(t).to_html(false), Tiers.name_of(t),
			Tiers.color_of(next).to_html(false), Tiers.name_of(next), Tiers.stats_text(gain), Game.level()]
		if Tiers.unlock_at(next) != "":
			line += ", and [color=#ffd86b]%s[/color]" % MemberText.unlock_text(m, next)
		mid.add_child(Style.rich(line, 14))
	var perks := []
	for g in [Tiers.B, Tiers.A, Tiers.S]:
		var col := Tiers.color_of(g).to_html(false) if t >= g else "8a7262"
		perks.append("[color=#%s]%s: %s[/color]" % [col, Tiers.name_of(g), MemberText.unlock_text(m, g)])
	var pl := Style.rich("    ".join(perks), 12)
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(pl)
	h.add_child(mid)
	if not Tiers.is_max(t):
		var cost := Balance.money_bb(Tiers.train_gold(Game.level(), t))
		var pr := Tiers.train_prestige(t)
		if pr > 0:
			cost += "\n[color=#%s]%d prestige[/color]" % [Style.C["prestige"].to_html(false), pr]
		var cl := Style.rich("[right]%s[/right]" % cost, 14)
		cl.custom_minimum_size.x = 150
		h.add_child(cl)
		var why := Game.train_block(m)
		var b := Style.button("Train to %s" % Tiers.name_of(t + 1), Game.train.bind(m), why == "")
		b.custom_minimum_size.x = 140
		b.disabled = why != ""
		b.tooltip_text = why
		h.add_child(b)
	return p
