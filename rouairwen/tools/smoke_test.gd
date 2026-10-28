extends Node
## End-to-end smoke test, driven from main.gd when the game runs with "-- --smoke".
## Plays through every screen with a bot healer on a throwaway save; "--shots" also saves screenshots.

var main
var shots := false
var shot_dir := ""
var failures := 0
## Guildmate ability lines in the combat log since the counter was last reset.
var guild_lines := 0


func run() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	shot_dir = ProjectSettings.globalize_path("user://smoke_shots")
	DirAccess.make_dir_recursive_absolute(shot_dir)
	Game.save_path = "user://smoke_save.txt"
	# Plays at normal experience whatever the options say (not saved, so the player's choice stays).
	Settings.xp_boost = false
	# A fixed seed makes every run play the same fights, so a failure is reproducible.
	Game.rng.seed = 20261027
	await _frames(5)
	await _shot("01_title")
	Game.new_game()
	Settings.xp_boost = true
	_check(Game._grant(1, 0, [])["xp"] == Settings.XP_BOOST, "the testing option multiplies experience")
	Settings.xp_boost = false
	Game.data["priest"]["xp"] = 0
	_check_coefficients()
	_check(Game.members().all(func(m): return m["traits"].size() == 2 and m["affixes"].is_empty()), "founders have 2 traits and no affixes")
	_check(Game.data["recruits"].all(func(c): return c["traits"].size() == 2 and c["affixes"].size() <= 2), "recruits have 2 traits and up to 2 affixes")
	_check(UnitFrame.aura_tooltip({"id": "dot_x", "name": "Shadow Word: Pain", "dot": 12.0, "period": 3.0, "remaining": 9.0,
		"harmful": true, "dispel": "magic", "kind": "magic_dot"}).contains("Dispel Magic"), "debuff tooltip explains how to remove it")
	var empty_slot := ItemButton.new().setup({}, "neck")
	var frame := UnitFrame.new()
	_check(empty_slot._make_custom_tooltip("") == null and frame._make_custom_tooltip(" ") == null,
		"no tooltip appears when there's nothing to show")
	empty_slot.free()
	frame.free()
	main.show_hub()
	await _frames(3)
	var cap_rng := RandomNumberGenerator.new()
	var rolls := []
	for i in 2000:
		rolls.append(Tiers.roll(10, cap_rng))
	_check(rolls.max() == Tiers.A, "the best guild hall recruits up to grade A, no higher")
	for p in ["quests", "guild", "character", "dungeons", "raids", "prestige", "recruit", "shop", "missions", "hall", "talents"]:
		main.screen.open_page(p)
		await _frames(3)
		if shots:
			# Let the backdrop finish fading in to the new place
			await get_tree().create_timer(0.5).timeout
		await _shot("02_hub_" + p)
	_check(OrgrimmarMap.SCENES.values().all(func(s): return s in Backdrop.SCENE_NAMES), "every place on the map has a backdrop")
	# The map: clicking a place opens its page, and the backdrop moves there
	main.screen.open_page("quests")
	await _frames(2)
	var hub: HubScreen = main.screen
	var spot: Array = hub.map._spots.filter(func(s): return s[0] == "shop")
	if not spot.is_empty():
		var at: Vector2 = hub.map.get_global_rect().position + spot[0][1]
		await _push_mouse(at, true, MOUSE_BUTTON_MASK_LEFT)
		await _push_mouse(at, false, 0)
	_check(hub.page == "shop" and hub.backdrop.scene == "drag", "clicking Supplies on the map opens it in the Drag (%s, %s)" % [hub.page, hub.backdrop.scene])
	main.open_options()
	await _frames(3)
	await _shot("02_options")
	main.close_overlay()
	if "--ui-only" in OS.get_cmdline_user_args():
		await _ui_only()
		return

	# A level-1 quest with the founders
	_check(Game.data["quests"].size() == 6, "quest board holds 6 quests")
	_check(Game.data["quests"].filter(Game.is_easy_quest).size() >= 1, "quest board has an easy quest")
	var q: Dictionary = Game.data["quests"][0]
	main.screen.open_party(q)
	await _frames(3)
	await _shot("03_party")
	main.close_overlay()
	Game.start_run(q, _ids(2))
	main.start_combat()
	await _play_run("04_quest")

	# Jump ahead: level 22, a full guild, gear, talents, supplies
	Game.data["priest"]["level"] = 24
	Game.data["gold"] = 5000000
	Game.data["hall"] = 4
	Game.refresh_recruits(false)
	for i in 3:
		Game.hire(0)
		Game.refresh_recruits(false)
	_check(Game.members().size() == 5, "hired three recruits")
	Game.members()[2]["spec"] = "warrior_protection"
	Game.members()[2]["class"] = "warrior"
	Game.auto_member_talents(Game.members()[2])
	for m in Game.members():
		m["tier"] = maxi(m["tier"], 6)
	Game.refresh_auto_talents()
	_check(Game.members().all(func(m): return SpecTalents.spent(m["talents"]) == SpecTalents.points_at(24)), "guildmates auto-spent their talent points")
	var tm: Dictionary = Game.members()[0]
	Game.reset_member_talents(tm)
	var first: Array = SpecTalents.tree(tm["spec"])[0]
	Game.learn_member_talent(tm, first[0])
	_check(SpecTalents.spent(tm["talents"]) == 1 and not tm["auto_talents"], "a guildmate talent can be learned by hand")
	Game.auto_member_talents(tm)
	_check(SpecTalents.spent(tm["talents"]) == SpecTalents.points_at(24), "recommended build refills the tree")
	_check(Game.members().all(func(m): return not Game.member_abilities(m).is_empty()), "every guildmate has abilities from talents")
	_check_training(Game.members()[1])
	var st := Game.member_stats(Game.members()[2])
	_check(st["str"] > 0.0 and st["sta"] > 0.0 and st["armor"] > 0.0 and st["attack_power"] > 0.0,
		"guildmate stats are computed (Str %d, Sta %d, AP %d, armor %d)" % [st["str"], st["sta"], st["attack_power"], st["armor"]])

	# Character sheet, both tabs, for a guildmate
	main.show_hub("character")
	main.screen.selected_member = Game.members()[2]["id"]
	main.screen.refresh()
	await _frames(3)
	await _shot("05_sheet_stats")
	main.screen.sheet_tab = "talents"
	main.screen.refresh()
	await _frames(3)
	await _shot("05_sheet_talents")
	main.screen.sheet_tab = "stats"

	# A guild mission: send one guildmate, fast-forward the clock, collect
	var ms := Game.missions()
	_check(ms["board"].size() == Missions.BOARD_SIZE, "mission board is full")
	var away: Dictionary = Game.members()[4]
	Game.start_mission(0, [away["id"]])
	_check(ms["active"].size() == 1 and Game.is_busy(away), "a guildmate left on a mission")
	var odds: float = ms["active"][0]["chance"]
	_check(odds >= 0.0 and odds <= 1.0, "mission success chance is a probability (%d%%)" % int(odds * 100.0))
	var pd := PartyDialog.new()
	pd.act = {"party_size": 5}
	_check(not (away["id"] in pd._auto_pick()), "guildmates on missions aren't picked for activities")
	pd.free()
	main.show_hub("missions")
	await _frames(3)
	await _shot("05_missions_active")
	ms["active"][0]["end"] = Missions.now() - 1.0
	var res := Game.collect_mission(0)
	_check(res.has("success") and ms["active"].is_empty() and not Game.is_busy(away), "a finished mission can be collected (%s)" % ("success" if res.get("success") else "failed"))
	for t in ["spiritual_healing", "spiritual_healing", "spiritual_healing", "spiritual_healing", "spiritual_healing",
			"holy_specialization", "holy_specialization", "holy_specialization", "holy_specialization", "holy_specialization", "prayer_of_mending"]:
		Game.learn(t)
	_check(Game.priest()["talents"].get("prayer_of_mending", 0) == 1, "learned Prayer of Mending")
	Game.buy("mana_potion", 5)
	Game.buy("battle_elixir", 2)
	Game.upgrade_hall()
	_check(Game.hall() == 5, "upgraded the hall")
	for i in 6:
		Game._bank_add(Items.random_item(22, "rare", Game.rng))
	_check(Game.data["bank"].all(func(it): return not Stats.item_stats(it).is_empty()), "every item carries stats")
	Game.auto_equip_all()
	Game.sell_obsolete()
	main.show_hub("guild")
	await _frames(3)
	await _shot("05_guild_geared")
	main.show_hub("talents")
	await _frames(3)
	await _check_action_bar()
	await _frames(3)
	await _shot("05_talents")
	main.open_key_bindings()
	await _frames(3)
	await _shot("05_key_bindings")
	main.close_overlay()
	Game.reset_action_bar()

	var d := Dungeons.by_id("wc")
	var run_act := Activities.make_dungeon(d, Game.level(), Game.rng)
	Game.start_run(run_act, _auto(run_act))
	main.start_combat()
	guild_lines = 0
	await _play_run("06_dungeon")
	_check(guild_lines > 0, "guildmates used their abilities (%d combat log lines)" % guild_lines)
	var dloot: Array = Game.data["bank"].filter(func(it): return it.get("guaranteed", false) and it["profile"] == run_act["guaranteed"] and it["ilvl"] == d["ilvl"])
	_check(not dloot.is_empty(), "dungeon gave its guaranteed %s piece" % run_act["guaranteed"])

	# Level 60 raid with nine guildmates
	Game.data["priest"]["level"] = 60
	Game.data["hall"] = 10
	while Game.members().size() < 9:
		Game.refresh_recruits(false)
		Game.hire(0)
	var comp := ["warrior_protection", "shaman_elemental", "druid_balance", "rogue_combat", "mage_fire",
		"warlock_destruction", "hunter_marksmanship", "warrior_fury", "shaman_enhancement"]
	var talents_60 := {"spiritual_healing": 5, "holy_specialization": 5, "prayer_of_mending": 1, "inspiration": 3, "improved_healing": 3,
		"surge_of_light": 2, "empowered_healing": 5, "lightwell": 1, "circle_of_healing": 1, "twin_disciplines": 5, "meditation": 3,
		"inner_focus": 1, "mental_agility": 3, "penance": 1, "mental_strength": 5, "improved_shield": 3, "spirit_of_redemption": 1}
	Game.data["priest"]["talents"] = talents_60
	for i in Game.members().size():
		var m: Dictionary = Game.members()[i]
		m["spec"] = comp[i]
		m["class"] = ClassData.class_of(comp[i])
		m["tier"] = 11
		Game._grade_perk(m)
		m["gear"] = {}
		Game.auto_member_talents(m)
	for m in [Game.priest()] + Game.members():
		for slot in Items.SLOTS:
			var it := {}
			for tries in 30:
				it = Items.random_item(66, "epic", Game.rng, Game.member_stat(m), slot)
				if Items.can_use(it, Game.member_class(m)):
					break
			if Items.can_use(it, Game.member_class(m)):
				m["gear"][slot] = it
	var r := Raids.by_id("mc")
	var prestige_before := Game.prestige_total()
	Game.start_run(Activities.make_raid(r, [], Game.rng), _ids(9))
	main.start_combat()
	_check_lightwell(Game.build_engine())
	await _play_run("07_raid")
	_check(Game.data["raid_clears"].get("ony", 0) + int(Game.data["raid_progress"].has("ony")) >= 0, "raid flow finished")
	_check(Game.prestige_total() > prestige_before, "raid bosses grant prestige (%d, rank #%d)" % [Game.prestige_total() - prestige_before,
		Prestige.rank(Game.prestige_total())])
	main.show_hub("prestige")
	await _frames(3)
	await _shot("08_prestige")
	main.screen.recruit_tab = "training"
	main.screen.open_page("recruit")
	await _frames(3)
	await _shot("08_training")
	main.screen.recruit_tab = "recruits"

	# Save / load round trip
	Game.save()
	var lvl := Game.level()
	_check(Game.load_game(), "save loads")
	_check(Game.level() == lvl, "level survives the save")

	# An older save: healer guildmates and quests with a fixed reward choice
	Game.members()[1]["spec"] = "shaman_restoration"
	Game.members()[1]["class"] = "shaman"
	Game.members()[2]["spec"] = "priest_holy"
	Game.members()[2]["class"] = "priest"
	var priest_name: String = Game.members()[2]["name"]
	Game.data["quests"][0]["rewards"] = {"xp": 10, "gold": 10, "items": []}
	Game.data.erase("prestige")
	Game.data["raid_clears"]["mc"] = 2
	var old: Dictionary = Game.members()[0]
	old["talent_version"] = 1
	old["talents"] = {"old_talent": 3}
	old["auto_talents"] = false
	Game.save()
	_check(Game.load_game(), "old save loads")
	old = Game.members()[0]
	_check(old["talent_version"] == Game.TALENT_VERSION and not old["talents"].has("old_talent") \
		and SpecTalents.spent(old["talents"]) == SpecTalents.points_at(Game.level()), "old guildmate talents were rebuilt in the new trees")
	_check(Game.prestige_total() >= 2 * Prestige.for_clear(Raids.by_id("mc")), "an old save earns prestige for its past raid clears")
	_check(Game.members()[1]["spec"] == "shaman_elemental", "restoration shaman retrained as elemental")
	_check(Game.members().filter(func(m): return m["name"] == priest_name).is_empty(), "guildmate priest left the guild")
	_check(Game.data["quests"].all(func(q): return q["rewards"].has("gold_min")), "old quests were replaced")
	main.show_hub("raids")
	await _frames(3)
	await _shot("08_raids_60")
	Game.delete_save()
	print("SMOKE TEST %s (%d failure%s)" % ["PASSED" if failures == 0 else "FAILED", failures, "" if failures == 1 else "s"])
	print("Screenshots: " + shot_dir if shots else "")
	get_tree().quit(1 if failures > 0 else 0)


func _ids(n: int) -> Array:
	var ms: Array = Game.members().duplicate()
	ms.sort_custom(func(a, b): return Game.member_power(a) > Game.member_power(b))
	var out := []
	for m in ms.slice(0, n):
		out.append(m["id"])
	return out


## Plays every fight of the current run with the bot, accepting retries, and turns it in.
func _play_run(tag: String) -> void:
	var cs: CombatScreen = main.screen
	var guard := 0
	var shot_taken := false
	while guard < 30:
		guard += 1
		await _frames(2)
		cs.countdown = 0.0
		cs.running = true
		cs.center_label.text = ""
		if guard == 1 and tag == "04_quest":
			_check_pause_toggle(cs)
		var steps := 0
		if not cs.eng.combat_log.is_connected(_count_log):
			cs.eng.combat_log.connect(_count_log)
		while not cs.eng.over and steps < 9000:
			_bot(cs.eng)
			cs.eng.tick(0.1)
			steps += 1
			if steps == 120 and not shot_taken:
				cs._rebuild_enemies()
				cs._update_hud()
				cs.meter.queue_redraw()
				await _frames(2)
				await _shot(tag + "_combat")
				shot_taken = true
		_check(cs.eng.over, "fight ended (%s)" % tag)
		await get_tree().create_timer(1.3).timeout
		await _frames(2)
		if not cs.eng.won:
			var e := cs.eng
			var boss_hp := 0.0
			for en in e.enemies:
				if en.is_boss or en.is_elite:
					boss_hp = en.frac()
			var roles := []
			for m in e.party:
				roles.append("%s%s" % [m.role.substr(0, 1), "" if m.alive else "x"])
			print("  %s: wipe on fight %d at %.0fs, mana %d%%, boss %d%%, party %s, power %d/%d" % [tag, Game.run["fight"] + 1, e.time,
				int(100 * e.mana / e.max_mana), int(100 * boss_hp), " ".join(roles), Game.party_power(Game.run["members"]), Game.recommended_power(Game.run["activity"])])
			if Game.run["wipes"] > 8:
				_check(false, "run %s keeps wiping" % tag)
				Game.finish_run(false)
				main.show_hub()
				return
			if Game.run["wipes"] > 2:
				Game.run["mana_frac"] = 1.0
			cs.start_fight()
			continue
		if not Game.run_finished():
			cs.start_fight()
			continue
		_check_meter(cs, tag)
		await _shot(tag + "_victory")
		if Game.run["activity"]["type"] == "quest":
			var gold_before := Game.gold()
			cs._turn_in_quest()
			await _frames(3)
			await _shot(tag + "_reward")
			var rw: Dictionary = Game.run["activity"]["rewards"]
			_check(Game.gold() - gold_before >= rw["gold_min"], "quest paid gold in its range")
			var gp: Array = Game.run["loot"].filter(func(it): return it.get("guaranteed", false))
			_check(gp.size() == 1 and gp[0]["profile"] == Game.run["activity"]["guaranteed"], "quest gave its guaranteed %s piece" % Game.run["activity"]["guaranteed"])
			await _frames(2)
		print("  %s: done, %d XP, %s, %d items, %d wipes, level %d" % [tag, Game.run["xp"], Balance.money(Game.run["gold"]), Game.run["loot"].size(), Game.run["wipes"], Game.level()])
		cs._finish_success()
		await _frames(3)
		return
	_check(false, "run %s finished within the retry budget" % tag)
	Game.finish_run(false)
	main.show_hub()


## The damage meter: totals for the fight and the whole outing, breakdowns that add up.
func _check_meter(cs: CombatScreen, tag: String) -> void:
	var keep: bool = DamageMeter.overall
	DamageMeter.overall = false
	var cur: Dictionary = cs.meter.segment()[0]
	DamageMeter.overall = true
	var all: Dictionary = cs.meter.segment()[0]
	DamageMeter.overall = keep
	var p: String = Game.priest()["name"]
	var dealt := 0.0
	for n in all:
		dealt += all[n]["damage"]
	_check(all[p]["healing"] > 0.0 and dealt > 0.0, "the meter counts damage and healing (%s: %s healed, %s dealt)" % [tag,
		DamageMeter.short(all[p]["healing"]), DamageMeter.short(dealt)])
	_check(all[p]["healing"] >= cur[p]["healing"] and all[p]["taken"] >= cur[p]["taken"], "Overall adds up every fight of the outing (%s)" % tag)
	var parts: float = all[p]["healing_by"].values().reduce(func(a, b): return a + b, 0.0)
	_check(absf(parts - all[p]["healing"]) < 1.0, "the healing breakdown adds up to the total (%s)" % tag)


## The Lightwell: waits while everyone is healthy, heals the lowest ally every 0.5 sec, 20 charges, 20 sec.
func _check_lightwell(e: CombatEngine) -> void:
	e._resolve("lightwell", null)
	for i in 4:
		e._tick_lightwell(0.5)
	_check(e.lightwell.get("charges", 0) == 20, "the Lightwell waits while everyone is at full health")
	var a: CombatEngine.Unit = e.party[1]
	var b: CombatEngine.Unit = e.party[2]
	a.hp = a.max_hp * 0.5
	b.hp = b.max_hp * 0.3
	var a_hp := a.hp
	var b_hp := b.hp
	e._tick_lightwell(0.5)
	_check(b.hp > b_hp and a.hp == a_hp and e.lightwell["charges"] == 19, "the Lightwell heals the ally with the lowest health first")
	for m in e.party:
		m.hp = 1.0
	for i in 30:
		e._tick_lightwell(0.5)
	_check(e.lightwell.is_empty() and e.priest.healing_by.get("Lightwell", 0.0) > 0.0, "the Lightwell fades after its 20 charges")
	for m in e.party:
		m.hp = m.max_hp
	e._resolve("lightwell", null)
	for i in 39:
		e._tick_lightwell(0.5)
	var standing := not e.lightwell.is_empty()
	for i in 2:
		e._tick_lightwell(0.5)
	_check(standing and e.lightwell.is_empty(), "the Lightwell fades after 20 sec, its charges unused")


## WoW-style coefficients: each heal adds its share of healing power, Renew 100% split over its ticks.
func _check_coefficients() -> void:
	var gain := func(id: String, tal := {}) -> float:
		return CombatEngine.spell_amount(id, 40, 1000.0, 1.0, tal) - CombatEngine.spell_amount(id, 40, 0.0, 1.0, tal)
	_check(is_equal_approx(gain.call("renew"), 1000.0), "Renew adds 100% of healing power over its ticks")
	_check(is_equal_approx(gain.call("heal"), 1000.0 * 2.5 / 3.5) and is_equal_approx(gain.call("flash_heal"), 1000.0 * 1.5 / 3.5),
		"direct heals add cast time / 3.5 of healing power")
	_check(is_equal_approx(gain.call("heal", {"empowered_healing": 5}), 1000.0 * (2.5 / 3.5 + 0.4)), "Empowered Healing raises Heal's coefficient")
	# Smite is gone; its talents now work on heals
	_check(not Spells.BOOK.has("smite") and not ("smite" in Spells.known(60, {})), "the priest has no Smite")
	var twin := {"twin_disciplines": 5}
	var amt := func(id: String, tal: Dictionary) -> float:
		return CombatEngine.spell_amount(id, 40, 1000.0, 1.0, tal)
	_check(is_equal_approx(amt.call("renew", twin), amt.call("renew", {}) * 1.1) and is_equal_approx(amt.call("shield", twin), amt.call("shield", {}) * 1.1)
		and is_equal_approx(amt.call("heal", twin), amt.call("heal", {})), "Twin Disciplines raises instant spells only, by 10%")
	var eng := CombatEngine.new()
	eng.priest = CombatEngine.Unit.new()
	eng.talents = {"divine_fury": 5}
	eng._talent_values = {"divine_fury": Talents.value(eng.talents, "divine_fury")}
	_check(is_equal_approx(eng.cast_time("heal"), 2.0) and is_equal_approx(eng.cast_time("prayer_of_healing"), 2.5),
		"Divine Fury speeds up Heal and Prayer of Healing")
	var green := Stats.compute_stats("priest", "priest", 50, Stats.reference_gear_stats("healing", 50))
	_check(absf(green["heal_mult"] - 1.434) < 0.01, "at-level greens still make Lesser Heal 43%% bigger (%.3f)" % green["heal_mult"])


## Spell order and key bindings: moving a spell, new spells at the end, swapped keys, modifiers.
func _check_action_bar() -> void:
	var bar := Game.action_bar()
	Game.move_spell(bar[-1], 0)
	var moved := Game.action_bar()
	_check(moved[0] == bar[-1] and moved.size() == bar.size() and Game.priest_combat_spec({})["known"] == moved,
		"a spell moved to the first action bar slot (%s)" % moved[0])
	Game.priest()["talents"]["inner_focus"] = 1
	_check(Game.action_bar()[-1] == "inner_focus", "a newly learned spell goes at the end of a rearranged bar")
	Game.priest()["talents"].erase("inner_focus")
	# Drag the spellbook's first spell onto the third (events pushed into the game, not the real mouse).
	await _frames(2)
	var rows: Array = main.screen.find_children("*", "PanelContainer", true, false).filter(
		func(c): return c.mouse_default_cursor_shape == Control.CURSOR_DRAG)
	var before := Game.action_bar()
	if rows.size() >= 3:
		var from: Vector2 = rows[0].get_global_rect().get_center()
		var to: Vector2 = rows[2].get_global_rect().get_center()
		await _push_mouse(from, true, MOUSE_BUTTON_MASK_LEFT)
		for k in range(1, 9):
			await _push_motion(from.lerp(to, k / 8.0), from.lerp(to, (k - 1) / 8.0))
		await _push_mouse(to, false, 0)
		await _frames(3)
	_check(Game.action_bar()[2] == before[0], "dragging a spell in the spellbook moves it (%s now in slot 3)" % Game.action_bar()[2])
	var keys: Dictionary = Settings.keys.duplicate()
	Settings.reset_keys()
	Settings.bind("slot1", KEY_2)
	_check(Settings.keys["slot1"] == KEY_2 and Settings.keys["slot2"] == KEY_1, "binding a key in use swaps the two")
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_2
	_check(Settings.action_for(Settings.event_code(ev)) == "slot1", "a key press finds its action")
	Settings.bind("potion", KEY_MASK_SHIFT | KEY_1)
	ev.physical_keycode = KEY_1
	ev.shift_pressed = true
	_check(Settings.action_for(Settings.event_code(ev)) == "potion" and Settings.key_short("potion") == "s-1", "Shift combinations bind (%s)" % Settings.key_label("potion"))
	_check(Settings.reserved(KEY_ESCAPE) and Settings.reserved(KEY_SHIFT), "Escape and lone modifiers can't be bound")
	# Leave the player's own bindings as they were (nothing here is saved).
	Settings.keys = keys
	await _frames(1)


func _push_mouse(at: Vector2, pressed: bool, mask: int) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.button_mask = mask
	ev.position = at
	ev.global_position = at
	get_viewport().push_input(ev, true)
	await _frames(1)


func _push_motion(at: Vector2, last: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	ev.position = at
	ev.global_position = at
	ev.relative = at - last
	get_viewport().push_input(ev, true)
	await _frames(1)


## Trains a guildmate from their grade to S: gold up to A, prestige past it, unlocks at B, A and S.
func _check_training(m: Dictionary) -> void:
	var start: int = m["tier"]
	var gold_before := Game.gold()
	Game.train(m)
	_check(m["tier"] == start + 1 and Game.gold() < gold_before, "training raises a grade for gold (%s to %s)" % [
		Tiers.name_of(start), Tiers.name_of(m["tier"])])
	while m["tier"] < Tiers.A:
		Game.train(m)
	var ids := Game.member_abilities(m).map(func(a): return a["id"])
	_check(m.has("grade_perk") and SpecTalents.CLASS_SPELLS[m["class"]] in ids,
		"grade B gave %s and grade A taught %s" % [m.get("grade_perk", ["nothing"])[0], SpecTalents.CLASS_SPELLS[m["class"]]])
	Game.data["prestige"] = {"points": 0, "total": 0}
	Game.train(m)
	_check(m["tier"] == Tiers.A, "training past A needs prestige")
	Game.add_prestige(Tiers.train_prestige(Tiers.A) + Tiers.train_prestige(Tiers.A + 1))
	Game.train(m)
	Game.train(m)
	ids = Game.member_abilities(m).map(func(a): return a["id"])
	_check(m["tier"] == Tiers.S and Game.prestige() == 0 and SpecTalents.RACE_SPELLS[m["race"]] in ids,
		"prestige trained to S, which taught %s" % SpecTalents.RACE_SPELLS[m["race"]])
	Game.data["prestige"] = {"points": 0, "total": 0}


func _count_log(category: String, _text: String) -> void:
	if category == "guild":
		guild_lines += 1


## Space toggles the pause on press; releasing it changes nothing, and no button can steal the key.
func _check_pause_toggle(cs: CombatScreen) -> void:
	var focusable := cs.find_children("*", "BaseButton", true, false).filter(func(b): return b.focus_mode != Control.FOCUS_NONE)
	_check(focusable.is_empty(), "no combat button can take keyboard focus (%d can)" % focusable.size())
	var press := InputEventKey.new()
	press.keycode = KEY_SPACE
	press.physical_keycode = KEY_SPACE
	press.pressed = true
	var release: InputEventKey = press.duplicate()
	release.pressed = false
	cs._unhandled_input(press)
	cs._unhandled_input(release)
	_check(cs.paused, "Space pauses, and stays paused when released")
	cs._unhandled_input(press)
	cs._unhandled_input(release)
	_check(not cs.paused, "Space again resumes")


## Screens only, for checking layouts at several resolutions: a quest fight and the sheet.
func _ui_only() -> void:
	var q: Dictionary = Game.data["quests"][1]
	Game.start_run(q, _ids(2))
	main.start_combat()
	var cs: CombatScreen = main.screen
	await _frames(2)
	cs.countdown = 0.0
	cs.running = true
	cs.center_label.text = ""
	for i in 120:
		_bot(cs.eng)
		cs.eng.tick(0.1)
	cs._rebuild_enemies()
	await _frames(3)
	await _shot("10_ui_combat")
	Game.finish_run(false)
	main.show_hub("character")
	await _frames(3)
	await _shot("10_ui_sheet")
	print("SMOKE TEST %s (%d failure%s)" % ["PASSED" if failures == 0 else "FAILED", failures, "" if failures == 1 else "s"])
	get_tree().quit(1 if failures > 0 else 0)


func _bot(eng: CombatEngine) -> void:
	if not eng.casting.is_empty() or eng.gcd > 0.0:
		return
	if eng.mana < eng.max_mana * 0.3:
		eng.use_mana_potion()
	var low = null
	for m in eng.alive_party():
		if low == null or m.frac() < low.frac():
			low = m
		for au in m.auras:
			if au.get("harmful", false) and au.get("dispel", "") in ["magic", "disease"]:
				if eng.cast("dispel", m) == "":
					return
	if low == null:
		return
	var t := eng.tank()
	if t != null and eng.cast("prayer_of_mending", t) == "":
		return
	if low.frac() < 0.5:
		for sp in ["shield", "flash_heal", "heal"]:
			if eng.cast(sp, low) == "":
				return
	if low.frac() < 0.8:
		if not low.has("renew") and eng.cast("renew", low) == "":
			return
		eng.cast("heal", low)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("SMOKE FAIL: " + what)
	else:
		print("  ok: " + what)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(name + ".png"))


## The party the party dialog would pick.
func _auto(act: Dictionary) -> Array:
	var pd := PartyDialog.new()
	pd.act = act
	var ids := pd._auto_pick()
	pd.free()
	return ids
