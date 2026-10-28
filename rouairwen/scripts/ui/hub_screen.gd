class_name HubScreen
extends Control
## Orgrimmar: the guild's home. A top bar, a district menu and one page at a time.

const NAV := [
	["guild", "Guild Roster", "Gear and guildmates"],
	["character", "Character Sheet", "Stats & talents"],
	["quests", "Quest Board", "Valley of Strength"],
	["dungeons", "Dungeons", "Cleft of Shadow"],
	["raids", "Raids", "Grommash Hold"],
	["recruit", "Recruitment", "Valley of Honor"],
	["shop", "Supplies", "The Drag"],
	["missions", "Guild Missions", "The War Table"],
	["hall", "Guild Hall", "Upgrades & chronicle"],
	["talents", "Talents & Spells", "Valley of Spirits"],
]

var main
var page := "quests"
var top_bar: PanelContainer
var nav_box: VBoxContainer
var content: MarginContainer
var nav_buttons := {}
var selected_dungeon := ""
var selected_raid := ""
var selected_member = "priest"
var bank_filter := true
var sheet_tab := "stats"


func _ready() -> void:
	add_child(Backdrop.new("orgrimmar"))
	var root := Style.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	top_bar = PanelContainer.new()
	top_bar.add_theme_stylebox_override("panel", Style.box(Color(0.07, 0.025, 0.02, 0.93), Style.C["border"], 0, 0, 8))
	root.add_child(top_bar)
	var body := Style.hbox(10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bm := MarginContainer.new()
	bm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		bm.add_theme_constant_override("margin_" + side, 10)
	bm.add_child(body)
	root.add_child(bm)
	var nav_panel := Style.panel(Color(0.08, 0.03, 0.02, 0.9), Style.C["border"], 2, 8)
	nav_panel.custom_minimum_size.x = 210
	body.add_child(nav_panel)
	nav_box = Style.vbox(6)
	nav_panel.add_child(nav_box)
	var content_panel := Style.panel(Color(0.09, 0.035, 0.025, 0.9), Style.C["border"], 2, 0)
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(content_panel)
	content = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 14)
	content_panel.add_child(content)
	_build_nav()
	Game.changed.connect(refresh)
	Game.leveled.connect(_on_leveled)
	refresh()


func _exit_tree() -> void:
	if Game.changed.is_connected(refresh):
		Game.changed.disconnect(refresh)
	if Game.leveled.is_connected(_on_leveled):
		Game.leveled.disconnect(_on_leveled)


func _on_leveled(lvl: int) -> void:
	main.show_toast("Level %d reached!" % lvl)


func open_page(p: String) -> void:
	page = p
	refresh()


func refresh() -> void:
	if not is_inside_tree():
		return
	_build_top()
	_update_nav()
	Style.clear(content)
	match page:
		"guild":
			var gp := GuildPage.new()
			gp.hub = self
			content.add_child(gp)
			gp.rebuild()
		"quests":
			content.add_child(_quests_page())
		"dungeons":
			content.add_child(_dungeons_page())
		"raids":
			content.add_child(_raids_page())
		"recruit":
			content.add_child(_recruit_page())
		"shop":
			content.add_child(_shop_page())
		"character":
			var cp := CharacterPage.new()
			cp.hub = self
			content.add_child(cp)
			cp.rebuild()
		"missions":
			var mp := MissionPage.new()
			mp.hub = self
			content.add_child(mp)
			mp.rebuild()
		"hall":
			content.add_child(_hall_page())
		"talents":
			var tp := TalentPage.new()
			content.add_child(tp)
			tp.rebuild()


# ---------------------------------------------------------------- top bar & nav

func _build_top() -> void:
	Style.clear(top_bar)
	var h := Style.hbox(14)
	top_bar.add_child(h)
	var em := GuildEmblem.new()
	em.custom_minimum_size = Vector2(52, 52)
	h.add_child(em)
	var v := Style.vbox(2)
	var p := Game.priest()
	var row := Style.hbox(10)
	row.add_child(Style.label("<Lumens>", 22, Style.C["gold"], true))
	row.add_child(Style.label("%s · Level %d %s Priest" % [p["name"], p["level"], ClassData.RACES.get(p["race"], "")], 16, Style.C["text"]))
	v.add_child(row)
	var xpb := Style.bar(Color("8a3ad8"), 12)
	xpb.custom_minimum_size.x = 420
	var need := Game.xp_needed()
	xpb.value = float(p["xp"]) / need if need > 0 else 1.0
	xpb.tooltip_text = "Experience: %d / %d" % [p["xp"], need] if need > 0 else "Maximum level"
	v.add_child(xpb)
	var xl := Style.label(("XP %s / %s" % [Balance.big(p["xp"]), Balance.big(need)]) if need > 0 else "Level 60 — raids are open", 12, Style.C["muted"])
	v.add_child(xl)
	h.add_child(v)
	h.add_child(Style.spacer())
	var pts := Game.talent_points_free()
	if pts > 0:
		var tb := Style.button("%d talent point%s to spend" % [pts, "" if pts == 1 else "s"], open_page.bind("talents"), true)
		h.add_child(tb)
	var right := Style.vbox(2)
	var gold := Style.rich("[right][font_size=20]%s[/font_size][/right]" % Balance.money_bb(Game.gold()), 18)
	gold.custom_minimum_size.x = 200
	right.add_child(gold)
	var hl := Style.label("%s · %d/%d members" % [Balance.HALL_NAMES[Game.hall()], Game.members().size() + 1, Game.MAX_GUILD], 13, Style.C["muted"])
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(hl)
	h.add_child(right)


func _build_nav() -> void:
	var t := Style.label("Orgrimmar", 20, Style.C["gold"], true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav_box.add_child(t)
	nav_box.add_child(HSeparator.new())
	for n in NAV:
		var b := Button.new()
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 44)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(open_page.bind(n[0]))
		var v := Style.vbox(0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 12
		v.offset_top = 3
		var l1 := Style.label(n[1], 16, Style.C["text"])
		l1.add_theme_font_override("font", Style.bold_font())
		l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l2 := Style.label(n[2], 12, Style.C["muted"])
		l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l1)
		v.add_child(l2)
		b.add_child(v)
		b.set_meta("sub", l2)
		nav_box.add_child(b)
		nav_buttons[n[0]] = b
	nav_box.add_child(Style.spacer())
	nav_box.add_child(Style.button("Options", _options))
	nav_box.add_child(Style.button("Save & Exit", _save_exit))


func _update_nav() -> void:
	for id in nav_buttons:
		var b: Button = nav_buttons[id]
		b.button_pressed = id == page
		var sub: Label = b.get_meta("sub")
		var locked: bool = (id == "dungeons" and Game.level() < 10) or (id == "raids" and Game.level() < Balance.MAX_LEVEL)
		b.modulate = Color(1, 1, 1, 0.55) if locked else Color.WHITE
		if id == "dungeons" and locked:
			sub.text = "Opens at level 10"
		elif id == "raids" and locked:
			sub.text = "Opens at level 60"
		elif id == "talents" and Game.talent_points_free() > 0:
			sub.text = "%d point(s) to spend!" % Game.talent_points_free()
		else:
			for n in NAV:
				if n[0] == id:
					sub.text = n[2]


func _options() -> void:
	main.open_options()


func _save_exit() -> void:
	Game.save()
	main.show_title()


# ---------------------------------------------------------------- page helpers

func _page(title: String, subtitle: String) -> VBoxContainer:
	var v := Style.vbox(10)
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := Style.hbox(10)
	var hv := Style.vbox(2)
	hv.add_child(Style.title(title, 26))
	var sub := Style.label(subtitle, 14, Style.C["muted"])
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hv.add_child(sub)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	head.name = "Head"
	v.add_child(head)
	return v


func _card() -> PanelContainer:
	return Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)


func _power_text(have: int, need: int) -> String:
	var col := "6ee06e" if have >= need else ("ffb040" if have >= need * 0.88 else "ff5a4a")
	return "[color=#%s]%d[/color] / %d" % [col, have, need]


# ---------------------------------------------------------------- quests

func _quests_page() -> Control:
	var v := _page("Quest Board", "Quests send you and two guildmates into a zone of your level. Each one holds 1 to 3 fights. There is always one easy quest, below your own power.")
	var rr := Style.button("New quests (%s)" % Balance.money(Game.reroll_quest_cost()), Game.reroll_quests)
	v.get_node("Head").add_child(rr)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for q in Game.data["quests"]:
		grid.add_child(_quest_card(q))
	v.add_child(Style.scroll(grid))
	return v


func _quest_card(q: Dictionary) -> Control:
	var p := _card()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Style.vbox(5)
	p.add_child(v)
	var h := Style.hbox(8)
	var t := Style.label(q["title"], 19, Style.C["gold"], true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(t)
	var kcol: Color = {"easy": Color("6ee06e"), "normal": Color("e6e6e6"), "hard": Color("ffa040"), "elite": Color("c45cff")}[q["kind"]]
	h.add_child(Style.label(q["kind_label"], 14, kcol, true))
	v.add_child(h)
	v.add_child(Style.label("%s · Level %d · given by %s" % [q["place"], q["level"], q["giver"]], 13, Style.C["muted"]))
	var txt := Style.label(q["text"], 14, Style.C["text"])
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size.x = 340
	v.add_child(txt)
	var fights: Array = q["fights"]
	var flist := []
	for f in fights:
		flist.append(("[color=#ffb040]%s[/color]" % f["label"]) if f["type"] == "elite" else f["label"])
	v.add_child(Style.rich("[color=#c09f86]%d fight%s:[/color] %s" % [fights.size(), "" if fights.size() == 1 else "s", ", ".join(flist)], 13))
	var rw: Dictionary = q["rewards"]
	v.add_child(Style.rich("[color=#c09f86]Rewards:[/color] %s XP and %s – %s" % [Balance.big(rw["xp"]), Balance.money_bb(rw["gold_min"]), Balance.money_bb(rw["gold_max"])], 13))
	var n_txt := "%d" % rw["items_min"] if rw["items_min"] == rw["items_max"] else "%d–%d" % [rw["items_min"], rw["items_max"]]
	var odds := "[color=#0070dd]%d%% rare[/color]" % int(round(rw["rare_chance"] * 100.0))
	if rw["epic_chance"] > 0.0:
		odds += ", [color=#a335ee]%d%% epic[/color]" % int(round(rw["epic_chance"] * 100.0))
	v.add_child(Style.rich("[color=#c09f86]Gear:[/color] %s random piece%s, item level %d–%d (%s each)" % [n_txt,
		"" if rw["items_max"] == 1 else "s", rw["ilvl_min"], rw["ilvl_max"], odds], 13))
	var g := Activities.guarantee_bb(q)
	if g != "":
		v.add_child(Style.rich(g + " [color=#8a7262](one of the pieces)[/color]", 13))
	var foot := Style.hbox(8)
	var rec := Game.recommended_power(q)
	var rec_txt := "[color=#c09f86]Recommended power:[/color] %d" % rec
	if Game.is_easy_quest(q):
		rec_txt += " [color=#6ee06e](below %s's %d)[/color]" % [Game.priest()["name"], int(round(100.0 * Game.member_power(Game.priest())))]
	foot.add_child(Style.rich(rec_txt, 13))
	foot.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(Style.button("Accept", open_party.bind(q), true))
	v.add_child(foot)
	return p


# ---------------------------------------------------------------- dungeons

func _dungeons_page() -> Control:
	var v := _page("Dungeons", "Five-player expeditions (you + four guildmates) from level 10. Bosses drop named rare loot; the deepest dungeons drop Tier 0 set pieces. Clearing a run guarantees one piece for a random role.")
	if Game.level() < 10:
		v.add_child(Style.label("The war council will not send you below the earth until you reach level 10.", 16, Style.C["accent"]))
		return v
	var h := Style.hbox(12)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var list := Style.vbox(4)
	var sc := Style.scroll(list)
	sc.custom_minimum_size.x = 290
	sc.size_flags_horizontal = Control.SIZE_FILL
	h.add_child(sc)
	if selected_dungeon == "" or not Game.dungeon_unlocked(Dungeons.by_id(selected_dungeon)):
		for d in Dungeons.LIST:
			if Game.dungeon_unlocked(d) and Game.level() <= d["max"] + 2:
				selected_dungeon = d["id"]
	for d in Dungeons.LIST:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = d["id"] == selected_dungeon
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		var ok := Game.dungeon_unlocked(d)
		b.text = "%s  (%d-%d)" % [d["name"], d["min"], d["max"]]
		b.disabled = not ok
		var clears: int = Game.data["dungeon_clears"].get(d["id"], 0)
		if clears > 0:
			b.text += "  ✓%d" % clears
		b.pressed.connect(_select_dungeon.bind(d["id"]))
		list.add_child(b)
	var d := Dungeons.by_id(selected_dungeon)
	if d.is_empty():
		return v
	var det := _card()
	det.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	det.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(det)
	var dv := Style.vbox(6)
	det.add_child(Style.scroll(dv))
	dv.add_child(Style.title(d["name"], 24))
	var cl := clampi(Game.level(), d["min"], d["max"])
	dv.add_child(Style.label("Levels %d-%d · fights at level %d · item level %d" % [d["min"], d["max"], cl, d["ilvl"]], 14, Style.C["muted"]))
	var act_preview := {"level": cl, "diff": d["diff"]}
	dv.add_child(Style.rich("[color=#c09f86]Recommended power:[/color] %d" % Game.recommended_power(act_preview), 14))
	if Game.level() > d["max"] + 2:
		dv.add_child(Style.label("You have outgrown this dungeon: experience is reduced.", 13, Style.C["accent"]))
	dv.add_child(HSeparator.new())
	for b in d["bosses"]:
		var bh := Style.hbox(8)
		bh.add_child(Style.label(("☠ " if b.get("final", false) else "• ") + b["name"], 16, Style.C["gold"] if b.get("final", false) else Style.C["text"]))
		dv.add_child(bh)
		var loot := HFlowContainer.new()
		loot.add_theme_constant_override("h_separation", 6)
		loot.add_theme_constant_override("v_separation", 4)
		for e in b.get("loot", []):
			var it := Items.from_entry(e, d["ilvl"], "rare")
			var ib := ItemButton.new().setup(it, "", "", true)
			ib.custom_minimum_size = Vector2(220, 24)
			loot.add_child(ib)
		if b.has("tier"):
			loot.add_child(Style.label("+ Tier 0 set pieces", 13, Color("ffd100")))
		dv.add_child(loot)
	var enter := Style.button("Enter %s" % d["name"], _enter_dungeon.bind(d), true)
	enter.custom_minimum_size.y = 42
	dv.add_child(enter)
	return v


func _select_dungeon(id: String) -> void:
	selected_dungeon = id
	refresh()


func _enter_dungeon(d: Dictionary) -> void:
	open_party(Activities.make_dungeon(d, Game.level(), Game.rng))


# ---------------------------------------------------------------- raids

func _raids_page() -> Control:
	var v := _page("Raids", "Ten-player raids (you + nine guildmates) at level 60, built for a team of grade A+ in decent gear. Progress is saved after each boss; finishing a run guarantees one epic piece for a random role.")
	if Game.level() < Balance.MAX_LEVEL:
		v.add_child(Style.label("Thrall's war council only gathers raids for champions of level 60.", 16, Style.C["accent"]))
		return v
	var h := Style.hbox(12)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var list := Style.vbox(4)
	list.custom_minimum_size.x = 290
	h.add_child(list)
	if selected_raid == "":
		selected_raid = Raids.LIST[0]["id"]
	for r in Raids.LIST:
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = r["id"] == selected_raid
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		var lock := Game.raid_unlocked(r)
		b.text = r["name"] + ("  🔒" if lock != "" else "")
		var clears: int = Game.data["raid_clears"].get(r["id"], 0)
		if clears > 0:
			b.text += "  ✓%d" % clears
		b.pressed.connect(_select_raid.bind(r["id"]))
		list.add_child(b)
	var r := Raids.by_id(selected_raid)
	var det := _card()
	det.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	det.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(det)
	var dv := Style.vbox(6)
	det.add_child(Style.scroll(dv))
	dv.add_child(Style.title(r["name"], 24))
	var tier_txt := "" if r["tier"] < 1 else " · Tier %s set pieces" % ["", "1", "2", "2.5", "3"][r["tier"]]
	dv.add_child(Style.label("Item level %d%s" % [r["ilvl"], tier_txt], 14, Style.C["muted"]))
	dv.add_child(Style.rich("[color=#c09f86]Recommended power:[/color] %d" % Game.recommended_power({"level": 60, "diff": r["diff"]}), 14))
	var lock := Game.raid_unlocked(r)
	if lock != "":
		dv.add_child(Style.label(lock, 15, Style.C["bad"]))
	var killed := Game.raid_killed(r["id"])
	dv.add_child(HSeparator.new())
	for i in r["bosses"].size():
		var b: Dictionary = r["bosses"][i]
		var done: bool = i in killed
		dv.add_child(Style.label(("✓ " if done else ("☠ " if b.get("final", false) else "• ")) + b["name"], 16,
			Style.C["good"] if done else (Style.C["gold"] if b.get("final", false) else Style.C["text"])))
		var loot := HFlowContainer.new()
		loot.add_theme_constant_override("h_separation", 6)
		loot.add_theme_constant_override("v_separation", 4)
		for e in b.get("loot", []).slice(0, 6):
			var ib := ItemButton.new().setup(Items.from_entry(e, r["ilvl"] + i, "epic"), "", "", true)
			ib.custom_minimum_size = Vector2(230, 24)
			loot.add_child(ib)
		dv.add_child(loot)
	if lock == "":
		var row := Style.hbox(8)
		var label := "Continue raid (%d/%d)" % [killed.size(), r["bosses"].size()] if not killed.is_empty() else "Enter %s" % r["name"]
		var enter := Style.button(label, _enter_raid.bind(r), true)
		enter.custom_minimum_size.y = 42
		enter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(enter)
		if not killed.is_empty():
			row.add_child(Style.button("Reset progress", _reset_raid.bind(r["id"])))
		dv.add_child(row)
	return v


func _select_raid(id: String) -> void:
	selected_raid = id
	refresh()


func _enter_raid(r: Dictionary) -> void:
	open_party(Activities.make_raid(r, Game.raid_killed(r["id"]), Game.rng))


func _reset_raid(id: String) -> void:
	main.confirm("Reset your progress in %s? Killed bosses will come back." % Raids.by_id(id)["name"], _do_reset_raid.bind(id))


func _do_reset_raid(id: String) -> void:
	Game.data["raid_progress"].erase(id)
	Game.save()
	refresh()


# ---------------------------------------------------------------- recruitment

func _recruit_page() -> Control:
	var v := _page("Recruitment", "Adventurers answer the guild's notice in the Valley of Honor. A better guild hall attracts better grades, from F up to SSS+.")
	var head: Control = v.get_node("Head")
	head.add_child(Style.button("Post a new notice (%s)" % Balance.money(Balance.recruit_refresh_cost(Game.level())), Game.refresh_recruits.bind(true)))
	v.add_child(Style.rich("[color=#c09f86]Guild:[/color] %d / %d members    [color=#c09f86]Hall:[/color] %s    %s" % [
		Game.members().size() + 1, Game.MAX_GUILD, Balance.HALL_NAMES[Game.hall()], _odds_text(Game.hall())], 14))
	var row := Style.hbox(12)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in Game.data["recruits"].size():
		row.add_child(_candidate_card(Game.data["recruits"][i], i))
	if Game.data["recruits"].is_empty():
		row.add_child(Style.label("No one has answered the notice yet. Post a new one.", 15, Style.C["muted"]))
	v.add_child(row)
	return v


func _odds_text(hall: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hall * 31
	var n := 4000
	var a := 0
	var s := 0
	var best := 0
	for i in n:
		var t := Tiers.roll(hall, rng)
		if t >= 10:
			a += 1
		if t >= 12:
			s += 1
		best = maxi(best, t)
	return "[color=#c09f86]Typical grade:[/color] [color=#%s]%s[/color]   [color=#c09f86]A or better:[/color] %.1f%%   [color=#c09f86]S or better:[/color] %.1f%%   [color=#c09f86]Best possible:[/color] [color=#%s]%s[/color]" % [
		Tiers.color_of(int(round(Tiers.mean_for_hall(hall)))).to_html(false), Tiers.name_of(int(round(Tiers.mean_for_hall(hall)))),
		100.0 * a / n, 100.0 * s / n, Tiers.color_of(Tiers.cap_for_hall(hall)).to_html(false), Tiers.name_of(Tiers.cap_for_hall(hall))]


func _candidate_card(c: Dictionary, index: int) -> Control:
	var p := _card()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Style.vbox(6)
	p.add_child(v)
	var h := Style.hbox(8)
	var nv := Style.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(Style.label(c["name"], 22, Style.class_color(c["class"]), true))
	var sp: Dictionary = ClassData.SPECS[c["spec"]]
	nv.add_child(Style.label("%s %s %s" % [ClassData.RACES[c["race"]], sp["name"], ClassData.class_name_of(c["class"])], 14, Style.C["muted"]))
	h.add_child(nv)
	h.add_child(Style.tier_badge(c["tier"], 40))
	v.add_child(h)
	v.add_child(Style.rich("[color=#c09f86]Role:[/color] %s    [color=#c09f86]Power:[/color] %d" % [Style.role_label(sp["role"]), int(100 * Game.member_power(c))], 14))
	var tr := Style.rich(MemberText.traits_bb(c), 13)
	tr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tr.custom_minimum_size.x = 250
	v.add_child(tr)
	var ur := Style.rich(MemberText.utils_bb(c["spec"]), 12)
	ur.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ur.custom_minimum_size.x = 250
	v.add_child(ur)
	for slot in c["gear"]:
		var ib := ItemButton.new().setup(c["gear"][slot], slot, "", true)
		ib.custom_minimum_size.y = 24
		v.add_child(ib)
	v.add_child(Style.spacer())
	v.add_child(Style.rich("[color=#c09f86]Signing bonus:[/color] %s" % Balance.money_bb(c["cost"]), 15))
	var hire := Style.button("Hire %s" % c["name"], Game.hire.bind(index), true)
	hire.disabled = Game.guild_full()
	if Game.guild_full():
		hire.text = "Guild is full"
	v.add_child(hire)
	return p


# ---------------------------------------------------------------- shop

func _shop_page() -> Control:
	var v := _page("Supplies on the Drag", "Potions are used in combat; elixirs and food are consumed when the party sets out (one of each, if ticked).")
	var list := Style.vbox(8)
	for cat in ShopData.ORDER:
		list.add_child(_shop_row(cat))
	v.add_child(Style.scroll(list))
	return v


func _shop_row(cat: String) -> Control:
	var data: Dictionary = ShopData.CATEGORIES[cat]
	var p := _card()
	var h := Style.hbox(12)
	p.add_child(h)
	var rank := ShopData.best_rank(cat, Game.level())
	var ic := SpellIcon.new(data["icon"], WowIcons.consumable(ShopData.rank_name(cat, maxi(rank, 0))))
	ic.custom_minimum_size = Vector2(52, 52)
	h.add_child(ic)
	var v := Style.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rname := ShopData.rank_name(cat, rank) if rank >= 0 else "Nothing yet"
	var head := Style.hbox(10)
	head.add_child(Style.label(rname, 18, Style.C["gold"], true))
	head.add_child(Style.label(data["name"], 13, Style.C["muted"]))
	v.add_child(head)
	var effect := ""
	if rank >= 0:
		var val := ShopData.rank_value(cat, rank)
		match cat:
			"mana_potion":
				effect = "Restores %d mana." % int(val * Balance.scale(ShopData.rank_level(cat, rank)))
			"healing_potion":
				effect = "Restores %d health." % int(val * Balance.scale(ShopData.rank_level(cat, rank)))
			_:
				effect = "+%d%%." % int(val)
	var d := Style.label("%s %s" % [data["desc"], effect], 13, Style.C["text"])
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	var next_txt := ""
	var ranks: Array = data["ranks"]
	if rank + 1 < ranks.size():
		next_txt = "Next: %s at level %d" % [ranks[rank + 1][0], ranks[rank + 1][1]]
	v.add_child(Style.label("In the guild bank: %d    %s" % [Game.stock(cat), next_txt], 12, Style.C["muted"]))
	h.add_child(v)
	var use := CheckBox.new()
	use.text = "Use"
	use.button_pressed = Game.data["use"].get(cat, true)
	use.toggled.connect(_toggle_use.bind(cat))
	use.focus_mode = Control.FOCUS_NONE
	h.add_child(use)
	if rank >= 0:
		var price := ShopData.price(cat, rank)
		var pv := Style.vbox(4)
		pv.add_child(Style.rich("[right]%s each[/right]" % Balance.money_bb(price), 14))
		var bh := Style.hbox(6)
		bh.add_child(Style.button("Buy 1", Game.buy.bind(cat, 1)))
		bh.add_child(Style.button("Buy 5", Game.buy.bind(cat, 5)))
		pv.add_child(bh)
		pv.custom_minimum_size.x = 180
		h.add_child(pv)
	return p


func _toggle_use(on: bool, cat: String) -> void:
	Game.data["use"][cat] = on
	Game.save()


# ---------------------------------------------------------------- hall

func _hall_page() -> Control:
	var v := _page("Guild Hall", "A grander hall draws stronger adventurers to your recruitment notices.")
	var h := Style.hbox(12)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var cur := _card()
	cur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(cur)
	var cv := Style.vbox(8)
	cur.add_child(cv)
	cv.add_child(Style.label("Current hall (level %d / %d)" % [Game.hall(), Balance.HALL_MAX], 14, Style.C["muted"]))
	cv.add_child(Style.title(Balance.HALL_NAMES[Game.hall()], 28))
	var od := Style.rich(_odds_text(Game.hall()).replace("   ", "\n"), 15)
	cv.add_child(od)
	cv.add_child(HSeparator.new())
	if Game.hall() < Balance.HALL_MAX:
		var nxt := Game.hall() + 1
		cv.add_child(Style.label("Next: %s" % Balance.HALL_NAMES[nxt], 20, Style.C["gold"], true))
		cv.add_child(Style.rich(_odds_text(nxt).replace("   ", "\n"), 15))
		cv.add_child(Style.rich("[color=#c09f86]Cost:[/color] %s    [color=#c09f86]Requires level:[/color] %d" % [Balance.money_bb(Balance.hall_cost(nxt)), Balance.HALL_LEVEL_REQ[nxt]], 15))
		var why := Game.can_upgrade_hall()
		var b := Style.button("Upgrade the hall" if why == "" else why, Game.upgrade_hall, true)
		b.disabled = why != ""
		b.custom_minimum_size.y = 42
		cv.add_child(b)
	else:
		cv.add_child(Style.label("The Citadel of Dawn is complete. The finest champions of Azeroth seek your banner.", 16, Style.C["gold"]))
	var chron := _card()
	chron.custom_minimum_size.x = 380
	h.add_child(chron)
	var chv := Style.vbox(6)
	chron.add_child(chv)
	chv.add_child(Style.title("Guild Chronicle", 20))
	var st: Dictionary = Game.data["stats"]
	chv.add_child(Style.rich("[color=#c09f86]Time played:[/color] %dh %02dm   [color=#c09f86]Fights won:[/color] %d   [color=#c09f86]Wipes:[/color] %d\n[color=#c09f86]Quests:[/color] %d   [color=#c09f86]Dungeons:[/color] %d   [color=#c09f86]Raids:[/color] %d   [color=#c09f86]Best grade:[/color] [color=#%s]%s[/color]" % [
		st["playtime"] / 3600, (st["playtime"] / 60) % 60, st["fights"], st["wipes"], st["quests"], st["dungeons"], st["raids"],
		Tiers.color_of(st["best_tier"]).to_html(false), Tiers.name_of(st["best_tier"])], 13))
	chv.add_child(HSeparator.new())
	var lg := Style.vbox(4)
	for line in Game.data["log"]:
		var l := Style.label("• " + line, 13, Style.C["text"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lg.add_child(l)
	chv.add_child(Style.scroll(lg))
	return v


# ---------------------------------------------------------------- party selection

func open_party(act: Dictionary) -> void:
	var dlg := PartyDialog.new()
	dlg.setup(main, act)
