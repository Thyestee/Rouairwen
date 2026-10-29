extends Node
## The whole saved game: the priest, the Lumens guild, its bank, gold and progress.
## Autoloaded as "Game".

signal changed
signal toast(text: String)
signal leveled(level: int)

var save_path := "user://lumens_save.txt"
## The guild leader is always Thyeste, an Undead priest.
const PRIEST_NAME := "Thyeste"
const PRIEST_RACE := "undead"
const MAX_GUILD := 10
const BANK_SIZE := 120
const QUEST_BOARD := 6
const RECRUIT_BOARD := 3
## Version 2: talent trees with abilities (guildmates from older saves get the recommended build).
const TALENT_VERSION := 2

var data := {}
var rng := RandomNumberGenerator.new()
var run := {}
var _play_accum := 0.0
var _weights_cache := {}


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if not data.is_empty():
		_play_accum += delta
		if _play_accum >= 1.0:
			data["stats"]["playtime"] += int(_play_accum)
			_play_accum -= int(_play_accum)
			_check_missions()


# ---------------------------------------------------------------- save / load

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save() -> void:
	if data.is_empty():
		return
	data["next_uid"] = Items._next_uid
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(data))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return false
	var v = str_to_var(f.get_as_text())
	if typeof(v) != TYPE_DICTIONARY or not v.has("priest"):
		return false
	data = v
	Items.set_next_uid(data.get("next_uid", 1))
	run = {}
	_migrate()
	changed.emit()
	return true


## Brings older saves up to date with the current rules.
func _migrate() -> void:
	# The priest is the guild's only healer: healers retrain, priests leave.
	for m in data["members"].duplicate():
		if not ClassData.RETIRED_SPECS.has(m["spec"]):
			continue
		var to: String = ClassData.RETIRED_SPECS[m["spec"]]
		if to == "":
			for slot in m["gear"]:
				_bank_add(m["gear"][slot])
			data["members"].erase(m)
			add_log("%s leaves <Lumens>: the guild only needs one healer." % m["name"])
		else:
			m["spec"] = to
			add_log("%s retrains as %s %s." % [m["name"], ClassData.SPECS[to]["name"], ClassData.class_name_of(m["class"])])
	# Guildmates from before traits and talents: 2 spec traits (no affixes) and the recommended build.
	for m in data["members"]:
		if not m.has("traits"):
			m["traits"] = roll_traits(m["spec"])
			m["affixes"] = []
		if not m.has("talents"):
			m["talents"] = {}
			m["auto_talents"] = true
		# Talents from the trees before abilities don't exist anymore: start over in the recommended build.
		if m.get("talent_version", 1) < TALENT_VERSION:
			m["talents"] = {}
			m["auto_talents"] = true
			m["talent_version"] = TALENT_VERSION
		if m.get("auto_talents", true):
			m["talents"] = SpecTalents.auto_build(m["spec"], m["talents"], level())
		# Traits and affixes take their current effects (Stamina instead of health, for instance).
		var role: String = ClassData.SPECS[m["spec"]]["role"]
		for tr in m["traits"]:
			tr[1] = _current_effects(tr, SpecTalents.TRAITS[role])
		for af in m["affixes"]:
			af[1] = _current_effects(af, SpecTalents.AFFIXES_GOOD + SpecTalents.AFFIXES_BAD)
		# Guildmates already at B or better get their grade perk (grades past A from before the cap stay).
		_grade_perk(m)
	# Missions posted before their rewards changed (set experience, surprise spoils) are posted again.
	if data.has("missions") and data["missions"]["board"].any(func(mi): return not mi["rewards"].has("xp")):
		data["missions"]["board"].clear()
	# Prestige arrived after raids: past clears count, so veteran guilds start on the ladder.
	if not data.has("prestige"):
		data["prestige"] = {"points": 0, "total": 0}
		var earned := 0
		for rid in data["raid_clears"]:
			earned += Prestige.for_clear(Raids.by_id(rid)) * data["raid_clears"][rid]
		if earned > 0:
			add_prestige(earned)
			add_log("<Lumens>' past raid clears earn %d prestige." % earned)
	for c in data["recruits"]:
		if not ClassData.SPECS.has(c["spec"]) or not c.has("traits") or c["tier"] > Tiers.RECRUIT_MAX:
			refresh_recruits(false)
			break
	# Quests from before random rewards and role guarantees; then top the board up (6 quests, one easy).
	for q in data["quests"]:
		if not q["rewards"].has("gold_min") or not q.has("guaranteed"):
			refresh_quests(true)
			break
	refresh_quests()
	save()


func _current_effects(entry: Array, pool: Array) -> Dictionary:
	for p in pool:
		if p[0] == entry[0]:
			return p[1].duplicate()
	return entry[1]


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func new_game() -> void:
	Items._next_uid = 1
	data = {
		"version": 1,
		"priest": {"name": PRIEST_NAME, "race": PRIEST_RACE, "level": 1, "xp": 0, "talents": {}, "respecs": 0, "gear": {}},
		"gold": 250,
		"hall": 1,
		"members": [],
		"bank": [],
		"consumables": {"mana_potion:0": 3, "healing_potion:0": 3},
		"use": {"mana_potion": true, "healing_potion": true, "battle_elixir": true, "guardian_elixir": true, "priest_elixir": true, "food": true},
		"quests": [],
		"recruits": [],
		"raid_progress": {},
		"raid_clears": {},
		"dungeon_clears": {},
		"world_buff": {},
		"stats": {"playtime": 0, "fights": 0, "wipes": 0, "quests": 0, "dungeons": 0, "raids": 0, "best_tier": 2, "recruited": 0},
		"prestige": {"points": 0, "total": 0},
		"log": [],
	}
	var p: Dictionary = data["priest"]
	p["gear"]["chest"] = Items.make("Apprentice's Robe", "chest", "common", 1, "healing", "cloth")
	p["gear"]["weapon"] = Items.make("Bent Staff", "weapon", "common", 1, "healing", "staff")
	p["gear"]["feet"] = Items.make("Apprentice's Boots", "feet", "common", 1, "healing", "cloth")
	var nd := _new_member("Nightdude", "orc", "shaman_enhancement", 2, false)
	nd["founder"] = true
	nd["gear"]["chest"] = Items.make("Novice's Vest", "chest", "common", 1, "physical", "leather")
	nd["gear"]["weapon"] = Items.make("Worn Axe", "weapon", "common", 1, "physical", "axe")
	nd["gear"]["legs"] = Items.make("Novice's Pants", "legs", "common", 1, "physical", "leather")
	var rk := _new_member("Raynkoy", "tauren", "warrior_fury", 2, false)
	rk["founder"] = true
	rk["gear"]["chest"] = Items.make("Recruit's Vest", "chest", "common", 1, "physical", "mail")
	rk["gear"]["weapon"] = Items.make("Worn Mace", "weapon", "common", 1, "physical", "mace")
	rk["gear"]["legs"] = Items.make("Recruit's Pants", "legs", "common", 1, "physical", "mail")
	data["members"] = [nd, rk]
	refresh_quests(true)
	refresh_recruits(false)
	add_log("%s founds the guild <Lumens> in Orgrimmar, with Nightdude and Raynkoy at his side." % PRIEST_NAME)
	save()
	changed.emit()


## A guildmate with 2 spec traits and, for recruits, up to 2 random affixes (good or bad).
func _new_member(mname: String, race: String, spec_id: String, tier: int, with_affixes := true) -> Dictionary:
	var m := {"id": Items.new_uid(), "name": mname, "race": race, "spec": spec_id, "class": ClassData.class_of(spec_id),
		"tier": tier, "gear": {}, "founder": false, "talents": {}, "auto_talents": true, "talent_version": TALENT_VERSION,
		"traits": roll_traits(spec_id), "affixes": roll_affixes(spec_id, tier) if with_affixes else []}
	m["talents"] = SpecTalents.auto_build(spec_id, {}, level() if not data.is_empty() else 1)
	_grade_perk(m)
	return m


func roll_traits(spec_id: String) -> Array:
	var role: String = ClassData.SPECS[spec_id]["role"]
	var pool: Array = SpecTalents.TRAITS[role].duplicate()
	pool.shuffle()
	return [pool[0].duplicate(true), pool[1].duplicate(true)]


## Up to 2 affixes that suit the spec. The better the grade, the likelier each is good: 45% at F,
## 85% at A.
func roll_affixes(spec_id: String, tier: int) -> Array:
	var r := rng.randf()
	var n := 0 if r < 0.35 else (1 if r < 0.8 else 2)
	var good := SpecTalents.AFFIXES_GOOD.filter(func(a): return SpecTalents.affix_fits(a, spec_id))
	var bad := SpecTalents.AFFIXES_BAD.filter(func(a): return SpecTalents.affix_fits(a, spec_id))
	var out := []
	var used := []
	while out.size() < n:
		var pool: Array = good if rng.randf() < 0.45 + 0.04 * tier else bad
		var a: Array = pool[rng.randi() % pool.size()]
		if not (a[0] in used):
			used.append(a[0])
			out.append(a.duplicate(true))
	return out


func add_log(text: String) -> void:
	var lg: Array = data["log"]
	lg.push_front(text)
	if lg.size() > 40:
		lg.resize(40)


# ---------------------------------------------------------------- accessors

func level() -> int:
	return data["priest"]["level"]


func gold() -> int:
	return data["gold"]


func priest() -> Dictionary:
	return data["priest"]


func members() -> Array:
	return data["members"]


func member(id) -> Dictionary:
	if typeof(id) == TYPE_STRING and id == "priest":
		return data["priest"]
	for m in data["members"]:
		if m["id"] == id:
			return m
	return {}


func is_priest(m: Dictionary) -> bool:
	return m.has("respecs")


func member_class(m: Dictionary) -> String:
	return "priest" if is_priest(m) else m["class"]


func member_stat(m: Dictionary) -> String:
	return "healing" if is_priest(m) else ClassData.SPECS[m["spec"]]["stat"]


## How a character fights, for stats: "priest", "tank", "spell" or "physical".
func member_kind(m: Dictionary) -> String:
	if is_priest(m):
		return "priest"
	var sp: Dictionary = ClassData.SPECS[m["spec"]]
	if sp["role"] == "tank":
		return "tank"
	return "spell" if sp["stat"] == "spell" else "physical"


## Every stat of a character (Stats.compute): base, grade, gear and talent percentages, plus derived values.
func member_stats(m: Dictionary) -> Dictionary:
	return Stats.compute(member_class(m), member_kind(m), level(), m["gear"], member_mods(m), grade_stats(m))


## What a guildmate's grade adds to their stats at the guild's level (nothing for Thyeste), with
## Gifted or Stunted affixes ("grade%") applied.
func grade_stats(m: Dictionary, tier := -1) -> Dictionary:
	if is_priest(m):
		return {}
	var out := Tiers.stats(m["spec"], m["tier"] if tier < 0 else tier, level())
	var pct: float = member_mods(m).get("grade%", 0.0)
	if pct != 0.0:
		for k in out:
			out[k] *= 1.0 + pct / 100.0
	return out


## How much stronger gear makes a character than naked: damage for guildmates, healing for Thyeste.
func gear_bonus(m: Dictionary) -> float:
	var mods := member_mods(m)
	var worn := Stats.compute(member_class(m), member_kind(m), level(), m["gear"], mods, grade_stats(m))
	if is_priest(m):
		return worn["heal_mult"] - 1.0
	var naked := Stats.compute(member_class(m), member_kind(m), level(), {}, mods, grade_stats(m))
	return worn["offense"] / naked["offense"] - 1.0


## A guildmate's power: the damage their stats give (grade and gear), times what their talents,
## abilities, traits and affixes are worth. 1.0 is an F grade naked. Thyeste's power is her healing
## multiplier.
func member_power(m: Dictionary) -> float:
	if is_priest(m):
		return member_stats(m)["heal_mult"]
	return core_power(m) * (1.0 + SpecTalents.power_value(member_mods(m)) + SpecTalents.ability_value(member_abilities(m)))


## The damage their stats give, grade included: what a guildmate's damage scales with.
func core_power(m: Dictionary) -> float:
	return member_stats(m)["offense"]


## All effects on a guildmate: talents, traits, affixes and the grade B perk.
func member_mods(m: Dictionary) -> Dictionary:
	var mods := {}
	if is_priest(m):
		return mods
	var tal: Dictionary = m.get("talents", {})
	for id in tal:
		var t := SpecTalents.find(m["spec"], id)
		if not t.is_empty():
			SpecTalents.add_effects(mods, t[5], tal[id])
	for tr in m.get("traits", []) + m.get("affixes", []) + ([m["grade_perk"]] if m.has("grade_perk") else []):
		SpecTalents.add_effects(mods, tr[1])
	return mods


func member_talent_points_free(m: Dictionary) -> int:
	return SpecTalents.points_at(level()) - SpecTalents.spent(m.get("talents", {}))


func learn_member_talent(m: Dictionary, id: String) -> void:
	if not SpecTalents.can_learn(m["spec"], m.get("talents", {}), id, level()):
		return
	m["talents"][id] = m["talents"].get(id, 0) + 1
	m["auto_talents"] = false
	save()
	changed.emit()


func reset_member_talents(m: Dictionary) -> void:
	m["talents"] = {}
	m["auto_talents"] = false
	save()
	changed.emit()


## Re-specs a guildmate into the recommended build and keeps it filled as they level.
func auto_member_talents(m: Dictionary) -> void:
	m["talents"] = SpecTalents.auto_build(m["spec"], {}, level())
	m["auto_talents"] = true
	save()
	changed.emit()


func guild_full() -> bool:
	return data["members"].size() >= MAX_GUILD - 1


func xp_needed() -> int:
	return Balance.xp_to_next(level())


func talent_points_free() -> int:
	return Balance.talent_points_at(level()) - Talents.spent(data["priest"]["talents"])


func hall() -> int:
	return data["hall"]


# ---------------------------------------------------------------- gold

func add_gold(c: int) -> void:
	data["gold"] += c


func spend(c: int) -> bool:
	if data["gold"] < c:
		toast.emit("You don't have enough gold.")
		return false
	data["gold"] -= c
	return true


# ---------------------------------------------------------------- prestige & training

## Prestige to spend on training.
func prestige() -> int:
	return data["prestige"]["points"]


## Every point of prestige ever earned: the guild's score on the ladder.
func prestige_total() -> int:
	return data["prestige"]["total"]


func add_prestige(n: int) -> void:
	data["prestige"]["points"] += n
	data["prestige"]["total"] += n


## Why a guildmate can't train to the next grade right now, or "".
func train_block(m: Dictionary) -> String:
	if Tiers.is_max(m["tier"]):
		return "Already %s, the highest grade." % Tiers.name_of(m["tier"])
	if gold() < Tiers.train_gold(level(), m["tier"]):
		return "Not enough gold."
	if prestige() < Tiers.train_prestige(m["tier"]):
		return "Not enough prestige: raid bosses grant it."
	return ""


## Trains a guildmate one grade up, for gold (and prestige past A).
func train(m: Dictionary) -> void:
	var why := train_block(m)
	if why != "":
		toast.emit(why)
		return
	data["gold"] -= Tiers.train_gold(level(), m["tier"])
	data["prestige"]["points"] -= Tiers.train_prestige(m["tier"])
	m["tier"] += 1
	_grade_perk(m)
	data["stats"]["best_tier"] = maxi(data["stats"]["best_tier"], m["tier"])
	var unlocked := ""
	match Tiers.unlock_at(m["tier"]):
		"perk":
			unlocked = ": %s" % m["grade_perk"][0]
		"class":
			unlocked = " and learns %s" % SpecTalents.ABILITIES[SpecTalents.CLASS_SPELLS[m["class"]]]["name"]
		"race":
			unlocked = " and learns %s" % SpecTalents.ABILITIES[SpecTalents.RACE_SPELLS[m["race"]]]["name"]
	add_log("%s trains to grade %s%s." % [m["name"], Tiers.name_of(m["tier"]), unlocked])
	toast.emit("%s reaches grade %s%s!" % [m["name"], Tiers.name_of(m["tier"]), unlocked])
	save()
	changed.emit()


## Guildmates of grade B or better get their B perk (crit or damage, at random) once.
func _grade_perk(m: Dictionary) -> void:
	if m["tier"] >= Tiers.B and not m.has("grade_perk"):
		m["grade_perk"] = Tiers.B_PERKS[rng.randi() % Tiers.B_PERKS.size()].duplicate(true)


# ---------------------------------------------------------------- quests

## Fills the quest board, always keeping one quest whose recommended power is below Thyeste's own.
func refresh_quests(full := false) -> void:
	var board: Array = data["quests"]
	if full:
		board.clear()
	if not board.any(is_easy_quest):
		if board.size() >= QUEST_BOARD:
			board.pop_back()
		board.push_front(_make_easy_quest())
	while board.size() < QUEST_BOARD:
		board.append(Activities.make_quest(level(), rng))


func is_easy_quest(q: Dictionary) -> bool:
	return recommended_power(q) < int(round(100.0 * member_power(data["priest"])))


func _make_easy_quest() -> Dictionary:
	# Recommended power is 112% of the difficulty, so keep it comfortably under Thyeste's power.
	var diff := minf(0.8, 0.9 * member_power(data["priest"]) / (1.12 * recommended_talent_factor(maxi(1, level() - 1))))
	return Activities.make_quest(level(), rng, true, diff)


func reroll_quest_cost() -> int:
	return int(Balance.income(level()) * 0.5) + 1


func reroll_quests() -> void:
	if spend(reroll_quest_cost()):
		refresh_quests(true)
		save()
		changed.emit()


# ---------------------------------------------------------------- recruitment

func make_candidate() -> Dictionary:
	var spec_id := ClassData.random_spec(rng)
	var cls := ClassData.class_of(spec_id)
	var race := Names.race_for(cls, rng)
	var tier := Tiers.roll(hall(), rng)
	var c := _new_member(Names.make(race, rng), race, spec_id, tier)
	# Recruits show up wearing level-appropriate greens in a few slots.
	var stat: String = ClassData.SPECS[spec_id]["stat"]
	for slot in ["chest", "legs", "weapon"]:
		var it := Items.random_item(maxi(1, level() - 2), "uncommon" if level() > 5 else "common", rng, stat, slot)
		var tries := 0
		while not Items.can_use(it, cls) and tries < 12:
			it = Items.random_item(maxi(1, level() - 2), "uncommon" if level() > 5 else "common", rng, stat, slot)
			tries += 1
		if Items.can_use(it, cls):
			c["gear"][slot] = it
	c["cost"] = Balance.recruit_hire_cost(level(), tier)
	return c


func refresh_recruits(paid: bool) -> void:
	if paid and not spend(Balance.recruit_refresh_cost(level())):
		return
	var board: Array = data["recruits"]
	board.clear()
	for i in RECRUIT_BOARD:
		board.append(make_candidate())
	if paid:
		save()
		changed.emit()


func hire(index: int) -> void:
	var board: Array = data["recruits"]
	if index < 0 or index >= board.size():
		return
	if guild_full():
		toast.emit("The guild is full (%d members). Dismiss someone first." % MAX_GUILD)
		return
	var c: Dictionary = board[index]
	if not spend(c["cost"]):
		return
	c.erase("cost")
	data["members"].append(c)
	board.remove_at(index)
	data["stats"]["recruited"] += 1
	data["stats"]["best_tier"] = maxi(data["stats"]["best_tier"], c["tier"])
	add_log("%s (%s %s, grade %s) joins <Lumens>." % [c["name"], ClassData.SPECS[c["spec"]]["name"], ClassData.class_name_of(c["class"]), Tiers.name_of(c["tier"])])
	toast.emit("%s joins the guild!" % c["name"])
	save()
	changed.emit()


func dismiss(id: int) -> void:
	var m := member(id)
	if m.is_empty():
		return
	if is_busy(m):
		toast.emit("%s is away on a mission." % m["name"])
		return
	for slot in m["gear"]:
		_bank_add(m["gear"][slot])
	m["gear"] = {}
	data["members"].erase(m)
	add_log("%s leaves the guild." % m["name"])
	toast.emit("%s leaves the guild. Their gear went to the guild bank." % m["name"])
	save()
	changed.emit()


# ---------------------------------------------------------------- guild missions

func missions() -> Dictionary:
	if not data.has("missions"):
		data["missions"] = {"board": [], "active": []}
	var ms: Dictionary = data["missions"]
	while ms["board"].size() < Missions.BOARD_SIZE:
		ms["board"].append(Missions.make(level(), rng, recommended_talent_factor(level())))
	return ms


func busy_ids() -> Array:
	var out := []
	for a in missions()["active"]:
		out.append_array(a["members"])
	return out


func is_busy(m: Dictionary) -> bool:
	return not is_priest(m) and m["id"] in busy_ids()


func mission_team(ids: Array) -> Array:
	var team := []
	for id in ids:
		var m := member(id)
		if not m.is_empty():
			team.append(m)
	return team


## {ratio, bonus, effective, chance, counters: {threat: name}} for a team on a mission.
func mission_odds(mission: Dictionary, ids: Array) -> Dictionary:
	var team := mission_team(ids)
	var cmap := Missions.counter_map(mission, team, member_mods)
	var countered := 0
	for th in cmap:
		if cmap[th] != "":
			countered += 1
	var powers := team.map(func(m): return member_power(m))
	var o := Missions.odds(mission, powers, countered)
	o["counters"] = cmap
	return o


func start_mission(index: int, ids: Array) -> void:
	var ms := missions()
	if ms["active"].size() >= Missions.MAX_ACTIVE:
		toast.emit("The War Table can follow %d missions at once." % Missions.MAX_ACTIVE)
		return
	var mission: Dictionary = ms["board"][index]
	if ids.is_empty() or ids.size() > mission["slots"] or ids.any(func(id): return id in busy_ids()):
		return
	var odds := mission_odds(mission, ids)
	ms["active"].append({"mission": mission, "members": ids, "end": Missions.now() + mission["minutes"] * 60.0,
		"chance": odds["chance"], "notified": false})
	ms["board"].remove_at(index)
	add_log("%s set out on a mission: %s." % [", ".join(mission_team(ids).map(func(m): return m["name"])), mission["title"]])
	save()
	changed.emit()


func reroll_missions_cost() -> int:
	return int(Balance.income(level()) * 1.0) + 1


func reroll_missions() -> void:
	if spend(reroll_missions_cost()):
		missions()["board"].clear()
		missions()
		save()
		changed.emit()


## Rolls a finished mission's outcome and grants its rewards. Returns {success, xp, gold, items, levels}.
func collect_mission(index: int) -> Dictionary:
	var ms := missions()
	var a: Dictionary = ms["active"][index]
	if Missions.time_left(a) > 0.0:
		return {}
	ms["active"].remove_at(index)
	var mission: Dictionary = a["mission"]
	var rw: Dictionary = mission["rewards"]
	var success: bool = rng.randf() < a["chance"]
	var res := {"success": success, "xp": 0, "gold": 0, "items": [], "levels": 0, "title": mission["title"]}
	if success:
		# The spoils are rolled now: gold, gear or both
		var sp := Missions.spoils(mission, rng)
		var items := []
		for i in sp.get("items", 0) * Settings.boost_rate():
			var q := "uncommon"
			var r := rng.randf()
			if r < sp["epic_chance"]:
				q = "epic"
			elif r < sp["epic_chance"] + sp["rare_chance"]:
				q = "rare"
			var team := mission_team(a["members"])
			var profile: String = member_stat(team[rng.randi() % team.size()]) if not team.is_empty() else ""
			items.append(wearable_item(rng.randi_range(sp["ilvl_min"], sp["ilvl_max"]), q, profile))
		# Missions from before the rework promised an experience range
		var xp: int = rw.get("xp", rng.randi_range(rw["xp_min"], rw["xp_max"]) if rw.has("xp_min") else 0)
		var granted := _grant(xp, sp.get("gold", 0), items)
		res.merge(granted, true)
		data["stats"]["missions"] = data["stats"].get("missions", 0) + 1
		add_log("Mission complete: %s." % mission["title"])
	else:
		add_log("Mission failed: %s." % mission["title"])
	missions()
	save()
	changed.emit()
	return res


func _check_missions() -> void:
	if not data.has("missions"):
		return
	for a in data["missions"]["active"]:
		if not a["notified"] and Missions.time_left(a) <= 0.0:
			a["notified"] = true
			toast.emit("Mission complete: %s. Collect it at the War Table." % a["mission"]["title"])


# ---------------------------------------------------------------- guild hall

func can_upgrade_hall() -> String:
	if hall() >= Balance.HALL_MAX:
		return "The guild hall is fully upgraded."
	var req: int = Balance.HALL_LEVEL_REQ[hall() + 1]
	if level() < req:
		return "Requires level %d." % req
	return ""


func upgrade_hall() -> void:
	if can_upgrade_hall() != "":
		return
	if not spend(Balance.hall_cost(hall() + 1)):
		return
	data["hall"] += 1
	add_log("The guild moves into the %s." % Balance.HALL_NAMES[hall()])
	toast.emit("Guild hall upgraded: %s!" % Balance.HALL_NAMES[hall()])
	refresh_recruits(false)
	save()
	changed.emit()


# ---------------------------------------------------------------- shop

func stock_key(cat: String, rank: int) -> String:
	return "%s:%d" % [cat, rank]


func stock(cat: String) -> int:
	var n := 0
	for k in data["consumables"]:
		if String(k).begins_with(cat + ":"):
			n += data["consumables"][k]
	return n


func best_stock_rank(cat: String) -> int:
	var best := -1
	for k in data["consumables"]:
		if String(k).begins_with(cat + ":") and data["consumables"][k] > 0:
			best = maxi(best, int(String(k).get_slice(":", 1)))
	return best


func buy(cat: String, qty: int) -> void:
	var rank := ShopData.best_rank(cat, level())
	if rank < 0:
		return
	if not spend(ShopData.price(cat, rank) * qty):
		return
	var key := stock_key(cat, rank)
	data["consumables"][key] = data["consumables"].get(key, 0) + qty
	save()
	changed.emit()


func _take(cat: String) -> int:
	var rank := best_stock_rank(cat)
	if rank < 0:
		return -1
	var key := stock_key(cat, rank)
	data["consumables"][key] -= 1
	if data["consumables"][key] <= 0:
		data["consumables"].erase(key)
	return rank


# ---------------------------------------------------------------- items

## Puts an item in the guild bank; a full bank sells it instead. Returns what it sold for (0 when
## banked). `quiet` leaves the toast to the caller, for rewards with many pieces.
func _bank_add(item: Dictionary, quiet := false) -> int:
	if item.is_empty():
		return 0
	var bank: Array = data["bank"]
	if bank.size() >= BANK_SIZE:
		var c := Items.sell_price(item)
		add_gold(c)
		if not quiet:
			toast.emit("Guild bank full: %s was sold for %s." % [item["name"], Balance.money(c)])
		return c
	bank.append(item)
	return 0


func bank_item(uid: int) -> Dictionary:
	for it in data["bank"]:
		if it["uid"] == uid:
			return it
	return {}


func equip(m: Dictionary, uid: int) -> void:
	var it := bank_item(uid)
	if it.is_empty() or not Items.can_use(it, member_class(m)):
		return
	data["bank"].erase(it)
	var slot: String = it["slot"]
	if m["gear"].has(slot):
		_bank_add(m["gear"][slot])
	m["gear"][slot] = it
	save()
	changed.emit()


func unequip(m: Dictionary, slot: String) -> void:
	if not m["gear"].has(slot):
		return
	_bank_add(m["gear"][slot])
	m["gear"].erase(slot)
	save()
	changed.emit()


func sell(uid: int) -> void:
	var it := bank_item(uid)
	if it.is_empty():
		return
	data["bank"].erase(it)
	add_gold(Items.sell_price(it))
	save()
	changed.emit()


## What an item's stats are worth to a character (-1 if they can't wear it), from WoW-style stat weights.
func item_value_for(m: Dictionary, it: Dictionary) -> float:
	if not Items.can_use(it, member_class(m)):
		return -1.0
	return Stats.item_value(it, stat_weights(m))


func stat_weights(m: Dictionary) -> Dictionary:
	var key := "%s|%s|%d" % [member_class(m), member_kind(m), level()]
	if not _weights_cache.has(key):
		_weights_cache[key] = Stats.weights(member_class(m), member_kind(m), level())
	return _weights_cache[key]


## How much an item would improve a member (0 if it doesn't).
func upgrade_amount(m: Dictionary, it: Dictionary) -> float:
	var v := item_value_for(m, it)
	if v < 0.0:
		return 0.0
	var cur: Dictionary = m["gear"].get(it["slot"], {})
	return maxf(0.0, v - item_value_for(m, cur) if not cur.is_empty() else v)


## Who in the guild benefits most from an item: [member, gain].
func best_wearer(it: Dictionary) -> Array:
	var best = null
	var gain := 0.0
	for m in [data["priest"]] + data["members"]:
		var g := upgrade_amount(m, it)
		if is_priest(m):
			g *= 1.6
		if g > gain + 0.0001:
			gain = g
			best = m
	return [best, gain]


func auto_equip(m: Dictionary) -> int:
	var changes := 0
	for slot in Items.SLOTS:
		var best := {}
		var best_v := item_value_for(m, m["gear"].get(slot, {})) if m["gear"].has(slot) else 0.0
		for it in data["bank"]:
			if it["slot"] != slot:
				continue
			var v := item_value_for(m, it)
			if v > best_v + 0.00001:
				best_v = v
				best = it
		if not best.is_empty():
			data["bank"].erase(best)
			if m["gear"].has(slot):
				_bank_add(m["gear"][slot])
			m["gear"][slot] = best
			changes += 1
	return changes


## Equips the priest first, then guildmates from the strongest grade down.
func auto_equip_all() -> void:
	var n := auto_equip(data["priest"])
	var ms: Array = data["members"].duplicate()
	ms.sort_custom(func(a, b): return a["tier"] > b["tier"])
	for m in ms:
		n += auto_equip(m)
	toast.emit("Equipped %d upgrade%s." % [n, "" if n == 1 else "s"] if n > 0 else "No upgrades in the bank.")
	save()
	changed.emit()


## Sells every bank item that is no upgrade for anyone.
func sell_obsolete() -> void:
	var total := 0
	var count := 0
	for it in data["bank"].duplicate():
		if best_wearer(it)[0] == null:
			data["bank"].erase(it)
			total += Items.sell_price(it)
			count += 1
	add_gold(total)
	toast.emit("Sold %d item%s for %s." % [count, "" if count == 1 else "s", Balance.money(total)] if count > 0 else "Nothing to sell.")
	save()
	changed.emit()


# ---------------------------------------------------------------- talents

func learn(id: String) -> void:
	var t: Dictionary = data["priest"]["talents"]
	if not Talents.can_learn(t, id, level()):
		return
	t[id] = t.get(id, 0) + 1
	save()
	changed.emit()


func respec() -> void:
	if Talents.spent(data["priest"]["talents"]) == 0:
		return
	if not spend(Balance.respec_cost(level(), data["priest"]["respecs"])):
		return
	data["priest"]["talents"] = {}
	data["priest"]["respecs"] += 1
	save()
	changed.emit()


# ---------------------------------------------------------------- action bar

## Thyeste's spells in action bar order: the order set in the spellbook, then spells learned since
## at the end (all in the default order until the bar is rearranged). Slot i is cast with the key
## bound to Settings.slot_action(i).
func action_bar() -> Array:
	var known := Spells.known(level(), data["priest"]["talents"])
	var out := []
	for id in data["priest"].get("bar", []):
		if id in known:
			out.append(id)
	for id in known:
		if not (id in out):
			out.append(id)
	return out


## Moves a spell to another action bar slot; the spells in between shift over.
func move_spell(id: String, to: int) -> void:
	var bar := action_bar()
	if not (id in bar):
		return
	bar.erase(id)
	bar.insert(clampi(to, 0, bar.size()), id)
	data["priest"]["bar"] = bar
	save()
	changed.emit()


func reset_action_bar() -> void:
	data["priest"].erase("bar")
	save()
	changed.emit()


# ---------------------------------------------------------------- unlocks

func dungeon_unlocked(d: Dictionary) -> bool:
	return level() >= d["min"]


func raid_unlocked(r: Dictionary) -> String:
	if level() < Balance.MAX_LEVEL:
		return "Requires level 60."
	var req: String = r.get("requires", "")
	if req != "" and data["raid_clears"].get(req, 0) <= 0:
		return "Requires clearing %s." % Raids.by_id(req)["name"]
	return ""


func raid_killed(rid: String) -> Array:
	return data["raid_progress"].get(rid, [])


# ---------------------------------------------------------------- combat specs

## Active buffs for a run: {category: value%}.
func _buff_value(buffs: Dictionary, cat: String) -> float:
	return buffs.get(cat, 0.0) / 100.0


## Combat numbers for a guildmate. Health, damage, damage taken and threat get their talent/trait/affix
## effects here; the rest of the effects go to the engine in "mods".
func member_combat_spec(m: Dictionary, buffs: Dictionary) -> Dictionary:
	return CombatEngine.member_spec(m["name"], m["spec"], member_stats(m), member_mods(m),
		member_abilities(m), level(), _buff_value(buffs, "battle_elixir") + _buff_value(buffs, "world"),
		_buff_value(buffs, "guardian_elixir"))


## Thyeste's combat numbers: Stamina for health, Intellect for mana and crit, Spirit for regeneration,
## healing power (Healing and Spell Damage) for heals.
func priest_combat_spec(buffs: Dictionary) -> Dictionary:
	var p: Dictionary = data["priest"]
	var st := member_stats(p)
	var u := Balance.scale(level())
	var wis := _buff_value(buffs, "priest_elixir")
	return {
		"name": p["name"], "talents": p["talents"], "known": action_bar(),
		"max_hp": 100.0 * u * st["health_mult"] * (1.0 + _buff_value(buffs, "guardian_elixir")),
		"max_mana": 300.0 * u * st["mana_mult"] * (1.0 + wis),
		"regen": 6.0 * u * st["regen_mult"] * (1.0 + _buff_value(buffs, "food")),
		"heal_power": st["heal_power"],
		"heal_mult": (1.0 + wis * 0.5) * (1.0 + _buff_value(buffs, "world") * 0.5),
		"crit": st["spell_crit"] / 100.0, "dodge": st["dodge"],
		"mit": Stats.armor_factor("priest", level(), st["armor"]),
	}


## A guildmate's abilities from their talents (with every improving talent applied) and their grade.
func member_abilities(m: Dictionary) -> Array:
	if is_priest(m):
		return []
	return SpecTalents.abilities_for(m["spec"], m.get("talents", {}), member_mods(m), SpecTalents.grade_spells(m["class"], m["race"], m["tier"]))


## Party strength shown before an activity, comparable to 100 x content difficulty.
func party_power(ids: Array) -> int:
	var total := member_power(data["priest"])
	var n := 1
	for id in ids:
		var m := member(id)
		if not m.is_empty():
			total += member_power(m)
			n += 1
	return int(round(100.0 * total / n))


func recommended_power(act: Dictionary) -> int:
	var lvl_gap: int = act["level"] - level()
	return int(round(100.0 * act["diff"] * pow(Balance.GROWTH, maxi(0, lvl_gap)) * 1.12 * recommended_talent_factor(act["level"])))


## Recommended power assumes guildmates carry the talents expected at that level.
func recommended_talent_factor(content_level: int) -> float:
	return 1.0 + 0.43 * Encounters.talent_frac(content_level)


# ---------------------------------------------------------------- runs

## Starts an activity with a party. Consumes one of each selected buff.
func start_run(act: Dictionary, ids: Array) -> void:
	var buffs := {}
	var used_names := []
	for cat in ["battle_elixir", "guardian_elixir", "priest_elixir", "food"]:
		if data["use"].get(cat, true):
			var r := _take(cat)
			if r >= 0:
				buffs[cat] = ShopData.rank_value(cat, r)
				used_names.append(ShopData.rank_name(cat, r))
	var wb: Dictionary = data["world_buff"]
	if not wb.is_empty() and wb.get("charges", 0) > 0:
		buffs["world"] = 10.0
		used_names.append(wb["name"])
		wb["charges"] -= 1
		if wb["charges"] <= 0:
			data["world_buff"] = {}
	run = {
		"activity": act, "members": ids, "fight": 0, "buffs": buffs, "buff_names": used_names,
		"xp": 0, "gold": 0, "loot": [], "mana_frac": 1.0, "soulstone": true, "wipes": 0, "levels": 0,
	}
	save()


func run_fight() -> Dictionary:
	return run["activity"]["fights"][run["fight"]]


func build_engine() -> CombatEngine:
	var act: Dictionary = run["activity"]
	var fight := run_fight()
	var party_specs := []
	for id in run["members"]:
		var m := member(id)
		if not m.is_empty():
			party_specs.append(member_combat_spec(m, run["buffs"]))
	var eng := CombatEngine.new()
	var enemies := Encounters.build(fight, act["level"], act["diff"], act["party_size"], rng)
	var pots := {}
	if data["use"].get("mana_potion", true):
		var r := best_stock_rank("mana_potion")
		if r >= 0:
			pots["mana"] = stock("mana_potion")
			pots["mana_amount"] = ShopData.rank_value("mana_potion", r) * Balance.scale(ShopData.rank_level("mana_potion", r))
	if data["use"].get("healing_potion", true):
		var r := best_stock_rank("healing_potion")
		if r >= 0:
			pots["healing"] = stock("healing_potion")
			pots["healing_amount"] = ShopData.rank_value("healing_potion", r) * Balance.scale(ShopData.rank_level("healing_potion", r))
	eng.setup(priest_combat_spec(run["buffs"]), party_specs, enemies, {
		"level": act["level"], "potions": pots, "soulstone": run["soulstone"], "mana_frac": run["mana_frac"], "seed": rng.randi(),
	})
	return eng


## Consumes the potions the engine used during a fight.
func settle_potions(eng: CombatEngine) -> void:
	for i in eng.potions_used["mana"]:
		_take("mana_potion")
	for i in eng.potions_used["healing"]:
		_take("healing_potion")
	if eng.soulstone_used:
		run["soulstone"] = false


## Rewards for a won fight. Returns {xp, gold, items, levels}.
func fight_won(eng: CombatEngine) -> Dictionary:
	settle_potions(eng)
	var act: Dictionary = run["activity"]
	var fight := run_fight()
	var type: String = act["type"]
	var cl: int = act["level"]
	var xp_mult := 1.0
	var gold_mult := 1.0
	match fight["type"]:
		"pack":
			xp_mult = 1.0 if type == "quest" else 1.15
			gold_mult = 1.0 if type == "quest" else 1.3
		"elite":
			xp_mult = 1.4
			gold_mult = 1.5
		"boss":
			xp_mult = 1.7
			gold_mult = 2.2
		"raid_boss":
			xp_mult = 0.0
			gold_mult = 4.0
	if type == "quest":
		xp_mult *= act["diff"]
	var xp := int(Balance.xp_per_fight(cl) * xp_mult * Balance.xp_level_factor(level(), cl))
	var g := int(Balance.income(cl) * gold_mult * rng.randf_range(0.85, 1.15) * Balance.LOOT_RATE)
	var items := _roll_loot(fight, act)
	data["stats"]["fights"] += 1
	run["fight"] += 1
	# Completing a dungeon or the rest of a raid hands out the run's guaranteed role piece.
	if run_finished() and type != "quest" and act.get("guaranteed", "") != "":
		if type == "dungeon":
			items.append(role_piece(act["guaranteed"], Dungeons.by_id(act["id"])["ilvl"], "rare"))
		else:
			items.append(role_piece(act["guaranteed"], Raids.by_id(act["id"])["ilvl"] + 3, "epic"))
	run["mana_frac"] = clampf(eng.mana / eng.max_mana + 0.6, 0.0, 1.0)
	var res := _grant(xp, g, items)
	if fight["type"] == "raid_boss":
		var rid: String = act["id"]
		var pts := Prestige.for_boss(Raids.by_id(rid), fight.get("final", false))
		add_prestige(pts)
		res["prestige"] = pts
		run["prestige"] = run.get("prestige", 0) + pts
		var killed: Array = data["raid_progress"].get(rid, [])
		killed.append(fight["boss_index"])
		data["raid_progress"][rid] = killed
		if fight.get("final", false):
			data["raid_progress"].erase(rid)
			data["raid_clears"][rid] = data["raid_clears"].get(rid, 0) + 1
			add_log("<Lumens> has defeated %s! %s is cleared." % [fight["boss"]["name"], act["title"]])
		if fight["boss"]["name"] in ["Onyxia", "Nefarian"]:
			data["world_buff"] = {"name": "Rallying Cry of the Dragonslayer", "charges": 3}
			add_log("The head of %s is raised in Orgrimmar. Rallying Cry of the Dragonslayer!" % fight["boss"]["name"])
	save()
	return res


## Hands out a reward. The testing boost multiplies experience and gold here (and the number of
## pieces where they are rolled).
func _grant(xp: int, g: int, items: Array) -> Dictionary:
	xp *= Settings.boost_rate()
	g *= Settings.boost_rate()
	var levels := 0
	var p: Dictionary = data["priest"]
	if p["level"] < Balance.MAX_LEVEL:
		p["xp"] += xp
		while p["level"] < Balance.MAX_LEVEL and p["xp"] >= Balance.xp_to_next(p["level"]):
			p["xp"] -= Balance.xp_to_next(p["level"])
			p["level"] += 1
			levels += 1
		if p["level"] >= Balance.MAX_LEVEL:
			p["xp"] = 0
	else:
		xp = 0
	add_gold(g)
	var sold := 0
	var sold_for := 0
	for it in items:
		var price := _bank_add(it, true)
		if price > 0:
			sold += 1
			sold_for += price
	if sold > 0:
		toast.emit("Guild bank full: %d piece%s sold for %s." % [sold, "" if sold == 1 else "s", Balance.money(sold_for)])
	if not run.is_empty():
		run["xp"] += xp
		run["gold"] += g
		run["loot"].append_array(items)
		run["levels"] += levels
	if levels > 0:
		add_log("%s reaches level %d." % [p["name"], p["level"]])
		refresh_quests(true)
		if data.has("missions"):
			data["missions"]["board"].clear()
		refresh_recruits(false)
		refresh_auto_talents()
		leveled.emit(p["level"])
	return {"xp": xp, "gold": g, "items": items, "levels": levels}


func run_finished() -> bool:
	return run["fight"] >= run["activity"]["fights"].size()


## A random item for a profile that someone in the guild can wear, preferably someone who uses that profile.
func wearable_item(ilvl: int, quality: String, profile: String) -> Dictionary:
	var everyone: Array = [data["priest"]] + data["members"]
	var fits := everyone.filter(func(m): return member_stat(m) == profile)
	if fits.is_empty():
		fits = everyone
	var it := {}
	for i in 25:
		it = Items.random_item(ilvl, quality, rng, profile)
		if fits.any(func(m): return Items.can_use(it, member_class(m))):
			break
	return it


## The guaranteed role piece of a run.
func role_piece(profile: String, ilvl: int, quality: String) -> Dictionary:
	var it := wearable_item(ilvl, quality, profile)
	it["guaranteed"] = true
	return it


## Turns in the current quest: its gold and gear are rolled now, the gear leaning towards the party's needs.
func complete_quest() -> Dictionary:
	var act: Dictionary = run["activity"]
	var rw: Dictionary = act["rewards"]
	var profiles := [member_stat(data["priest"])]
	for id in run["members"]:
		var m := member(id)
		if not m.is_empty():
			profiles.append(member_stat(m))
	var roll := Activities.roll_rewards(rw, act.get("guaranteed", ""), profiles, rng, wearable_item, Settings.boost_rate())
	var res := _grant(int(rw["xp"] * Balance.xp_level_factor(level(), act["level"])), roll["gold"], roll["items"])
	data["stats"]["quests"] += 1
	data["quests"].erase(act)
	refresh_quests()
	add_log("Quest complete: %s." % act["title"])
	save()
	return res


func finish_run(success: bool) -> void:
	var act: Dictionary = run["activity"]
	if success:
		match act["type"]:
			"dungeon":
				data["stats"]["dungeons"] += 1
				data["dungeon_clears"][act["id"]] = data["dungeon_clears"].get(act["id"], 0) + 1
				add_log("<Lumens> clears %s." % act["title"])
			"raid":
				data["stats"]["raids"] += 1
	run = {}
	save()
	changed.emit()


func wipe(eng: CombatEngine) -> void:
	settle_potions(eng)
	data["stats"]["wipes"] += 1
	run["wipes"] += 1
	run["mana_frac"] = 1.0
	save()


# ---------------------------------------------------------------- loot

func _party_classes() -> Array:
	var out := ["priest"]
	for id in run.get("members", []):
		var m := member(id)
		if not m.is_empty() and not (m["class"] in out):
			out.append(m["class"])
	return out


## A won fight's gear: its drops rolled LOOT_RATE times over (times the testing boost).
func _roll_loot(fight: Dictionary, act: Dictionary) -> Array:
	var out := []
	for i in Balance.LOOT_RATE * Settings.boost_rate():
		out.append_array(_roll_drops(fight, act))
	return out


func _roll_drops(fight: Dictionary, act: Dictionary) -> Array:
	var out := []
	var type: String = act["type"]
	match type:
		"quest":
			if rng.randf() < 0.12:
				out.append(Items.random_item(act["level"], "uncommon", rng))
		"dungeon":
			var d := Dungeons.by_id(act["id"])
			var ilvl: int = d["ilvl"]
			if fight["type"] == "pack":
				if rng.randf() < 0.22:
					out.append(Items.random_item(ilvl - 2, "rare" if rng.randf() < 0.25 else "uncommon", rng))
			else:
				var b: Dictionary = fight["boss"]
				var table: Array = b.get("loot", [])
				var drops := 2 if b.get("final", false) else 1
				var pool := table.duplicate()
				pool.shuffle()
				for i in drops:
					if i < pool.size():
						out.append(Items.from_entry(pool[i], ilvl, "rare"))
					else:
						out.append(Items.random_item(ilvl, "rare", rng))
				if rng.randf() < 0.35:
					out.append(Items.random_item(ilvl - 1, "uncommon" if rng.randf() < 0.6 else "rare", rng))
				if b.has("tier") and rng.randf() < 0.45:
					var classes := _party_classes()
					out.append(Items.tier_piece(classes[rng.randi() % classes.size()], 0, ilvl + 1, rng))
		"raid":
			var r := Raids.by_id(act["id"])
			var b: Dictionary = fight["boss"]
			var ilvl: int = r["ilvl"] + int(fight.get("boss_index", 0)) + (3 if b.get("final", false) else 0)
			var table: Array = b.get("loot", [])
			var pool := table.duplicate()
			pool.shuffle()
			var drops := 3 if b.get("final", false) else 2
			for i in mini(drops, pool.size()):
				out.append(Items.from_entry(pool[i], ilvl, "epic"))
			if r["tier"] >= 1:
				var classes := _party_classes()
				var slots: Array = r.get("tier_slots", [])
				var slot: String = slots[0] if not slots.is_empty() else ""
				out.append(Items.tier_piece(classes[rng.randi() % classes.size()], r["tier"], ilvl, rng, slot))
				if b.get("final", false):
					out.append(Items.tier_piece(classes[rng.randi() % classes.size()], r["tier"], ilvl, rng, slot))
			for e in b.get("legendary", []):
				if rng.randf() < 0.02:
					out.append(Items.from_entry(e, ilvl, "legendary"))
					add_log("[LEGENDARY] %s drops %s!" % [b["name"], e[0]])
	return out


## Spends new talent points for every guildmate on the recommended build.
func refresh_auto_talents() -> void:
	for m in data["members"]:
		if m.get("auto_talents", true):
			m["talents"] = SpecTalents.auto_build(m["spec"], m.get("talents", {}), level())
