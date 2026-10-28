extends SceneTree
## Headless balance check: a bot priest heals simulated fights across levels and party strengths.
## Run: godot --headless --path . --script res://tools/balance_sim.gd

const DT := 0.1
const RUNS := 40
## Whether guildmates carry talents and traits (false reproduces the pre-talent balance).
var TALENTS := not ("--no-talents" in OS.get_cmdline_user_args())
## Whether guildmates use their talent abilities.
var ABILITIES := not ("--no-abilities" in OS.get_cmdline_user_args())

const BUILD := ["spiritual_healing", "spiritual_healing", "spiritual_healing", "spiritual_healing", "spiritual_healing",
	"holy_specialization", "holy_specialization", "holy_specialization", "holy_specialization", "holy_specialization",
	"prayer_of_mending", "inspiration", "inspiration", "inspiration", "improved_healing", "improved_healing", "improved_healing",
	"empowered_healing", "empowered_healing", "empowered_healing", "empowered_healing", "empowered_healing",
	"surge_of_light", "surge_of_light", "spirit_of_redemption", "lightwell", "circle_of_healing",
	"twin_disciplines", "twin_disciplines", "twin_disciplines", "twin_disciplines", "twin_disciplines",
	"meditation", "meditation", "meditation", "inner_focus", "mental_agility", "mental_agility", "mental_agility",
	"penance", "mental_strength", "mental_strength", "mental_strength", "mental_strength", "mental_strength",
	"improved_shield", "improved_shield", "improved_shield", "borrowed_time", "borrowed_time", "borrowed_time"]


func _init() -> void:
	print("kind      lvl  tier gear  diff | win%  time  mana%  deaths  hps")
	for row in [
		["quest", 1, 2, 0.10, 1.0], ["quest", 3, 2, 0.15, 1.0], ["quest", 6, 2, 0.25, 1.0], ["quest", 6, 2, 0.25, 1.18],
		["quest", 9, 2, 0.30, 1.4], ["quest", 15, 4, 0.35, 1.0], ["quest", 30, 6, 0.4, 1.18],
		["dungeon", 12, 3, 0.30, 1.3], ["dungeon", 20, 4, 0.40, 1.4], ["dungeon", 24, 6, 0.15, 1.3], ["dungeon", 35, 6, 0.45, 1.55], ["dungeon", 50, 8, 0.50, 1.7],
		["dungeon", 60, 9, 0.50, 2.0], ["dungeon", 60, 10, 0.55, 2.15],
		["raid", 60, 11, 0.55, 2.6], ["raid", 60, 9, 0.50, 2.6], ["raid", 60, 13, 0.80, 3.1], ["raid", 60, 15, 0.95, 3.6], ["raid", 60, 17, 1.15, 4.1],
	]:
		_scenario(row[0], row[1], row[2], row[3], row[4])
	_talent_values()
	_tier_odds()
	_economy()
	_prestige()
	quit()


func _party(kind: String) -> Array:
	match kind:
		"quest":
			return ["shaman_enhancement", "warrior_fury"]
		"dungeon":
			return ["warrior_protection", "rogue_combat", "mage_fire", "shaman_enhancement"]
		_:
			return ["warrior_protection", "shaman_elemental", "druid_balance", "rogue_combat", "mage_frost",
				"warlock_destruction", "hunter_marksmanship", "warrior_fury", "druid_balance"]


func _talents(level: int) -> Dictionary:
	var t := {}
	for i in mini(Balance.talent_points_at(level), BUILD.size()):
		t[BUILD[i]] = t.get(BUILD[i], 0) + 1
	return t


func _scenario(kind: String, level: int, tier: int, gear: float, diff: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + level
	var wins := 0
	var time := 0.0
	var mana := 0.0
	var deaths := 0
	var hps := 0.0
	var u := Balance.scale(level)
	for i in RUNS:
		var specs := []
		for sid in _party(kind):
			specs.append(_member(sid, level, tier, gear, rng))
		var tal := _talents(level)
		var ps := Stats.compute_stats("priest", "priest", level, _gear("priest", "healing", level, gear))
		var priest := {"name": "Bot", "talents": tal, "known": Spells.known(level, tal),
			"max_hp": 100.0 * u * ps["health_mult"], "max_mana": 300.0 * u * ps["mana_mult"],
			"regen": 6.0 * u * ps["regen_mult"], "heal_power": ps["heal_power"],
			"crit": ps["spell_crit"] / 100.0, "dodge": ps["dodge"], "mit": Stats.armor_factor("priest", level, ps["armor"])}
		var size := 3 if kind == "quest" else (5 if kind == "dungeon" else 10)
		var ftype := "pack"
		var fight := {}
		var roll := i % 3
		if kind == "quest":
			var z: Dictionary = Zones.for_level(level)[0]
			var fam: Array = z["families"][i % z["families"].size()]
			if roll == 2:
				fight = {"type": "elite", "boss": {"name": z["elites"][0][0], "abilities": z["elites"][0][1]}, "mobs": [[fam[0], fam[3]]]}
			else:
				fight = {"type": "pack", "mobs": [[fam[0], fam[3]], [fam[0], fam[3]], [fam[0], fam[3]]] if level >= 4 else [[fam[0], fam[3]], [fam[0], fam[3]]]}
		elif kind == "dungeon":
			var d: Dictionary = Dungeons.LIST[0]
			for dd in Dungeons.LIST:
				if level >= dd["min"]:
					d = dd
			if roll == 0:
				fight = {"type": "pack", "mobs": [d["trash"][0], d["trash"][1], d["trash"][2]]}
			else:
				fight = {"type": "boss", "boss": d["bosses"][i % d["bosses"].size()], "mobs": []}
		else:
			var r: Dictionary = Raids.LIST[1]
			for rr in Raids.LIST:
				if absf(rr["diff"] - diff) < 0.05:
					r = rr
			fight = {"type": "raid_boss", "boss": r["bosses"][i % r["bosses"].size()], "mobs": []}
			fight["final"] = fight["boss"].get("final", false)
		var enemies := Encounters.build(fight, level, diff, size, rng)
		var eng := CombatEngine.new()
		var pr := ShopData.best_rank("mana_potion", level)
		eng.setup(priest, specs, enemies, {"level": level, "seed": rng.randi(), "soulstone": true,
			"potions": {"mana": 2, "mana_amount": ShopData.rank_value("mana_potion", pr) * Balance.scale(ShopData.rank_level("mana_potion", pr))}})
		while not eng.over and eng.time < 600.0:
			_bot(eng)
			eng.tick(DT)
		if eng.won:
			wins += 1
		time += eng.time
		mana += eng.mana / eng.max_mana
		deaths += eng.stats["deaths"]
		hps += eng.stats["healing"] / maxf(eng.time, 1.0) / u
	print("%-8s %4d  %4s %4.2f %5.2f | %4d  %4.0f  %4.0f   %5.2f  %4.1f" % [kind, level, Tiers.name_of(tier), gear, diff,
		100 * wins / RUNS, time / RUNS, 100.0 * mana / RUNS, float(deaths) / RUNS, hps / RUNS])


## A competent but not perfect healer.
func _bot(eng: CombatEngine) -> void:
	if not eng.casting.is_empty() or eng.gcd > 0.0:
		return
	if eng.mana < eng.max_mana * 0.25 and eng.mana_potions > 0 and eng.potion_cd <= 0.0:
		eng.use_mana_potion()
	var alive := eng.alive_party()
	var low = null
	var tank = eng.tank()
	var injured := 0
	for m in alive:
		if low == null or m.frac() < low.frac():
			low = m
		if m.frac() < 0.75:
			injured += 1
	for m in alive:
		for au in m.auras:
			if au.get("harmful", false) and au.get("dispel", "") in ["magic", "disease"] and (au.get("cc", false) or m.frac() < 0.8):
				if eng.cast("dispel", m) == "":
					return
	if low == null:
		return
	if low.frac() < 0.35:
		for sp in ["pain_suppression", "shield", "penance", "flash_heal", "heal"]:
			if eng.cast(sp, low) == "":
				return
	if tank != null and eng.cast("prayer_of_mending", tank) == "":
		return
	if injured >= 3:
		for sp in ["circle_of_healing", "prayer_of_healing"]:
			if eng.cast(sp, null) == "":
				return
	if tank != null and tank.frac() < 0.85 and not tank.has("renew") and eng.cast("renew", tank) == "":
		return
	if low.frac() < 0.6:
		if eng.cast("penance", low) == "":
			return
		if eng.cast("heal", low) == "":
			return
	if low.frac() < 0.8 and not low.has("renew") and eng.mana > eng.max_mana * 0.5:
		eng.cast("renew", low)


## A guildmate of this grade in reference gear, with the recommended talents and 2 random traits.
func _member(sid: String, level: int, tier: int, gear: float, rng: RandomNumberGenerator) -> Dictionary:
	var sp: Dictionary = ClassData.SPECS[sid]
	var cls: String = sp["class"]
	var kind := "tank" if sp["role"] == "tank" else ("spell" if sp["stat"] == "spell" else "physical")
	var profile := "tank" if kind == "tank" else ("spell" if kind == "spell" else
		("physical_agi" if cls in ["rogue", "hunter"] else "physical_str"))
	var tal := SpecTalents.auto_build(sid, {}, level) if TALENTS else {}
	var mods := _member_mods(sid, tal, rng)
	# Grade B perk, and the class (A) and racial (S) spells
	if tier >= Tiers.B:
		SpecTalents.add_effects(mods, Tiers.B_PERKS[rng.randi() % Tiers.B_PERKS.size()][1])
	var races: Array = ClassData.CLASSES[cls]["races"]
	var grade := SpecTalents.grade_spells(cls, races[rng.randi() % races.size()], tier)
	var st := Stats.compute_stats(cls, kind, level, _gear(cls, profile, level, gear), mods)
	return CombatEngine.member_spec(sid, sid, Tiers.power(tier), st, mods,
		SpecTalents.abilities_for(sid, tal, mods, grade) if ABILITIES else [], level)


## Reference gear: `gear` is what the old gear bonus was (0.4 = a full set of at-level greens).
func _gear(cls: String, profile: String, level: int, gear: float) -> Dictionary:
	var scale := gear / 0.4
	var g := Stats.reference_gear_stats(profile, level)
	for k in g:
		g[k] *= scale
	g["armor"] = (Stats.reference_armor(cls, level) - Stats.base(cls, level)["agi"] * 2.0) * clampf(scale, 0.6, 1.3)
	return g


## Talents as a guildmate would have them (recommended build) plus 2 random traits, like a recruit.
func _member_mods(spec_id: String, tal: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var mods := {}
	if not TALENTS:
		return mods
	for id in tal:
		SpecTalents.add_effects(mods, SpecTalents.find(spec_id, id)[5], tal[id])
	var pool: Array = SpecTalents.TRAITS[ClassData.SPECS[spec_id]["role"]]
	var a := rng.randi() % pool.size()
	var b := (a + 1 + rng.randi() % (pool.size() - 1)) % pool.size()
	SpecTalents.add_effects(mods, pool[a][1])
	SpecTalents.add_effects(mods, pool[b][1])
	return mods


func _talent_values() -> void:
	print("\nspec                    full tree power   (talents only, 36 points)")
	for sid in SpecTalents.TREES:
		var mods := {}
		var tal := SpecTalents.auto_build(sid, {}, 60)
		for id in tal:
			SpecTalents.add_effects(mods, SpecTalents.find(sid, id)[5], tal[id])
		var ranks := 0
		for t in SpecTalents.tree(sid):
			ranks += t[4]
		var abilities := SpecTalents.abilities_for(sid, tal, mods)
		var names := abilities.map(func(a): return a["name"])
		print("%-22s  %+5.1f%% %+5.1f%%  share %.2f  (%d ranks) %s" % [sid, 100.0 * SpecTalents.power_value(mods),
			100.0 * SpecTalents.ability_value(abilities), SpecTalents.damage_share(abilities), ranks, ", ".join(names)])


func _tier_odds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	print("\nhall | mean  P(>=B)  P(>=A)  P(>=S)  P(>=SS)  P(SSS+)")
	for h in range(1, 11):
		var counts := {}
		var total := 20000
		for i in total:
			var t := Tiers.roll(h, rng)
			counts[t] = counts.get(t, 0) + 1
		var mean := 0.0
		for k in counts:
			mean += k * counts[k]
		print(" %2d  | %4s  %5.1f%%  %5.1f%%  %5.2f%%  %5.2f%%  %5.2f%%" % [h, Tiers.name_of(int(round(mean / total))),
			_ge(counts, 8, total), _ge(counts, 10, total), _ge(counts, 12, total), _ge(counts, 14, total), _ge(counts, 17, total)])


func _ge(counts: Dictionary, x: int, total: int) -> float:
	var s := 0
	for k in counts:
		if k >= x:
			s += counts[k]
	return 100.0 * s / total


func _economy() -> void:
	print("\nlevel | income/fight  cum.fights  cum.hours  cum.gold  hall cost (unlocks here)")
	var fights := 0.0
	var gold := 0.0
	for l in range(1, 61):
		var f := Balance.fights_per_level(l) / 1.2
		if l == 60:
			f = 0.0
		fights += f
		gold += f * Balance.income(l) * 1.9
		var hc := ""
		for h in range(2, 11):
			if Balance.HALL_LEVEL_REQ[h] == l:
				hc = "hall %d: %s" % [h, Balance.money(Balance.hall_cost(h))]
		if l % 6 == 0 or hc != "" or l == 1:
			print(" %2d   | %10s  %8.0f  %8.1f  %10s  %s" % [l, Balance.money(Balance.income(l)), fights, fights * 65.0 / 3600.0, Balance.money(int(gold)), hc])


## How long the prestige ladder takes. A level-60 guild of nine grade-A guildmates (the recruitment
## cap) farms the best raid its grades allow (as in the raid rows above), and trains its lowest
## guildmate whenever its prestige allows. Gear is assumed to keep up with the grades.
func _prestige() -> void:
	const SEC_PER_KILL := 190.0  # ~2 min fights, the time between them, and the odd wipe
	const PLAY_SHARE := 0.85  # the rest of the time goes to dungeons, missions and Orgrimmar
	var need := {"zg": Tiers.A, "mc": Tiers.A, "ony": Tiers.A, "bwl": 13, "aq40": 15, "naxx": 17}
	var tiers := []
	for i in 9:
		tiers.append(Tiers.A)
	var points := 0.0
	var total := 0.0
	var hours := 0.0
	var dt := 0.05
	var next_print := 5.0
	var reached := {}
	var goals := {"#10": Prestige.rival_score(9), "#5": Prestige.rival_score(4), "#2": Prestige.rival_score(1), "#1": Prestige.TOP + 1}
	print("\nprestige model: %.0f s per boss kill, %d%% of play time raiding" % [SEC_PER_KILL, int(PLAY_SHARE * 100)])
	print("hours | raid  team grades       earned  rank")
	while hours < 80.0:
		var mean := 0.0
		for t in tiers:
			mean += t / 9.0
		var best := ""
		var rate := 0.0
		for r in Raids.LIST:
			if mean + 0.01 >= need[r["id"]]:
				var per_hour: float = Prestige.for_clear(r) / float(r["bosses"].size()) * 3600.0 / SEC_PER_KILL * PLAY_SHARE
				if per_hour > rate:
					rate = per_hour
					best = r["id"]
		points += rate * dt
		total += rate * dt
		hours += dt
		while true:
			var low := 0
			for i in tiers.size():
				if tiers[i] < tiers[low]:
					low = i
			var cost := Tiers.train_prestige(tiers[low])
			if Tiers.is_max(tiers[low]) or points < cost:
				break
			points -= cost
			tiers[low] += 1
		for g in goals:
			if not reached.has(g) and total >= goals[g]:
				reached[g] = hours
		if hours >= next_print:
			next_print += 5.0
			print(" %4.0f | %-5s %-18s %6.0f  #%d" % [hours, best, Tiers.name_of(int(floor(mean))) + " to " + Tiers.name_of(tiers.max()),
				total, Prestige.rank(int(total))])
	for g in goals:
		print("rank %s (%d prestige) after %.1f hours" % [g, goals[g], reached.get(g, -1.0)])
