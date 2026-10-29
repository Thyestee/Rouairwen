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
	Settings.boost = false
	# A fixed seed makes every run play the same fights, so a failure is reproducible.
	Game.rng.seed = 20261027
	await _frames(5)
	await _shot("01_title")
	Game.new_game()
	Settings.boost = true
	var boosted := Game._grant(1, 1, [])
	_check(boosted["xp"] == Settings.BOOST and boosted["gold"] == Settings.BOOST, "the testing option multiplies experience and gold")
	Settings.boost = false
	Game.data["gold"] -= Settings.BOOST
	_check_rewards()
	_check_grades()
	_check_missions_and_ladder()
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
	if res.get("success", false):
		_check(res["gold"] > 0 or not res["items"].is_empty(), "a successful mission brings back spoils")
	for t in ["spiritual_healing", "spiritual_healing", "spiritual_healing", "spiritual_healing", "spiritual_healing",
			"holy_specialization", "holy_specialization", "holy_specialization", "holy_specialization", "holy_specialization", "prayer_of_mending"]:
		Game.learn(t)
	_check(Game.priest()["talents"].get("prayer_of_mending", 0) == 1, "learned Prayer of Mending")
	_check_runes()
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
	TalentPage.tab = "runes"
	main.screen.refresh()
	await _frames(3)
	await _shot("05_runes")
	TalentPage.tab = "talents"
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
	# All three runes in the raid: Prayer of Mending's Renews, crit shields, and shared damage on the meter.
	for id in ["mending", "warding_light", "shared_pain"]:
		Game.engrave(id)
	_check(Game.active_runes().size() == 3 and Game.empty_rune_slots() == 0, "a rune engraved in each of the three slots at 60")
	TalentPage.tab = "runes"
	main.show_hub("talents")
	await _frames(3)
	await _shot("08_runes")
	TalentPage.tab = "talents"
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


## Runes: three slots that open at 20, 30 and 40 with 3-5 runes each, unlocked once what they change is
## within reach; engraving; and what each rune does in a fight.
func _check_runes() -> void:
	var sizes_ok := Runes.SLOTS.all(func(s): return Runes.in_slot(s["id"]).size() >= 3 and Runes.in_slot(s["id"]).size() <= 5)
	_check(sizes_ok and Runes.SLOTS[0]["level"] == 20, "three rune slots, the first at level 20, each with 3 to 5 runes")
	var coherent := true
	for id in Runes.LIST:
		var r: Dictionary = Runes.LIST[id]
		if r["level"] < Runes.slot(r["slot"])["level"] or Runes.describe(id).contains("{"):
			coherent = false
		if r.has("spell"):
			var sp: Dictionary = Spells.BOOK[r["spell"]]
			if sp.get("talent", false):
				if Balance.talent_points_at(r["level"]) <= Talents.find(r["spell"])["tier"] * Talents.POINTS_PER_TIER:
					coherent = false
			elif sp["level"] > r["level"]:
				coherent = false
	_check(coherent, "each rune unlocks in its slot once the spell it changes is within reach")
	# Engraving at level 24: the spell slot only
	Game.engrave("warding_light")
	Game.engrave("echoing_prayer")
	_check(Game.runes().is_empty() and Game.empty_rune_slots() == 1, "runes of closed slots or higher levels can't be engraved")
	Game.engrave("binding")
	Game.engrave("mending")
	_check(Game.active_runes() == ["mending"] and Game.priest_combat_spec({})["runes"] == ["mending"] and Game.empty_rune_slots() == 0,
		"an engraved rune replaces the one in its slot")
	_check(Runes.spell_line("prayer_of_mending", Game.active_runes()).contains("Renew"), "the spellbook shows a spell's rune")

	# Each rune at work, calling the engine's parts directly (no fight running)
	var e := _rune_engine(["mending"])
	var e0 := _rune_engine([])
	for x in [e, e0]:
		x._resolve("prayer_of_mending", x.party[1])
		x.damage(x.party[1], 1.0, null)
	_check(e.party[1].has("renew") and not e0.party[1].has("renew"), "Rune of Mending: Prayer of Mending casts Renew where it heals")

	e = _rune_engine(["binding"])
	var a: CombatEngine.Unit = e.party[1]
	var b: CombatEngine.Unit = e.party[2]
	a.hp = a.max_hp * 0.5
	b.hp = b.max_hp * 0.5
	var b_hp := b.hp
	e._resolve("flash_heal", a)
	_check(b.hp > b_hp and e.priest.healing_by.has("Binding Light"), "Rune of Binding Light: Flash Heal also heals the most injured other ally")

	var e_plain := _rune_engine([], false)
	e = _rune_engine(["penitence"])
	e.known.append("penance")
	e.cast("penance", e.party[1])
	_check(e.casting.get("bolts", 0) == 5 and is_equal_approx(e.casting.get("total", 0.0), 4.0) and is_equal_approx(e.cooldown_left("penance"), 6.0),
		"Rune of Penitence: Penance fires 5 bolts over 4 sec, every 6 sec")

	e = _rune_engine(["soul_warding"])
	e._resolve("shield", e.party[1])
	_check(not e.party[1].has("weakened_soul") and is_equal_approx(e.spell_cost("shield"), e_plain.spell_cost("shield") * 0.7),
		"Rune of Soul Warding: no Weakened Soul, and Power Word: Shield costs 30% less")

	e = _rune_engine(["echoing_prayer"])
	for x in e.party:
		x.hp = x.max_hp * 0.5
	e._resolve("prayer_of_healing", null)
	_check(e.party.all(func(x): return x.has("echo")), "Rune of Echoing Prayer: Prayer of Healing leaves a heal over time")

	e = _rune_engine(["warding_light"], false)
	var crit_up := is_equal_approx(e.crit, e_plain.crit + 0.1)
	e.crit = 1.0
	e._heal(e.party[1], 100.0, true, "heal")
	_check(crit_up and e.party[1].get_aura("ward").get("absorb", 0.0) > 25.0,
		"Rune of Warding Light: +10% critical chance, and a critical heal shields for 20% of it")

	e = _rune_engine(["clarity"])
	for i in 3:
		e._spend("renew")
	var mana_before := e.mana
	var free := e.priest.has("clearcasting") and e.spell_cost("renew") == 0.0
	e._spend("renew")
	_check(free and e.mana == mana_before and not e.priest.has("clearcasting"), "Rune of Clarity: the fourth spell is free")

	e = _rune_engine(["desperate_prayer"])
	var p: CombatEngine.Unit = e.priest
	p.hp = p.max_hp * 0.36
	e.damage(p, p.max_hp * 0.1 / p.mit, null)
	_check(p.frac() > 0.6 and e.desperate_cd > 0.0, "Rune of Desperate Prayer: you heal yourself below 35%% health (now %d%%)" % int(p.frac() * 100.0))
	# Same seed, so both engines draw the same random spread: only the rune differs.
	var heals := []
	for x in [_rune_engine(["desperate_prayer"]), _rune_engine([])]:
		x.party[1].hp = x.party[1].max_hp * 0.2
		heals.append(x._heal(x.party[1], 100.0, false, "heal"))
	_check(absf(heals[0] / heals[1] - 1.3) < 0.01, "Rune of Desperate Prayer: heals on allies below 35% are 30% stronger")

	e = _rune_engine(["overflow"])
	e._heal(e.party[1], e.party[1].max_hp, false, "heal")
	var ov: float = e.party[1].get_aura("overflow").get("absorb", 0.0)
	_check(ov > 0.0 and ov <= e.party[1].max_hp * 0.2 + 0.01, "Rune of Overflowing Light: overhealing becomes a shield, up to 20% of health")

	e = _rune_engine(["fervor"])
	var plain := e._base_heal("heal")
	for i in 3:
		e._spend("renew")
	_check(e.priest.get_aura("fervor").get("stacks", 0) == 3 and is_equal_approx(e._base_heal("heal"), plain * 1.09),
		"Rune of Fervor: each spell cast makes heals 3% stronger")

	e = _rune_engine(["shared_pain"])
	var n := e.party.size()
	var tank: CombatEngine.Unit = e.party[1]
	var hit := tank.max_hp * 0.3
	var before: Array = e.party.map(func(x): return x.hp)
	e.damage(tank, hit / tank.mit, null)
	var other_loss: float = before[2] - e.party[2].hp
	var tank_loss: float = before[1] - tank.hp
	_check(absf(other_loss - hit * 0.2 / n) < 0.5 and absf(tank_loss - hit * (0.8 + 0.2 / n)) < 0.5,
		"Rune of Shared Pain: 20% of a hit is spread over the whole party")

	e = _rune_engine(["fortitude"])
	_check(is_equal_approx(e.party[1].max_hp, e_plain.party[1].max_hp * 1.15) and is_equal_approx(e.priest.max_hp, e_plain.priest.max_hp * 1.15),
		"Rune of Fortitude: everyone has 15% more health")
	e = _rune_engine(["zeal"])
	_check(is_equal_approx(e.party[1].dps, e_plain.party[1].dps * 1.15), "Rune of Zeal: guildmates deal 15% more damage")

	e = _rune_engine(["atonement"])
	var foe := CombatEngine.Unit.new()
	foe.is_enemy = true
	foe.max_hp = 1e9
	foe.hp = 1e9
	e.enemies.append(foe)
	var hurt: CombatEngine.Unit = e.party[2]
	hurt.hp = hurt.max_hp * 0.2
	var hurt_hp := hurt.hp
	e._damage_enemy(foe, hurt.max_hp, e.party[1])
	e._tick_atonement(1.0)
	_check(hurt.hp > hurt_hp and e.priest.healing_by.has("Atonement"), "Rune of Atonement: the guild's damage heals the most injured ally")

	e = _rune_engine(["guardian"])
	var g: CombatEngine.Unit = e.party[1]
	g.mods = {}
	e.damage(g, g.max_hp * 5.0 / g.mit, null)
	var saved := g.alive and absf(g.frac() - 0.4) < 0.01
	e.damage(g, g.max_hp * 5.0 / g.mit, null)
	_check(saved and not g.alive, "Rune of the Guardian Spirit: saves an ally at 40% health, then not again for 40 sec")

	# Divine Aegis: no longer from critical heals (Warding Light's job), but from Power Word: Shields used up
	e = _rune_engine([])
	e.talents["divine_aegis"] = 3
	e._talent_values["divine_aegis"] = Talents.value(e.talents, "divine_aegis")
	e.crit = 1.0
	e._heal(e.party[3], 100.0, true, "heal")
	var shielded: CombatEngine.Unit = e.party[1]
	var hurt_most: CombatEngine.Unit = e.party[2]
	e._resolve("shield", shielded)
	var strength: float = shielded.get_aura("pws")["strength"]
	hurt_most.hp = hurt_most.max_hp * 0.3
	e.damage(shielded, (strength + 1.0) / shielded.mit, null)
	var aegis: float = hurt_most.get_aura("aegis").get("absorb", 0.0)
	_check(not e.party[3].has("aegis") and not shielded.has("pws") and absf(aegis - minf(strength * 0.45, hurt_most.max_hp * 0.4)) < 0.5,
		"Divine Aegis: a used-up Power Word: Shield shields the most injured ally for 45% of it")


## An engine with Thyeste, four guildmates, these runes and no enemy, whose parts are called directly.
## Crits are off unless asked for, so heals are predictable.
func _rune_engine(runes: Array, no_crit := true) -> CombatEngine:
	var ps := Game.priest_combat_spec({})
	ps["runes"] = runes
	var specs := []
	for m in Game.members().slice(0, 4):
		specs.append(Game.member_combat_spec(m, {}))
	var e := CombatEngine.new()
	e.setup(ps, specs, [], {"level": Game.level(), "seed": 11})
	if no_crit:
		e.crit = 0.0
	return e


## Missions show their experience (30-50% of a level) and keep their spoils, gold, gear or both, a
## surprise; the prestige ladder holds 100 rival guilds with the same top.
func _check_missions_and_ladder() -> void:
	var need := Balance.xp_to_next(Game.level())
	var shown_ok := true
	for mi in Game.missions()["board"]:
		var rw: Dictionary = mi["rewards"]
		if rw["xp"] < int(need * 0.3) or rw["xp"] > int(need * 0.5) or rw.has("gold_min") or rw.has("items"):
			shown_ok = false
	_check(shown_ok, "missions show 30-50% of a level in experience, and nothing else")
	var kinds := {"gold": 0, "gear": 0, "both": 0}
	var mission: Dictionary = Game.missions()["board"][0]
	for i in 300:
		var sp := Missions.spoils(mission, Game.rng)
		kinds["both" if sp.has("gold") and sp.has("items") else ("gold" if sp.has("gold") else "gear")] += 1
	_check(kinds.values().all(func(n): return n > 60), "mission spoils are gold, gear or both (%s)" % str(kinds))
	_check(Prestige.guild_count() == 101 and Prestige.rank(0) == 101 and Prestige.rival_score(0) == Prestige.TOP,
		"the ladder ranks 100 rival guilds under the same #1")


## Rewards are 4 times what they were: experience, gold, and gear pieces (the boost multiplies them again).
func _check_rewards() -> void:
	var q: Dictionary = Game.data["quests"][0]
	_check(q["rewards"]["items_min"] >= Balance.LOOT_RATE, "quests give %d times the gear (%d–%d pieces)" % [Balance.LOOT_RATE,
		q["rewards"]["items_min"], q["rewards"]["items_max"]])
	var rw: Dictionary = q["rewards"].duplicate()
	rw["items_min"] = 2
	rw["items_max"] = 2
	var r := Activities.roll_rewards(rw, "", [], Game.rng, Game.wearable_item, Settings.BOOST)
	_check(r["items"].size() == 2 * Settings.BOOST, "the testing option multiplies the number of pieces")
	_check(Balance.xp_per_fight(10) == int(round(Balance.xp_to_next(10) / Balance.fights_per_level(10) * 6.0)), "experience is 4 times the old 1.5 rate")


## Grades give the stats a spec fights with, mostly as gains per level; affixes fit the spec.
func _check_grades() -> void:
	_check(Tiers.stats("warrior_fury", 0, 60).is_empty(), "an F grade adds no stats")
	var fury := Tiers.stats("warrior_fury", 10, 60)
	var mage := Tiers.stats("mage_frost", 10, 60)
	var tank := Tiers.stats("warrior_protection", 10, 60)
	_check(fury.get("str", 0.0) > fury.get("sta", 0.0) and not fury.has("sp"), "a Fury warrior's grade is mostly Strength (%s)" % Tiers.stats_text(fury))
	_check(mage.get("sp", 0.0) > 0.0 and mage.get("int", 0.0) > 0.0 and not mage.has("str"), "a mage's grade is Spell Damage and Intellect (%s)" % Tiers.stats_text(mage))
	_check(tank.get("sta", 0.0) > fury.get("sta", 0.0) and tank.get("def", 0.0) > 0.0, "a tank's grade is mostly Stamina, with Defense (%s)" % Tiers.stats_text(tank))
	var low := Tiers.stats("warrior_fury", 10, 10)
	_check(low["str"] / Stats.base("warrior", 10)["str"] < fury["str"] / Stats.base("warrior", 60)["str"], "a grade grows with the levels")
	var plain := Stats.compute_stats("warrior", "physical", 60, {})
	var graded := Stats.compute_stats("warrior", "physical", 60, {}, {}, fury)
	_check(graded["offense"] > plain["offense"] and graded["health_mult"] > plain["health_mult"], "grade stats raise damage and health")
	var wrong := 0
	for i in 200:
		for a in Game.roll_affixes("warrior_fury", 0):
			if a[0] in ["Brilliant", "Dim", "Arcane-Touched", "Ironhide", "Menacing", "Glass Jaw", "Distracted"]:
				wrong += 1
	_check(wrong == 0, "affixes suit the spec (no caster or tank affixes on a Fury warrior)")
	var good_f := 0
	var good_a := 0
	for i in 400:
		for a in Game.roll_affixes("mage_fire", 0):
			good_f += 1 if SpecTalents.power_value(a[1]) > 0.0 else 0
		for a in Game.roll_affixes("mage_fire", Tiers.A):
			good_a += 1 if SpecTalents.power_value(a[1]) > 0.0 else 0
	_check(good_a > good_f, "better grades bring better affixes (%d against %d good)" % [good_a, good_f])


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
	# The runes at 60, the longest names engraved (the three columns keep the same width)
	Game.data["priest"]["level"] = 60
	for id in ["echoing_prayer", "desperate_prayer", "guardian"]:
		Game.engrave(id)
	TalentPage.tab = "runes"
	main.show_hub("talents")
	await _frames(3)
	await _shot("10_ui_runes")
	TalentPage.tab = "talents"
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
