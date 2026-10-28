class_name MissionPage
extends VBoxContainer
## The War Table: send guildmates on real-time missions, follow them, and collect the results.

var hub
var _timers: Array = []  # [active dict, ProgressBar, Label, was_done]
var _picked: Array = []
var _odds_label: RichTextLabel
var _send_button: Button


func rebuild() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	Style.clear(self)
	_timers.clear()
	var ms := Game.missions()
	var head := Style.hbox(10)
	var hv := Style.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(Style.title("Guild Missions — The War Table", 26))
	var sub := Style.label("Send guildmates away for 5 to 20 minutes (real time, even with the game closed). Counter the mission's threats with the right abilities, or bring a team 50% stronger than required.", 14, Style.C["muted"])
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(sub)
	head.add_child(hv)
	head.add_child(Style.button("New missions (%s)" % Balance.money(Game.reroll_missions_cost()), Game.reroll_missions))
	add_child(head)
	var body := Style.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(body)
	var left := Style.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(Style.label("Available missions", 18, Style.C["gold"], true))
	var full: bool = ms["active"].size() >= Missions.MAX_ACTIVE
	for i in ms["board"].size():
		left.add_child(_board_card(ms["board"][i], i, full))
	body.add_child(Style.scroll(left))
	var right := Style.vbox(8)
	right.custom_minimum_size.x = 360
	right.add_child(Style.label("Under way  %d/%d" % [ms["active"].size(), Missions.MAX_ACTIVE], 18, Style.C["gold"], true))
	if ms["active"].is_empty():
		right.add_child(Style.label("No guildmates are out on missions.", 14, Style.C["muted"]))
	for i in ms["active"].size():
		right.add_child(_active_card(ms["active"][i], i))
	body.add_child(right)


func _process(_d: float) -> void:
	for t in _timers:
		var a: Dictionary = t[0]
		var left := Missions.time_left(a)
		t[1].value = 1.0 - left / (a["mission"]["minutes"] * 60.0)
		t[2].text = "Back in %s" % Missions.clock(left) if left > 0.0 else "Back! Collect the results."
		if left <= 0.0 and not t[3]:
			rebuild()
			return


func _card() -> PanelContainer:
	return Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)


func _rewards_text(rw: Dictionary) -> String:
	var parts := []
	if rw.has("gold_min"):
		parts.append("%s – %s" % [Balance.money_bb(rw["gold_min"]), Balance.money_bb(rw["gold_max"])])
	if rw.has("xp_min"):
		parts.append("%s – %s XP" % [Balance.big(rw["xp_min"] * Settings.xp_rate()), Balance.big(rw["xp_max"] * Settings.xp_rate())])
	if rw.has("items"):
		var odds := "[color=#0070dd]%d%% rare[/color]" % int(round(rw["rare_chance"] * 100.0))
		if rw.get("epic_chance", 0.0) > 0.0:
			odds += ", [color=#a335ee]%d%% epic[/color]" % int(round(rw["epic_chance"] * 100.0))
		parts.append("%d gear piece%s, item level %d–%d (%s)" % [rw["items"], "" if rw["items"] == 1 else "s", rw["ilvl_min"], rw["ilvl_max"], odds])
	return "[color=#c09f86]Rewards:[/color] " + " · ".join(parts)


func _threats_text(mission: Dictionary, cmap := {}) -> String:
	var lines := []
	for th in mission["threats"]:
		var t: Dictionary = Missions.THREATS[th]
		var by: String = cmap.get(th, "")
		if cmap.is_empty():
			lines.append("[color=#ff9a3c]%s[/color] — %s [color=#8a7262]Countered by %s.[/color]" % [t["name"], t["desc"], t["counter"]])
		elif by != "":
			lines.append("[color=#6ee06e]✓ %s[/color] — countered by %s" % [t["name"], by])
		else:
			lines.append("[color=#ff6a5a]✗ %s[/color] — needs %s" % [t["name"], t["counter"]])
	return "\n".join(lines)


func _board_card(mission: Dictionary, index: int, full: bool) -> Control:
	var p := _card()
	var v := Style.vbox(4)
	p.add_child(v)
	var h := Style.hbox(8)
	var t := Style.label(mission["title"], 19, Style.C["gold"], true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(Style.label("%d min" % mission["minutes"], 16, Style.C["text"], true))
	v.add_child(h)
	v.add_child(Style.label("%s · Level %d · %d guildmate%s · requires power %d" % [mission["place"], mission["level"], mission["slots"],
		"" if mission["slots"] == 1 else "s", mission["required"]], 13, Style.C["muted"]))
	var txt := Style.label(mission["text"], 14)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	var th := Style.rich(_threats_text(mission), 13)
	th.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(th)
	var rw := Style.rich(_rewards_text(mission["rewards"]), 13)
	rw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(rw)
	var foot := Style.hbox(8)
	foot.alignment = BoxContainer.ALIGNMENT_END
	var b := Style.button("Send guildmates", _assign.bind(index), true)
	b.disabled = full
	if full:
		b.text = "The War Table is busy"
	foot.add_child(b)
	v.add_child(foot)
	return p


func _active_card(a: Dictionary, index: int) -> Control:
	var p := _card()
	var v := Style.vbox(4)
	p.add_child(v)
	var mission: Dictionary = a["mission"]
	v.add_child(Style.label(mission["title"], 17, Style.C["gold"], true))
	var names := Game.mission_team(a["members"]).map(func(m): return m["name"])
	var team := Style.label(", ".join(names), 13, Style.C["text"])
	team.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(team)
	var bar := Style.bar(Color("ff9a3c"), 12)
	v.add_child(bar)
	var left := Missions.time_left(a)
	var lbl := Style.label("", 13, Style.C["muted"])
	v.add_child(lbl)
	v.add_child(Style.rich("[color=#c09f86]Success chance:[/color] [color=#%s]%d%%[/color]" % [_chance_color(a["chance"]), int(round(a["chance"] * 100.0))], 13))
	if left <= 0.0:
		v.add_child(Style.button("Collect", _collect.bind(index), true))
	_timers.append([a, bar, lbl, left <= 0.0])
	return p


func _chance_color(c: float) -> String:
	return "6ee06e" if c >= 0.95 else ("ffd86b" if c >= 0.7 else ("ffb040" if c >= 0.45 else "ff5a4a"))


# ---------------------------------------------------------------- assigning

func _assign(index: int) -> void:
	var mission: Dictionary = Game.missions()["board"][index]
	_picked = []
	var v: VBoxContainer = hub.main.open_overlay(720)
	v.add_child(Style.title(mission["title"], 26))
	v.add_child(Style.label("%d min · up to %d guildmate%s · requires power %d" % [mission["minutes"], mission["slots"],
		"" if mission["slots"] == 1 else "s", mission["required"]], 14, Style.C["muted"]))
	var list := Style.vbox(4)
	var free := Game.members().filter(func(m): return not Game.is_busy(m))
	free.sort_custom(func(a, b): return Game.member_power(a) > Game.member_power(b))
	for m in free:
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 34
		var sp: Dictionary = ClassData.SPECS[m["spec"]]
		b.text = "  %s — %s %s · %s · power %d" % [m["name"], sp["name"], ClassData.class_name_of(m["class"]), Tiers.name_of(m["tier"]), int(round(100.0 * Game.member_power(m)))]
		b.add_theme_color_override("font_color", Style.class_color(m["class"]))
		b.toggled.connect(_toggle_pick.bind(m["id"], b, mission))
		list.add_child(b)
	if free.is_empty():
		list.add_child(Style.label("Every guildmate is already away.", 14, Style.C["muted"]))
	var sc := Style.scroll(list)
	sc.custom_minimum_size.y = 220
	v.add_child(sc)
	_odds_label = Style.rich("", 14)
	_odds_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_odds_label)
	var foot := Style.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_child(Style.button("Cancel", hub.main.close_overlay))
	_send_button = Style.button("Send them", _send.bind(index), true)
	foot.add_child(_send_button)
	v.add_child(foot)
	_update_odds(mission)


func _toggle_pick(on: bool, id, b: Button, mission: Dictionary) -> void:
	if on and not (id in _picked):
		if _picked.size() >= mission["slots"]:
			b.set_pressed_no_signal(false)
			Game.toast.emit("This mission takes %d guildmate%s." % [mission["slots"], "" if mission["slots"] == 1 else "s"])
			return
		_picked.append(id)
	elif not on:
		_picked.erase(id)
	_update_odds(mission)


func _update_odds(mission: Dictionary) -> void:
	var o := Game.mission_odds(mission, _picked)
	var countered := 0
	for th in o["counters"]:
		if o["counters"][th] != "":
			countered += 1
	var s := _threats_text(mission, o["counters"])
	s += "\n\n[color=#c09f86]Team power:[/color] %d%% of the requirement   [color=#c09f86]Counters:[/color] %d/%d (+%d%%)   [color=#c09f86]Total:[/color] %d%% (100%% chance at 150%%)" % [
		int(round(o["ratio"] * 100.0)), countered, mission["threats"].size(), int(round(o["bonus"] * 100.0)), int(round(o["effective"] * 100.0))]
	s += "\n[font_size=20][color=#c09f86]Success chance:[/color] [color=#%s]%d%%[/color][/font_size]" % [_chance_color(o["chance"]), int(round(o["chance"] * 100.0))]
	_odds_label.text = s
	_send_button.disabled = _picked.is_empty()


func _send(index: int) -> void:
	Game.start_mission(index, _picked.duplicate())
	hub.main.close_overlay()


func _collect(index: int) -> void:
	var res := Game.collect_mission(index)
	if res.is_empty():
		return
	var v: VBoxContainer = hub.main.open_overlay(560)
	v.add_child(Style.title(("Mission complete: " if res["success"] else "Mission failed: ") + res["title"], 24))
	if res["success"]:
		var gains := []
		if res["xp"] > 0:
			gains.append("%s XP" % Balance.big(res["xp"]))
		if res["gold"] > 0:
			gains.append(Balance.money_bb(res["gold"]))
		if not gains.is_empty():
			v.add_child(Style.rich("[color=#c09f86]Received:[/color] " + ", ".join(gains), 15))
		if res["levels"] > 0:
			v.add_child(Style.label("You reached level %d!" % Game.level(), 20, Style.C["gold"], true))
		for it in res["items"]:
			var bw := Game.best_wearer(it)
			var note := ("[color=#6ee06e]Upgrade for %s[/color]" % bw[0]["name"]) if bw[0] != null else "[color=#8a7262]Not an upgrade for anyone.[/color]"
			var row := Style.hbox(8)
			var ib := ItemButton.new().setup(it, "", note, true)
			ib.custom_minimum_size = Vector2(300, 26)
			row.add_child(ib)
			row.add_child(Style.rich(note, 13))
			row.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(row)
	else:
		v.add_child(Style.label("Your guildmates come back empty-handed but unharmed. Counter more threats or send a stronger team.", 15, Style.C["muted"]))
		v.get_child(1).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var foot := Style.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_child(Style.button("Close", hub.main.close_overlay, true))
	v.add_child(foot)
