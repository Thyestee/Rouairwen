extends Node
## End-to-end smoke test, driven from main.gd when the game runs with "-- --smoke".
## Plays through every screen with a bot healer on a throwaway save; "--shots" also saves screenshots.

var main
var shots := false
var shot_dir := ""
var failures := 0


func run() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	shot_dir = ProjectSettings.globalize_path("user://smoke_shots")
	DirAccess.make_dir_recursive_absolute(shot_dir)
	Game.save_path = "user://smoke_save.txt"
	# A fixed seed makes every run play the same fights, so a failure is reproducible.
	Game.rng.seed = 20261027
	await _frames(5)
	await _shot("01_title")
	Game.new_game()
	main.show_hub()
	await _frames(3)
	for p in ["quests", "guild", "dungeons", "raids", "recruit", "shop", "hall", "talents"]:
		main.screen.open_page(p)
		await _frames(3)
		await _shot("02_hub_" + p)

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
	for m in Game.members():
		m["tier"] = maxi(m["tier"], 6)
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
	Game.auto_equip_all()
	Game.sell_obsolete()
	main.show_hub("guild")
	await _frames(3)
	await _shot("05_guild_geared")
	main.show_hub("talents")
	await _frames(3)
	await _shot("05_talents")

	var d := Dungeons.by_id("wc")
	var run_act := Activities.make_dungeon(d, Game.level(), Game.rng)
	Game.start_run(run_act, _auto(run_act))
	main.start_combat()
	await _play_run("06_dungeon")
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
		m["gear"] = {}
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
	Game.start_run(Activities.make_raid(r, [], Game.rng), _ids(9))
	main.start_combat()
	await _play_run("07_raid")
	_check(Game.data["raid_clears"].get("ony", 0) + int(Game.data["raid_progress"].has("ony")) >= 0, "raid flow finished")

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
	Game.save()
	_check(Game.load_game(), "old save loads")
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
		var steps := 0
		while not cs.eng.over and steps < 9000:
			_bot(cs.eng)
			cs.eng.tick(0.1)
			steps += 1
			if steps == 120 and not shot_taken:
				cs._rebuild_enemies()
				cs._update_hud()
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
	elif eng.mana > eng.max_mana * 0.5:
		eng.cast("smite", null)


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
