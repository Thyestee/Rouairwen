class_name CombatEngine
extends RefCounted
## Real-time healer combat. The guild fights on its own; the priest keeps it alive.
##
## Pure logic with no nodes, so the same engine drives the combat screen and the
## headless balance simulation. Call tick(delta) every frame and cast() on input.

signal floating(unit, text: String, kind: String)
signal log_line(text: String)
## Detailed combat log entries; category is "heal", "damage" or "guild" (guildmates' abilities).
## log_line carries the other events.
signal combat_log(category: String, text: String)
signal ended(won: bool)

const LOG_HEAL := "6ee06e"
const LOG_DAMAGE := "ff6a5a"
const LOG_SPELL := "ffd86b"
const LOG_GUILD := "8fd3ff"

const GCD := 1.5
const FSR := 5.0
const DISPEL_COLORS := {"magic": Color("3c8cff"), "curse": Color("a335ee"), "disease": Color("c0a060"),
	"poison": Color("3cb043"), "": Color("b02020")}


class Unit:
	extends RefCounted
	var uid := 0
	var name := ""
	var class_id := ""
	var spec_id := ""
	var role := ""
	var is_enemy := false
	var is_priest := false
	var is_boss := false
	var is_elite := false
	var max_hp := 1.0
	var hp := 1.0
	var alive := true
	var dps := 0.0
	var mit := 1.0
	var aggro := 0.0
	var attack_timer := 0.0
	var auras: Array = []
	var target = null
	var swing := 0.0
	var swing_speed := 2.0
	var swing_timer := 0.0
	var abilities: Array = []
	var cast: Dictionary = {}
	var utils: Array = []
	var used: Dictionary = {}
	var damage_done := 0.0
	var healing_done := 0.0
	var enrage_at := 0.0
	var enraged := false
	var berserk := 0.0
	var retarget_timer := 0.0
	var spirit := 0.0
	var last_attacker = null
	## Talent, trait and affix effects (see SpecTalents.EFFECTS).
	var mods: Dictionary = {}
	## Critical strike and dodge chances (%) from Agility, Intellect and Defense.
	var crit_base := 12.0
	var dodge_base := 0.0
	## Abilities from talents (SpecTalents.abilities_for), each with the time it is "ready" again.
	var skills: Array = []
	var skill_gcd := 0.0
	## Share of their damage dealt by auto attacks; their abilities' base damage makes up the rest.
	var white := 1.0

	func mod(key: String) -> float:
		return mods.get(key, 0.0)

	func absorb() -> float:
		var a := 0.0
		for au in auras:
			a += au.get("absorb", 0.0)
		return a

	func has(id: String) -> bool:
		for au in auras:
			if au["id"] == id:
				return true
		return false

	func get_aura(id: String) -> Dictionary:
		for au in auras:
			if au["id"] == id:
				return au
		return {}

	func remove(id: String) -> void:
		for i in range(auras.size() - 1, -1, -1):
			if auras[i]["id"] == id:
				auras.remove_at(i)

	func frac() -> float:
		return clampf(hp / max_hp, 0.0, 1.0)

	func cc() -> bool:
		for au in auras:
			if au.get("cc", false):
				return true
		return false


var rng := RandomNumberGenerator.new()
var party: Array = []
var enemies: Array = []
var priest: Unit
var level := 1
var u := 1.0
var time := 0.0
var over := false
var won := false
var focus = null

# Priest state
var talents := {}
var known: Array = []
var mana := 0.0
var max_mana := 1.0
var regen := 1.0
var fsr_keep := 0.15
var since_spend := 99.0
## Healing power (Healing + Spell Damage) and Spell Damage: each spell adds its coefficient of them.
var heal_power := 0.0
var spell_power := 0.0
## Healing multiplier from elixirs and world buffs.
var heal_mult := 1.0
var crit := 0.05
var haste := 0.0
var casting: Dictionary = {}
var gcd := 0.0
var cooldowns := {}
var inner_focus := false
var borrowed_time := false
var surge := false
var serendipity := 0
var silenced := 0.0
var lightwell: Dictionary = {}
var lightwell_tick := 0.0
var potion_cd := 0.0
var mana_potions := 0
var mana_potion_amount := 0.0
var healing_potions := 0
var healing_potion_amount := 0.0
var potions_used := {"mana": 0, "healing": 0}
var soulstone := false
var soulstone_used := false
## Windfury Totem: every ally hit (Smite included) has this chance to deal double damage.
var windfury := false
const WINDFURY_CHANCE := 0.05
var windfury_chance := WINDFURY_CHANCE
## Strongest party aura / enemy debuff of each kind (SpecTalents.GROUP_KEYS).
var group := {}
const INTERRUPT_COOLDOWN := 8.0
const OPENER_TIME := 12.0
## Share of a boss's spells that guildmates' interrupts can stop (a regular enemy's always can).
const BOSS_INTERRUPTIBLE := 0.35
## Guildmate abilities used whenever needed, off the global cooldown; the others share SKILL_GCD.
const REACTIVE := ["defensive", "self_heal", "shield", "feign", "taunt"]
const SKILL_GCD := 1.5
const DOT_PERIOD := 3.0
var soulstone_timer := 0.0
var innervate_time := 0.0
var cleanse_timer := 6.0
var decurse_timer := 6.0
var priest_dead_for := 0.0
var next_uid := 1
var stats := {"healing": 0.0, "overheal": 0.0, "absorbed": 0.0, "mana_spent": 0.0, "dispels": 0, "deaths": 0}
var _talent_values := {}
var _focus_crit := false


## party_specs: guildmates; priest_spec: the player's priest; enemy_specs: from Encounters.build.
## ctx: {level, potions: {mana, mana_amount, healing, healing_amount}, soulstone}
func setup(priest_spec: Dictionary, party_specs: Array, enemy_specs: Array, ctx: Dictionary) -> void:
	level = ctx.get("level", 1)
	u = Balance.scale(level)
	rng.seed = ctx.get("seed", randi())
	talents = priest_spec.get("talents", {})
	for id in talents:
		_talent_values[id] = Talents.value(talents, id)
	known = priest_spec.get("known", ["heal", "smite"])

	priest = Unit.new()
	priest.uid = _uid()
	priest.name = priest_spec["name"]
	priest.class_id = "priest"
	priest.role = "priest"
	priest.is_priest = true
	priest.max_hp = priest_spec["max_hp"]
	priest.hp = priest.max_hp
	priest.mit = priest_spec.get("mit", 1.0)
	priest.dodge_base = priest_spec.get("dodge", 0.0)
	priest.aggro = 0.0
	party.append(priest)

	var utils_present := {}
	for s in party_specs:
		var m := Unit.new()
		m.uid = _uid()
		m.name = s["name"]
		m.class_id = s["class_id"]
		m.spec_id = s["spec_id"]
		m.role = s["role"]
		m.max_hp = s["max_hp"]
		m.hp = m.max_hp
		m.dps = s["dps"]
		m.mit = s["mit"]
		m.aggro = s["aggro"]
		m.utils = s.get("utils", [])
		m.mods = s.get("mods", {})
		m.crit_base = s.get("crit", 12.0)
		m.dodge_base = s.get("dodge", 0.0)
		for a in s.get("abilities", []):
			var sk: Dictionary = a.duplicate(true)
			# Damage abilities come up a little after the pull; reactive ones are ready at once.
			sk["ready"] = 0.0 if sk["kind"] in REACTIVE else rng.randf_range(0.5, 3.0)
			m.skills.append(sk)
		m.white = 1.0 / (1.0 + SpecTalents.damage_share(s.get("abilities", [])))
		m.attack_timer = rng.randf_range(0.2, 1.5)
		for ut in m.utils:
			utils_present[ut] = true
		# Party auras and enemy debuffs don't stack: the strongest one counts.
		for k in SpecTalents.GROUP_KEYS:
			if m.mods.has(k):
				group[k] = maxf(group.get(k, 0.0), m.mods[k])
		party.append(m)

	# Party-wide utilities and auras
	for m in party:
		m.mit *= 1.0 - group.get("party_mit", 0.0) / 100.0
		m.max_hp *= 1.0 + group.get("party_hp", 0.0) / 100.0
		m.hp = m.max_hp
		if m.is_priest:
			continue
		var mult: float = 1.0 + group.get("party_dps", 0.0) / 100.0
		if m.role == "melee" or m.role == "tank":
			if utils_present.has("battle_shout"):
				mult += 0.05
		if ClassData.SPECS.get(m.spec_id, {}).get("stat", "") == "physical" and utils_present.has("trueshot_aura"):
			mult += 0.04
		m.dps *= mult

	max_mana = priest_spec["max_mana"] * (1.0 + _tv("mental_strength") / 100.0) * (1.0 + group.get("priest_mana", 0.0) / 100.0)
	if utils_present.has("arcane_intellect"):
		max_mana *= 1.08
	regen = priest_spec["regen"] * (1.1 if utils_present.has("totems") else 1.0) * (1.0 + group.get("priest_regen", 0.0) / 100.0)
	fsr_keep = 0.15 + _tv("meditation") / 100.0
	mana = max_mana * ctx.get("mana_frac", 1.0)
	heal_power = priest_spec.get("heal_power", 0.0)
	spell_power = priest_spec.get("spell_power", 0.0)
	heal_mult = priest_spec.get("heal_mult", 1.0)
	crit = priest_spec.get("crit", 0.05) + _tv("holy_specialization") / 100.0
	soulstone = ctx.get("soulstone", false) and utils_present.has("soulstone")
	windfury = utils_present.has("windfury")
	windfury_chance = WINDFURY_CHANCE + group.get("windfury_bonus", 0.0) / 100.0

	var pots: Dictionary = ctx.get("potions", {})
	mana_potions = pots.get("mana", 0)
	mana_potion_amount = pots.get("mana_amount", 0.0)
	healing_potions = pots.get("healing", 0)
	healing_potion_amount = pots.get("healing_amount", 0.0)

	for e in enemy_specs:
		_spawn(e)


func _uid() -> int:
	next_uid += 1
	return next_uid


func _tv(id: String) -> float:
	return _talent_values.get(id, 0.0)


func _windfury_proc() -> bool:
	return windfury and rng.randf() < windfury_chance


func _group(key: String) -> float:
	return group.get(key, 0.0)


## Effects that change the combat stats themselves are applied here; the rest ride along in "mods".
const APPLIED_MODS := ["hp", "dps", "mit", "aggro"]


## A guildmate's combat numbers from their spec, grade, stats (Stats.compute) and effects.
## Damage follows Attack Power or Spell Damage, health follows Stamina, damage taken follows Armor,
## crit and dodge come from Agility/Intellect and Defense.
static func member_spec(mname: String, spec_id: String, grade: float, stats: Dictionary, mods: Dictionary,
		abilities: Array, lvl: int, dmg_buff := 0.0, hp_buff := 0.0) -> Dictionary:
	var sp: Dictionary = ClassData.SPECS[spec_id]
	var rest := {}
	for k in mods:
		var key := String(k)
		if not (key in APPLIED_MODS) and not key.contains(".") and not key.ends_with("%") and key != "ability":
			rest[k] = mods[k]
	return {
		"name": mname, "class_id": sp["class"], "spec_id": spec_id, "role": sp["role"],
		"max_hp": sp["hp"] * Balance.scale(lvl) * sqrt(grade) * stats["health_mult"] * (1.0 + hp_buff) * (1.0 + mods.get("hp", 0.0) / 100.0),
		"dps": sp["dps"] * grade * stats["offense"] * (1.0 + dmg_buff) * (1.0 + mods.get("dps", 0.0) / 100.0),
		"mit": clampf(sp["mit"] * Stats.armor_factor(sp["class"], lvl, stats["armor"]) * (1.0 - mods.get("mit", 0.0) / 100.0), 0.25, 1.3),
		"aggro": clampf(sp["aggro"] + mods.get("aggro", 0.0) / 100.0, 0.0, 0.98),
		"crit": stats["crit_chance"], "dodge": stats["dodge"],
		"utils": sp["util"], "pm": grade * stats["offense"], "mods": rest, "abilities": abilities,
	}


func _spawn(e: Dictionary) -> Unit:
	var en := Unit.new()
	en.uid = _uid()
	en.is_enemy = true
	en.name = e["name"]
	en.max_hp = e["max_hp"]
	en.hp = en.max_hp
	en.is_boss = e.get("boss", false)
	en.is_elite = e.get("elite", false)
	en.swing = e["swing"]
	en.swing_speed = e.get("swing_speed", 2.0)
	en.swing_timer = rng.randf_range(0.5, en.swing_speed)
	en.enrage_at = e.get("enrage_at", 0.0)
	en.berserk = e.get("berserk", 0.0)
	for a in e.get("abilities", []):
		var ab: Dictionary = a.duplicate(true)
		ab["interruptible"] = not en.is_boss or rng.randf() < BOSS_INTERRUPTIBLE
		en.abilities.append(ab)
	en.retarget_timer = rng.randf_range(4.0, 7.0)
	enemies.append(en)
	en.target = _pick_tank()
	return en


# ---------------------------------------------------------------- queries

func alive_party() -> Array:
	return party.filter(func(m): return m.alive)


func alive_enemies() -> Array:
	return enemies.filter(func(e): return e.alive)


func tank() -> Unit:
	var best: Unit = null
	for m in party:
		if m.alive and not m.is_priest and m.role == "tank":
			if best == null or m.aggro > best.aggro:
				best = m
	return best


func _pick_tank() -> Unit:
	var t := tank()
	if t != null:
		return t
	var best: Unit = null
	for m in party:
		if m.alive and not m.is_priest:
			if best == null or m.aggro > best.aggro or (m.aggro == best.aggro and m.max_hp > best.max_hp):
				best = m
	if best == null and priest.alive:
		return priest
	return best


func _random_member(exclude = null, prefer_non_tank := false) -> Unit:
	var pool := []
	for m in party:
		if not m.alive or m == exclude or m.spirit > 0.0:
			continue
		var w := 1.0
		if m.is_priest:
			w = 0.8
		if prefer_non_tank and m.role == "tank":
			w = 0.25
		# Subtle guildmates draw less attention; reckless ones draw more.
		w *= clampf(1.0 - m.mod("threat") / 100.0, 0.2, 2.0)
		pool.append([m, w])
	if pool.is_empty():
		return null
	var total := 0.0
	for p in pool:
		total += p[1]
	var r := rng.randf() * total
	for p in pool:
		r -= p[1]
		if r <= 0.0:
			return p[0]
	return pool[0][0]


func _mult(unit: Unit, key: String) -> float:
	var m := 1.0
	for au in unit.auras:
		m *= au.get(key, 1.0)
	return m


## Debuffs of one kind on an enemy don't stack: the one furthest from 1.0 counts.
func _strongest(unit: Unit, key: String) -> float:
	var best := 1.0
	for au in unit.auras:
		var v: float = au.get(key, 1.0)
		if absf(v - 1.0) > absf(best - 1.0):
			best = v
	return best


func cooldown_left(id: String) -> float:
	return cooldowns.get(id, 0.0)


func spell_cost(id: String) -> float:
	var s: Dictionary = Spells.BOOK[id]
	var cost: float = s["mana"] * u
	if s["cast"] == 0.0 and not s.get("channel", 0):
		cost *= 1.0 - _tv("mental_agility") / 100.0
	if id == "heal" or id == "prayer_of_healing":
		cost *= 1.0 - _tv("improved_healing") / 100.0
	if id == "prayer_of_healing" or id == "prayer_of_mending":
		cost *= 1.0 - _tv("healing_prayers") / 100.0
	if inner_focus and id != "inner_focus":
		cost = 0.0
	if id == "flash_heal" and surge:
		cost = 0.0
	if priest.spirit > 0.0:
		cost = 0.0
	return cost


func cast_time(id: String) -> float:
	var s: Dictionary = Spells.BOOK[id]
	var t: float = s["cast"]
	if s.get("channel", 0):
		return t
	if id == "heal" or id == "smite":
		t -= _tv("divine_fury")
	if (id == "heal" or id == "prayer_of_healing") and serendipity > 0:
		t *= 1.0 - serendipity * _tv("serendipity") / 100.0
	if id == "flash_heal" and surge:
		return 0.0
	if t <= 0.0:
		return 0.0
	if borrowed_time:
		t *= 1.0 - _tv("borrowed_time") / 100.0
	return t / (1.0 + _haste())


func _haste() -> float:
	var h := haste
	if priest.has("power_infusion"):
		h += 0.2
	return h


## Why a spell can't be cast right now ("" when it can).
func can_cast(id: String, target) -> String:
	if over:
		return "The fight is over"
	if not priest.alive and priest.spirit <= 0.0:
		return "You are dead"
	if not (id in known):
		return "Unknown spell"
	var s: Dictionary = Spells.BOOK[id]
	if not casting.is_empty():
		return "Already casting"
	if silenced > 0.0:
		return "Silenced"
	if gcd > 0.0 and not s.get("off_gcd", false):
		return "Not ready yet"
	if cooldown_left(id) > 0.0:
		return "Not ready yet"
	if mana < spell_cost(id):
		return "Not enough mana"
	match s["target"]:
		"ally":
			if target == null or target.is_enemy or not target.alive:
				return "Invalid target"
			if id == "shield" and target.has("weakened_soul"):
				return "Target is Weakened Soul"
			if id == "dispel" and _dispellable(target).is_empty():
				return "Nothing to dispel"
		"enemy":
			if _enemy_target() == null:
				return "No enemy"
	return ""


func _enemy_target() -> Unit:
	if focus != null and focus.alive:
		return focus
	var a := alive_enemies()
	return a[0] if not a.is_empty() else null


func _dispellable(target: Unit) -> Dictionary:
	for au in target.auras:
		if au.get("dispel", "") in ["magic", "disease"] and au.get("harmful", false):
			return au
	return {}


# ---------------------------------------------------------------- casting

func cast(id: String, target) -> String:
	var err := can_cast(id, target)
	if err != "":
		return err
	var s: Dictionary = Spells.BOOK[id]
	if s["target"] == "self":
		target = priest
	elif s["target"] == "enemy":
		target = _enemy_target()
	var ct := cast_time(id)
	if not s.get("off_gcd", false):
		gcd = maxf(1.0, GCD / (1.0 + _haste()))
	if s.get("channel", 0):
		casting = {"id": id, "target": target, "remaining": s["cast"], "total": s["cast"], "channel": true,
			"ticks": s["channel"], "tick_timer": 0.0}
		_spend(spell_cost(id))
		cooldowns[id] = s.get("cooldown", 0.0)
		borrowed_time = false
		_channel_tick()
		_focus_crit = false
		return ""
	if ct <= 0.0:
		_spend(spell_cost(id))
		_resolve(id, target)
		_focus_crit = false
		return ""
	casting = {"id": id, "target": target, "remaining": ct, "total": ct, "channel": false}
	return ""


func cancel_cast() -> void:
	if not casting.is_empty():
		casting = {}
		gcd = minf(gcd, 0.3)


func use_mana_potion() -> String:
	if over or (not priest.alive and priest.spirit <= 0.0):
		return "You can't do that now"
	if mana_potions <= 0:
		return "No mana potions"
	if potion_cd > 0.0:
		return "Potion not ready"
	mana_potions -= 1
	potions_used["mana"] += 1
	potion_cd = 60.0
	var gain := minf(mana_potion_amount, max_mana - mana)
	mana += gain
	floating.emit(priest, "+%d mana" % int(gain), "mana")
	return ""


## Pays for a spell. Inner Focus is consumed here, but its crit bonus lasts until the spell resolves.
func _spend(cost: float) -> void:
	if cost > 0.0:
		mana -= cost
		since_spend = 0.0
		stats["mana_spent"] += cost
	if inner_focus:
		inner_focus = false
		_focus_crit = true


func _finish_cast() -> void:
	var id: String = casting["id"]
	var target = casting["target"]
	casting = {}
	var cost := spell_cost(id)
	if mana < cost:
		log_line.emit("Not enough mana to finish %s." % Spells.display_name(id, level))
		return
	if Spells.BOOK[id]["cast"] > 0.0 and borrowed_time:
		borrowed_time = false
	_spend(cost)
	_resolve(id, target)
	_focus_crit = false


func _channel_tick() -> void:
	var target = casting["target"]
	casting["ticks"] -= 1
	if target != null and target.alive:
		_heal(target, _base_heal("penance"), true, "penance")
		if casting["ticks"] == Spells.BOOK["penance"]["channel"] - 1:
			_add_grace(target)
	if casting["ticks"] <= 0:
		casting = {}


## A heal's amount before crits: base plus its coefficient of healing power, with every bonus.
func _base_heal(id: String) -> float:
	return spell_amount(id, level, heal_power, spell_power, heal_mult, talents)


## A spell's coefficient, Empowered Healing included.
static func spell_coef(id: String, tal: Dictionary) -> float:
	var c: float = Spells.BOOK[id].get("coef", 0.0)
	if id == "heal":
		c += Talents.value(tal, "empowered_healing") / 100.0
	elif id == "flash_heal":
		c += Talents.value(tal, "empowered_healing") / 200.0
	return c


## A priest spell's amount (heal, absorb or damage) before crits and random spread: its base in level
## units plus its coefficient of healing power (Spell Damage for Smite), times talents and buffs.
## Shared with tooltips, so they show what the spell really does.
static func spell_amount(id: String, lvl: int, hp: float, spp: float, mult: float, tal: Dictionary) -> float:
	var s: Dictionary = Spells.BOOK[id]
	var power: float = spp if s.get("power", "") == "spell" else hp
	var a: float = s["amount"] * Balance.scale(lvl) + spell_coef(id, tal) * power
	if id == "smite":
		return a * (1.0 + Talents.value(tal, "twin_disciplines") / 100.0)
	a *= mult * (1.0 + (Talents.value(tal, "twin_disciplines") + Talents.value(tal, "spiritual_healing")) / 100.0)
	if id == "renew":
		a *= 1.0 + Talents.value(tal, "improved_renew") / 100.0
	elif id == "shield":
		a *= 1.0 + Talents.value(tal, "improved_shield") / 100.0
	return a


## "Heals for 2412 (+756 from healing power, 71%)": what a spell does now, for its tooltip.
static func spell_text(id: String, lvl: int, hp: float, spp: float, mult: float, tal: Dictionary) -> String:
	var s: Dictionary = Spells.BOOK[id]
	if s["amount"] <= 0:
		return ""
	var total := spell_amount(id, lvl, hp, spp, mult, tal)
	var spell: bool = s.get("power", "") == "spell"
	var power := spp if spell else hp
	var coef := spell_coef(id, tal)
	var gain := total - spell_amount(id, lvl, 0.0, 0.0, mult, tal)
	var what := ""
	match id:
		"smite":
			what = "Deals %d Holy damage" % total
		"shield":
			what = "Absorbs %d damage" % total
		"renew":
			what = "Heals for %d over %d sec, %d per tick" % [total, s["duration"], total / s["ticks"]]
		"penance":
			what = "Each bolt heals for %d" % total
		"prayer_of_mending":
			what = "Heals for %d on each jump" % total
		"lightwell":
			what = "Each charge heals for %d over 6 sec" % total
		"prayer_of_healing", "circle_of_healing":
			what = "Heals each for %d" % total
		_:
			what = "Heals for %d" % total
	var share := "%d%%" % int(round(coef * 100.0))
	if id == "renew":
		share += ", split over %d ticks" % s["ticks"]
	elif id == "penance":
		share += " per bolt"
	var line := "[color=#ffffff]%s[/color]" % what
	if power > 0.0:
		line += " [color=#8a7262](+%d from %s, %s)[/color]" % [gain, "Spell Damage" if spell else "healing power", share]
	else:
		line += " [color=#8a7262](+%s of your %s)[/color]" % [share, "Spell Damage" if spell else "healing power"]
	return line + "."


func amount_text(id: String) -> String:
	return spell_text(id, level, heal_power, spell_power, heal_mult, talents)


func _resolve(id: String, target) -> void:
	var s: Dictionary = Spells.BOOK[id]
	match id:
		"heal":
			_heal(target, _base_heal(id), true, id)
			serendipity = 0
		"flash_heal":
			surge = false
			_heal(target, _base_heal(id), true, id)
			_add_grace(target)
			if talents.get("serendipity", 0) > 0:
				serendipity = mini(serendipity + 1, 3)
		"smite":
			var e: Unit = target if target != null and target.alive else _enemy_target()
			if e != null:
				var dmg: float = spell_amount(id, level, heal_power, spell_power, heal_mult, talents) * rng.randf_range(0.9, 1.1)
				var smite_crit := rng.randf() < crit + (0.25 if _focus_crit else 0.0)
				if smite_crit:
					dmg *= 1.5
				var label := "Smite"
				if _windfury_proc():
					dmg *= 2.0
					label = "Smite (Windfury)"
				_damage_enemy(e, dmg, priest, label, smite_crit)
		"shield":
			var amt: float = _base_heal(id)
			target.remove("pws")
			target.auras.append({"id": "pws", "name": "Power Word: Shield", "remaining": 30.0, "absorb": amt, "icon": "shield", "mine": true})
			target.remove("weakened_soul")
			target.auras.append({"id": "weakened_soul", "name": "Weakened Soul", "remaining": 15.0, "icon": "weakened", "debuff": true,
				"desc": "Cannot be protected by Power Word: Shield."})
			cooldowns["shield"] = s["cooldown"]
			if talents.get("borrowed_time", 0) > 0:
				borrowed_time = true
		"renew":
			var per: float = _base_heal(id) / s["ticks"]
			target.remove("renew")
			target.auras.append({"id": "renew", "name": "Renew", "remaining": s["duration"], "period": s["duration"] / s["ticks"],
				"tick_timer": s["duration"] / s["ticks"], "heal": per, "icon": "renew", "mine": true})
		"dispel":
			var au := _dispellable(target)
			if not au.is_empty():
				target.auras.erase(au)
				stats["dispels"] += 1
				floating.emit(target, "Dispelled", "info")
		"prayer_of_healing":
			for m in _most_injured(s["max_targets"]):
				_heal(m, _base_heal(id), true, id)
			serendipity = 0
		"circle_of_healing":
			for m in _most_injured(s["max_targets"]):
				_heal(m, _base_heal(id), true, id)
			cooldowns[id] = s["cooldown"]
		"prayer_of_mending":
			for m in party:
				m.remove("pom")
			target.auras.append({"id": "pom", "name": "Prayer of Mending", "remaining": 30.0, "charges": s["charges"],
				"heal": _base_heal(id), "icon": "pom", "mine": true})
			cooldowns[id] = s["cooldown"]
		"inner_focus":
			inner_focus = true
			cooldowns[id] = s["cooldown"]
			floating.emit(priest, "Inner Focus", "info")
		"power_infusion":
			target.remove("power_infusion")
			target.auras.append({"id": "power_infusion", "name": "Power Infusion", "remaining": 15.0, "dps_mult": 1.2, "icon": "infusion", "mine": true})
			cooldowns[id] = s["cooldown"]
		"pain_suppression":
			target.remove("pain_suppression")
			target.auras.append({"id": "pain_suppression", "name": "Pain Suppression", "remaining": 8.0, "dmg_taken": 0.6, "icon": "suppression", "mine": true})
			cooldowns[id] = s["cooldown"]
		"lightwell":
			lightwell = {"charges": s["charges"], "remaining": 60.0}
			cooldowns[id] = s["cooldown"]
			log_line.emit("You create a Lightwell.")
	if s.has("cooldown"):
		cooldowns[id] = s["cooldown"]


func _add_grace(target) -> void:
	if talents.get("grace", 0) <= 0 or target == null:
		return
	var g: Dictionary = target.get_aura("grace")
	if g.is_empty():
		target.auras.append({"id": "grace", "name": "Grace", "remaining": 15.0, "stacks": 1, "per_stack": _tv("grace"), "icon": "grace", "mine": true})
	else:
		g["stacks"] = mini(g["stacks"] + 1, 3)
		g["remaining"] = 15.0


func _most_injured(count: int) -> Array:
	var list := alive_party()
	list.sort_custom(func(a, b): return (a.max_hp - a.hp) > (b.max_hp - b.hp))
	return list.slice(0, count)


## Direct priest heal on a party member, with crits and their talent procs.
func _heal(target, amount: float, can_crit: bool, source: String) -> float:
	if target == null or not target.alive:
		return 0.0
	var c := crit + (0.25 if _focus_crit else 0.0)
	var is_crit := can_crit and rng.randf() < c
	if is_crit:
		amount *= 1.5
	var g: Dictionary = target.get_aura("grace")
	if not g.is_empty():
		amount *= 1.0 + g["stacks"] * _tv("grace") / 100.0
	amount *= _mult(target, "heal_taken") * rng.randf_range(0.95, 1.05)
	var eff := minf(amount, target.max_hp - target.hp)
	target.hp += eff
	stats["healing"] += eff
	stats["overheal"] += amount - eff
	priest.healing_done += eff
	floating.emit(target, ("+%d!" if is_crit else "+%d") % int(amount), "crit_heal" if is_crit else "heal")
	_log_heal(Spells.display_name(source, level), target, amount, eff, is_crit)
	if is_crit:
		if talents.get("inspiration", 0) > 0:
			target.remove("inspiration")
			target.auras.append({"id": "inspiration", "name": "Inspiration", "remaining": 15.0,
				"dmg_taken": 1.0 - _tv("inspiration") / 100.0, "icon": "inspiration", "mine": true})
		if talents.get("divine_aegis", 0) > 0:
			var aeg: Dictionary = target.get_aura("aegis")
			var add := amount * _tv("divine_aegis") / 100.0
			if aeg.is_empty():
				target.auras.append({"id": "aegis", "name": "Divine Aegis", "remaining": 12.0, "absorb": add, "icon": "aegis", "mine": true})
			else:
				aeg["absorb"] = minf(aeg["absorb"] + add, target.max_hp * 0.4)
				aeg["remaining"] = 12.0
		if talents.get("surge_of_light", 0) > 0 and source != "flash_heal" and rng.randf() * 100.0 < _tv("surge_of_light"):
			surge = true
			floating.emit(priest, "Surge of Light", "info")
	return eff


func _log_heal(spell: String, target: Unit, amount: float, eff: float, is_crit: bool) -> void:
	var over := amount - eff
	combat_log.emit("heal", "Your [color=#%s]%s[/color] heals %s for [color=#%s]%d[/color]%s%s." % [LOG_SPELL, spell,
		"you" if target.is_priest else target.name, LOG_HEAL, int(amount), " (critical)" if is_crit else "",
		(" (%d overhealed)" % int(over)) if over >= 1.0 else ""])


## Healing from something other than the priest's spells (guildmates, potions, healthstones).
func _heal_other(target: Unit, amount: float) -> void:
	if not target.alive:
		return
	amount *= _mult(target, "heal_taken")
	var eff := minf(amount, target.max_hp - target.hp)
	target.hp += eff
	if eff > 1.0:
		floating.emit(target, "+%d" % int(eff), "heal_other")


# ---------------------------------------------------------------- damage

## Damage to an enemy. Spell damage from the priest (label set) shows on the nameplate and in the log;
## guildmates' abilities (label set) only go to the log, to keep the nameplates readable.
func _damage_enemy(e: Unit, amount: float, source: Unit, label := "", is_crit := false) -> void:
	if not e.alive:
		return
	amount *= (1.0 + _group("enemy_vuln") / 100.0) * _strongest(e, "dmg_taken")
	e.hp -= amount
	if source != null:
		source.damage_done += amount
	if source == priest and label != "":
		floating.emit(e, ("-%d!" if is_crit else "-%d") % int(amount), "spell_crit" if is_crit else "spell_damage")
		combat_log.emit("damage", "Your [color=#%s]%s[/color] hits %s for [color=#%s]%d[/color]%s." % [LOG_SPELL, label, e.name,
			LOG_SPELL, int(amount), " (critical)" if is_crit else ""])
	elif source != null and label != "":
		combat_log.emit("guild", "%s's [color=#%s]%s[/color] hits %s for [color=#%s]%d[/color]%s." % [source.name, LOG_GUILD, label,
			e.name, LOG_GUILD, int(amount), " (critical)" if is_crit else ""])
	if e.hp <= 0.0:
		e.hp = 0.0
		e.alive = false
		e.cast = {}
		log_line.emit("[color=#ffd100]%s[/color] dies." % e.name)
		if focus == e:
			focus = null


func damage(target: Unit, amount: float, attacker: Unit, label := "") -> void:
	if target == null or not target.alive or over:
		return
	if target.spirit > 0.0:
		return
	# Plain melee swings (no label) can be dodged.
	if label == "" and attacker != null and attacker.is_enemy and rng.randf() * 100.0 < target.dodge_base + target.mod("dodge"):
		floating.emit(target, "Dodge", "info")
		return
	amount *= _mult(target, "dmg_taken") * target.mit
	if attacker != null and attacker.is_enemy:
		amount *= (1.0 - _group("enemy_dmg") / 100.0) * _strongest(attacker, "dmg_done")
	if attacker != null and attacker.enraged:
		amount *= 1.4
	if attacker != null and attacker.berserk > 0.0 and time > attacker.berserk:
		amount *= 3.0
	target.last_attacker = attacker
	var total := amount
	# Absorbs: shields first, then Divine Aegis.
	for au in target.auras.duplicate():
		if amount <= 0.0:
			break
		var ab: float = au.get("absorb", 0.0)
		if ab <= 0.0:
			continue
		var used := minf(ab, amount)
		au["absorb"] = ab - used
		amount -= used
		stats["absorbed"] += used
		if au.get("mine", false):
			priest.healing_done += used
			combat_log.emit("heal", "Your [color=#%s]%s[/color] absorbs [color=#%s]%d[/color] damage on %s." % [LOG_SPELL, au["name"],
				LOG_HEAL, int(used), "you" if target.is_priest else target.name])
		if au["id"] == "pws" and attacker != null and talents.get("reflective_shield", 0) > 0:
			_damage_enemy(attacker, used * _tv("reflective_shield") / 100.0, priest, "Reflective Shield")
		if au["absorb"] <= 0.01:
			target.auras.erase(au)
			if au["id"] == "pws" and talents.get("rapture", 0) > 0:
				var gain := max_mana * _tv("rapture") / 100.0
				mana = minf(max_mana, mana + gain)
	if total - amount > 0.5 and amount <= 0.0:
		floating.emit(target, "Absorbed", "absorb")
	target.hp -= amount
	if amount > target.max_hp * 0.12:
		floating.emit(target, "-%d" % int(amount), "damage")
	if label != "" and attacker != null:
		var absorbed := total - amount
		combat_log.emit("damage", "%s's [color=#ff9a3c]%s[/color] hits %s for [color=#%s]%d[/color]%s." % [attacker.name, label,
			"you" if target.is_priest else target.name, LOG_DAMAGE, int(total), (" (%d absorbed)" % int(absorbed)) if absorbed >= 1.0 else ""])
	_on_damaged(target, total)
	if target.hp <= 0.0:
		_die(target)


func _on_damaged(m: Unit, total: float) -> void:
	if not m.alive:
		return
	# Prayer of Mending
	var pom: Dictionary = m.get_aura("pom")
	if not pom.is_empty() and total > 0.0 and m.hp > 0.0:
		m.auras.erase(pom)
		_heal(m, pom["heal"], true, "prayer_of_mending")
		pom["charges"] -= 1
		if pom["charges"] > 0:
			var next := _random_member(m)
			if next != null:
				pom["remaining"] = 30.0
				next.auras.append(pom)
	var f := m.hp / m.max_hp
	if m.is_priest:
		return
	if f < 0.3 and "barkskin" in m.utils and not m.used.has("barkskin"):
		m.used["barkskin"] = true
		m.auras.append({"id": "barkskin", "name": "Barkskin", "remaining": 12.0, "dmg_taken": 0.7, "icon": "barkskin"})
		log_line.emit("%s uses Barkskin." % m.name)
	if f < 0.5 and "evasion" in m.utils and not m.used.has("evasion"):
		m.used["evasion"] = true
		m.auras.append({"id": "evasion", "name": "Evasion", "remaining": 8.0, "dmg_taken": 0.5, "icon": "evasion"})
		log_line.emit("%s uses Evasion." % m.name)
	if f < 0.2 and m.mod("last_stand") > 0.0 and not m.used.has("last_stand") and m.hp > 0.0:
		m.used["last_stand"] = true
		_heal_other(m, m.max_hp * m.mod("last_stand") / 100.0)
		log_line.emit("%s uses Last Stand!" % m.name)
	if f < 0.15 and m.mod("ice_block") > 0.0 and not m.used.has("ice_block") and m.hp > 0.0:
		m.used["ice_block"] = true
		m.auras.append({"id": "ice_block", "name": "Ice Block", "remaining": m.mod("ice_block"), "dmg_taken": 0.0,
			"desc": "Immune to damage.", "icon": "ice_block"})
		log_line.emit("%s uses Ice Block!" % m.name)
	if f < 0.3 and _party_has("healthstone") and not m.used.has("healthstone") and m.hp > 0.0:
		m.used["healthstone"] = true
		_heal_other(m, 50.0 * u * (1.0 + _group("healthstone_bonus") / 100.0))
		log_line.emit("%s eats a Healthstone." % m.name)
	elif f < 0.25 and healing_potions > 0 and not m.used.has("potion") and m.hp > 0.0:
		m.used["potion"] = true
		healing_potions -= 1
		potions_used["healing"] += 1
		_heal_other(m, healing_potion_amount)
		log_line.emit("%s drinks a healing potion." % m.name)


func _party_has(util: String) -> bool:
	for m in party:
		if m.alive and util in m.utils:
			return true
	return false


func _die(m: Unit) -> void:
	if m.is_priest and talents.get("spirit_of_redemption", 0) > 0 and not m.used.has("spirit"):
		m.used["spirit"] = true
		m.spirit = 10.0
		m.hp = 1.0
		m.auras = m.auras.filter(func(a): return not a.get("harmful", false))
		log_line.emit("[color=#fff4cf]You become a Spirit of Redemption![/color]")
		return
	if not m.is_priest and m.mod("cheat_death") > 0.0 and not m.used.has("cheat_death"):
		m.used["cheat_death"] = true
		if rng.randf() * 100.0 < m.mod("cheat_death"):
			m.hp = m.max_hp * 0.1
			floating.emit(m, "Cheat Death", "info")
			log_line.emit("[color=#fff569]%s cheats death![/color]" % m.name)
			return
	m.hp = 0.0
	m.alive = false
	m.auras.clear()
	stats["deaths"] += 1
	if m.is_priest:
		casting = {}
		log_line.emit("[color=#ff5050]You have died.[/color]")
		if soulstone:
			soulstone = false
			soulstone_used = true
			soulstone_timer = 3.0
	else:
		log_line.emit("[color=#ff5050]%s has died.[/color]" % m.name)
	for e in enemies:
		if e.target == m:
			e.target = _pick_tank()


# ---------------------------------------------------------------- tick

func tick(dt: float) -> void:
	if over:
		return
	time += dt
	_tick_priest(dt)
	for m in party:
		_tick_auras(m, dt)
	for e in enemies:
		_tick_auras(e, dt)
	_tick_party(dt)
	_tick_enemies(dt)
	_tick_lightwell(dt)
	_check_end(dt)


func _tick_priest(dt: float) -> void:
	since_spend += dt
	gcd = maxf(0.0, gcd - dt)
	silenced = maxf(0.0, silenced - dt)
	potion_cd = maxf(0.0, potion_cd - dt)
	innervate_time = maxf(0.0, innervate_time - dt)
	for k in cooldowns.keys():
		cooldowns[k] = maxf(0.0, cooldowns[k] - dt)
	if priest.alive:
		var r := regen
		if innervate_time > 0.0:
			r *= 4.0
		elif since_spend < FSR:
			r *= fsr_keep
		mana = minf(max_mana, mana + r * dt)
	if priest.spirit > 0.0:
		priest.spirit -= dt
		if priest.spirit <= 0.0:
			priest.spirit = 0.0
			_die(priest)
	if soulstone_timer > 0.0:
		soulstone_timer -= dt
		if soulstone_timer <= 0.0 and not priest.alive:
			priest.alive = true
			priest.hp = priest.max_hp * 0.4
			mana = maxf(mana, max_mana * 0.3)
			log_line.emit("[color=#9482c9]The Soulstone brings you back to life![/color]")
	if not casting.is_empty():
		if not priest.alive and priest.spirit <= 0.0:
			casting = {}
		elif casting.get("channel", false):
			casting["remaining"] -= dt
			casting["tick_timer"] += dt
			if casting["tick_timer"] >= 1.0:
				casting["tick_timer"] -= 1.0
				_channel_tick()
		else:
			casting["remaining"] -= dt
			if casting["remaining"] <= 0.0:
				_finish_cast()
	# Mana utilities from guildmates
	if priest.alive:
		var f := mana / max_mana
		if f < 0.35 and _party_has("innervate") and not priest.used.has("innervate"):
			priest.used["innervate"] = true
			innervate_time = 10.0
			log_line.emit("[color=#ff7d0a]A druid Innervates you.[/color]")


func _tick_auras(unit: Unit, dt: float) -> void:
	if not unit.alive:
		return
	for au in unit.auras.duplicate():
		au["remaining"] -= dt
		if au.has("period"):
			au["tick_timer"] -= dt
			if au["tick_timer"] <= 0.0:
				au["tick_timer"] += au["period"]
				if au.has("heal"):
					var amt: float = au["heal"]
					if au.get("mine", false):
						amt *= _mult(unit, "heal_taken")
						var eff := minf(amt, unit.max_hp - unit.hp)
						unit.hp += eff
						stats["healing"] += eff
						stats["overheal"] += amt - eff
						priest.healing_done += eff
						floating.emit(unit, "+%d" % int(amt), "hot")
						_log_heal(au["name"], unit, amt, eff, false)
					else:
						_heal_other(unit, amt)
				elif au.has("pdot"):
					# A guildmate's damage over time on an enemy
					var amt: float = au["pdot"] * rng.randf_range(0.95, 1.05)
					var src: Unit = au.get("source")
					_damage_enemy(unit, amt, src)
					if au.get("leech", 0.0) > 0.0 and src != null and src.alive:
						_heal_other(src, amt * au["leech"] / 100.0)
					if not unit.alive:
						return
				elif au.has("dot"):
					var src = au.get("source")
					damage(unit, au["dot"], src, au["name"] if src != null and src.alive else "")
					if not unit.alive:
						return
		if au["remaining"] <= 0.0 and unit.auras.has(au):
			unit.auras.erase(au)
			if au.has("bomb"):
				log_line.emit("[color=#ff8000]%s explodes![/color]" % au["name"])
				for m in alive_party():
					damage(m, au["bomb"], au.get("source"))


func _tick_party(dt: float) -> void:
	var targets := alive_enemies()
	if targets.is_empty():
		return
	for m in party:
		if not m.alive or m.is_priest or (m.cc() and not _break_free(m)):
			continue
		_tick_skills(m, targets, dt)
		targets = alive_enemies()
		if targets.is_empty():
			return
		m.attack_timer -= dt
		if m.attack_timer <= 0.0:
			# Haste makes hits come sooner; each hit still carries a full interval's worth of damage.
			var interval := rng.randf_range(1.6, 2.4)
			m.attack_timer += interval / maxf(0.5, 1.0 + (m.mod("haste") + _aura_sum(m, "haste")) / 100.0)
			var e := _attack_target(m, targets)
			if e != null:
				var dmg: float = m.dps * m.white * u * interval * _mult(m, "dps_mult") * rng.randf_range(0.85, 1.15)
				dmg *= _hit_mult(m, e, targets.size())
				if rng.randf() * 100.0 < _crit_chance(m):
					dmg *= 2.0 + m.mod("crit_dmg") / 100.0
				if _windfury_proc():
					dmg *= 2.0
				if m.mod("extra_attack") > 0.0 and rng.randf() * 100.0 < m.mod("extra_attack"):
					dmg *= 2.0
				if m.mod("leech") > 0.0:
					m.hp = minf(m.max_hp, m.hp + dmg * m.mod("leech") / 100.0)
				_damage_enemy(e, dmg, m)
				if not e.alive:
					targets = alive_enemies()
					if targets.is_empty():
						return
	# Cleansing utilities
	cleanse_timer -= dt
	if cleanse_timer <= 0.0:
		cleanse_timer = 6.0
		if _party_has("poison_cleansing"):
			_auto_cleanse("poison", "Poison Cleansing Totem")
	decurse_timer -= dt
	if decurse_timer <= 0.0:
		decurse_timer = 6.0
		if _party_has("remove_curse"):
			_auto_cleanse("curse", "Remove Curse")


func _auto_cleanse(type: String, label: String) -> void:
	for m in alive_party():
		for au in m.auras:
			if au.get("dispel", "") == type and au.get("harmful", false):
				m.auras.erase(au)
				floating.emit(m, label, "info")
				return


func _attack_target(m: Unit, targets: Array) -> Unit:
	if m.role == "tank":
		for e in targets:
			if e.target == m:
				return e
	if focus != null and focus.alive:
		return focus
	return targets[0]


func _aura_sum(unit: Unit, key: String) -> float:
	var s := 0.0
	for au in unit.auras:
		s += au.get(key, 0.0)
	return s


## Damage multiplier for one hit from situational effects (opener, bosses, packs, low targets).
func _hit_mult(m: Unit, e: Unit, enemy_count: int) -> float:
	var bonus := 0.0
	if time < OPENER_TIME:
		bonus += m.mod("opener")
	if e.is_boss:
		bonus += m.mod("boss")
	if enemy_count >= 3:
		bonus += m.mod("aoe")
	if enemy_count >= 2:
		bonus += _aura_sum(m, "aoe_pct")
	if e.frac() < 0.25:
		bonus += m.mod("execute")
	return maxf(0.1, 1.0 + bonus / 100.0)


func _crit_chance(m: Unit) -> float:
	return m.crit_base + m.mod("crit") + _group("party_crit") + _aura_sum(m, "crit_bonus")


## One second of a guildmate's damage, the unit their abilities' damage is measured in. Like auto
## attacks it is scaled by `white`, so that at base values abilities split damage rather than add to it.
func _second(m: Unit) -> float:
	return m.dps * m.white * u * _mult(m, "dps_mult")


# ---------------------------------------------------------------- guildmate abilities

## Uses at most one damage ability per global cooldown (when it's off cooldown and useful),
## and reactive ones (defensives, heals, taunts) whenever they're needed.
func _tick_skills(m: Unit, targets: Array, dt: float) -> void:
	m.skill_gcd -= dt
	for sk in m.skills:
		if sk["ready"] > time or sk["kind"] in ["interrupt", "break_cc"]:
			continue
		var reactive: bool = sk["kind"] in REACTIVE
		if not reactive and m.skill_gcd > 0.0:
			continue
		if _use_skill(m, sk, targets):
			sk["ready"] = time + sk["cd"]
			if not reactive:
				m.skill_gcd = SKILL_GCD
				return


func _use_skill(m: Unit, sk: Dictionary, targets: Array) -> bool:
	var n := targets.size()
	match sk["kind"]:
		"strike":
			var e := _attack_target(m, targets)
			if e == null:
				return false
			_skill_hit(m, sk, e, n)
		"execute":
			var e := _attack_target(m, targets)
			if e == null or e.frac() >= sk["at"]:
				e = null
				for x in targets:
					if x.frac() < sk["at"]:
						e = x
						break
			if e == null:
				return false
			_skill_hit(m, sk, e, n)
		"dot":
			var e := _attack_target(m, targets)
			# Not worth it on an enemy about to die.
			if e == null or (not e.is_boss and e.frac() < 0.15):
				return false
			var aura := {"id": "dot_%s_%d" % [sk["id"], m.uid], "name": sk["name"], "remaining": sk["dur"],
				"period": DOT_PERIOD, "tick_timer": DOT_PERIOD, "source": m, "harmful": true, "icon": sk["id"],
				"kind": "guild", "dispel": "", "leech": sk.get("leech", 0.0),
				"pdot": _second(m) * sk["coef"] * _hit_mult(m, e, n) * DOT_PERIOD / sk["dur"],
				"desc": "%s's %s: damage every %d sec." % [m.name, sk["name"], int(DOT_PERIOD)]}
			_debuff_fields(aura, sk.get("debuff", {}))
			e.remove(aura["id"])
			e.auras.append(aura)
			combat_log.emit("guild", "%s's [color=#%s]%s[/color] afflicts %s." % [m.name, LOG_GUILD, sk["name"], e.name])
		"aoe":
			# Against a lone enemy, only to keep the ability's debuff up (Thunder Clap on a boss).
			if n < 2:
				var cur: Dictionary = targets[0].get_aura("debuff_" + sk["id"])
				if not sk.has("debuff") or (not cur.is_empty() and cur["remaining"] > 2.0):
					return false
			var hit := 0
			for e in targets.duplicate():
				if hit >= sk.get("max", 6):
					break
				_skill_hit(m, sk, e, n)
				hit += 1
		"burst":
			var aura := {"id": "skill_" + sk["id"], "name": sk["name"], "remaining": sk["dur"], "icon": sk["id"],
				"dps_mult": 1.0 + sk.get("pct", 0.0) / 100.0, "haste": sk.get("haste", 0.0),
				"crit_bonus": sk.get("crit", 0.0), "aoe_pct": sk.get("aoe", 0.0), "desc": SpecTalents.burst_effects(sk) + "."}
			m.remove(aura["id"])
			m.auras.append(aura)
			_announce(m, sk)
		"debuff", "debuff_all":
			var pool: Array = targets if sk["kind"] == "debuff_all" else [_attack_target(m, targets)]
			var applied := false
			for e in pool:
				if e == null:
					continue
				var cur: Dictionary = e.get_aura("debuff_" + sk["id"])
				if not cur.is_empty() and cur["remaining"] > 3.0:
					continue
				_apply_debuff(m, sk, e, sk["dur"])
				applied = true
			if not applied:
				return false
			_announce(m, sk)
		"stun":
			var e := _stun_target(targets)
			if e == null:
				return false
			_stun(m, sk, e)
		"stun_all":
			var pool := targets.filter(func(x): return not x.is_boss and not x.cc())
			if pool.size() < 2:
				return false
			for e in pool:
				_stun(m, sk, e)
		"taunt":
			for e in targets:
				var t = e.target
				if t != null and t != m and t.alive and t.role != "tank":
					e.target = m
					floating.emit(e, sk["name"], "info")
					combat_log.emit("guild", "%s [color=#%s]%s[/color]s %s off %s." % [m.name, LOG_GUILD, sk["name"], e.name,
						"you" if t.is_priest else t.name])
					return true
			return false
		"defensive":
			if m.frac() >= sk["at"]:
				return false
			m.auras.append({"id": "skill_" + sk["id"], "name": sk["name"], "remaining": sk["dur"], "icon": sk["id"],
				"dmg_taken": maxf(0.0, 1.0 - sk["pct"] / 100.0), "desc": "Takes %d%% less damage." % int(sk["pct"])})
			_announce(m, sk)
		"self_heal":
			if m.frac() >= sk["at"]:
				return false
			_heal_other(m, m.max_hp * sk["pct"] / 100.0)
			_announce(m, sk)
		"shield":
			if m.has("skill_" + sk["id"]):
				return false
			m.auras.append({"id": "skill_" + sk["id"], "name": sk["name"], "remaining": 30.0, "icon": sk["id"],
				"absorb": m.max_hp * sk["pct"] / 100.0})
		"feign":
			if m.role == "tank" or m.frac() >= sk["at"]:
				return false
			var chased := targets.filter(func(x): return x.target == m)
			if chased.is_empty():
				return false
			for e in chased:
				var other := _pick_tank()
				e.target = other if other != m else null
			_announce(m, sk)
		_:
			return false
	return true


## A strike, execute or area hit: crits, Windfury, leech and the ability's debuff.
func _skill_hit(m: Unit, sk: Dictionary, e: Unit, enemy_count: int) -> void:
	var dmg: float = _second(m) * sk["coef"] * rng.randf_range(0.9, 1.1) * _hit_mult(m, e, enemy_count)
	var is_crit := rng.randf() * 100.0 < _crit_chance(m)
	if is_crit:
		dmg *= 2.0 + m.mod("crit_dmg") / 100.0
	if _windfury_proc():
		dmg *= 2.0
	_damage_enemy(e, dmg, m, sk["name"], is_crit)
	if sk.has("leech"):
		_heal_other(m, dmg * sk["leech"] / 100.0)
	if sk.has("debuff") and e.alive:
		_apply_debuff(m, sk, e, sk["debuff"].get("dur", 10.0))


func _apply_debuff(m: Unit, sk: Dictionary, e: Unit, dur: float) -> void:
	var aura := {"id": "debuff_" + sk["id"], "name": sk["name"], "remaining": dur, "harmful": true,
		"icon": sk["id"], "kind": "guild", "dispel": "", "source": m}
	_debuff_fields(aura, sk.get("debuff", {}))
	# The same debuff from two guildmates doesn't stack: the newest replaces the other.
	e.remove(aura["id"])
	e.auras.append(aura)


func _debuff_fields(aura: Dictionary, d: Dictionary) -> void:
	var desc := []
	if d.has("vuln"):
		aura["dmg_taken"] = 1.0 + d["vuln"] / 100.0
		desc.append("Takes %s%% more damage." % SpecTalents.number(d["vuln"]))
	if d.has("weaken"):
		aura["dmg_done"] = 1.0 - d["weaken"] / 100.0
		desc.append("Deals %s%% less damage." % SpecTalents.number(d["weaken"]))
	if d.has("anti_heal"):
		aura["heal_taken"] = 1.0 - d["anti_heal"] / 100.0
		desc.append("Healing received reduced by %d%%." % int(d["anti_heal"]))
	if not desc.is_empty():
		aura["desc"] = " ".join(desc)


## The best enemy to stun: one casting, then one attacking someone other than a tank. Bosses are immune.
func _stun_target(targets: Array) -> Unit:
	var best: Unit = null
	var best_score := 0
	for e in targets:
		if e.is_boss or e.cc():
			continue
		var score := 1
		if not e.cast.is_empty():
			score = 3
		elif e.target != null and e.target.role != "tank":
			score = 2
		if score > best_score:
			best = e
			best_score = score
	return best


func _stun(m: Unit, sk: Dictionary, e: Unit) -> void:
	e.remove("stun")
	e.auras.append({"id": "stun", "name": sk["name"], "remaining": sk["dur"], "cc": true, "harmful": true,
		"icon": sk["id"], "kind": "guild", "dispel": "", "desc": "Stunned."})
	if not e.cast.is_empty():
		e.cast = {}
	floating.emit(e, "Stunned", "info")
	combat_log.emit("guild", "%s's [color=#%s]%s[/color] stuns %s." % [m.name, LOG_GUILD, sk["name"], e.name])


func _announce(m: Unit, sk: Dictionary) -> void:
	combat_log.emit("guild", "%s uses [color=#%s]%s[/color]." % [m.name, LOG_GUILD, sk["name"]])


## Will of the Forsaken: a feared or mind-controlled guildmate breaks free. Returns whether they did.
func _break_free(m: Unit) -> bool:
	var sk := _ready_skill(m, "break_cc")
	if sk.is_empty():
		return false
	sk["ready"] = time + sk["cd"]
	m.auras = m.auras.filter(func(a): return not a.get("cc", false))
	floating.emit(m, sk["name"], "info")
	_announce(m, sk)
	return true


func _ready_skill(m: Unit, kind: String) -> Dictionary:
	for sk in m.skills:
		if sk["kind"] == kind and sk["ready"] <= time:
			return sk
	return {}


func _tick_enemies(dt: float) -> void:
	for e in enemies.duplicate():
		if not e.alive:
			continue
		if e.enrage_at > 0.0 and not e.enraged and e.hp / e.max_hp < e.enrage_at:
			e.enraged = true
			log_line.emit("[color=#ff8000]%s becomes enraged![/color]" % e.name)
		if e.berserk > 0.0 and time > e.berserk and not e.used.has("berserk"):
			e.used["berserk"] = true
			log_line.emit("[color=#ff3030]%s goes berserk![/color]" % e.name)
		# Targeting
		if e.target == null or not e.target.alive:
			e.target = _pick_tank()
		e.retarget_timer -= dt
		if e.retarget_timer <= 0.0:
			e.retarget_timer = rng.randf_range(4.0, 7.0)
			_retarget(e)
		if e.target == null or e.cc():
			continue
		# Casting an ability
		if not e.cast.is_empty():
			e.cast["remaining"] -= dt
			if e.cast["remaining"] <= 0.0:
				var ab: Dictionary = e.cast["ability"]
				var tgt = e.cast.get("target")
				e.cast = {}
				_use_ability(e, ab, tgt)
			continue
		# Melee swings
		e.swing_timer -= dt
		if e.swing_timer <= 0.0:
			e.swing_timer += e.swing_speed * (0.75 if e.enraged else 1.0)
			damage(e.target, e.swing * rng.randf_range(0.85, 1.15), e)
		# Abilities
		for ab in e.abilities:
			ab["timer"] -= dt
			if ab["timer"] <= 0.0 and e.cast.is_empty():
				ab["timer"] = ab["cd"] * rng.randf_range(0.85, 1.15)
				var tgt := _ability_target(e, ab)
				if ab["cast"] > 0.0 and _try_interrupt(e, ab):
					break
				if ab["cast"] > 0.0:
					e.cast = {"ability": ab, "remaining": ab["cast"], "total": ab["cast"], "target": tgt}
					if ab["kind"] in ["aoe", "fear", "bomb"] or e.is_boss:
						log_line.emit("%s begins to cast [color=#ff9a3c]%s[/color]." % [e.name, ab["name"]])
				else:
					_use_ability(e, ab, tgt)
				break


## A guildmate stops an enemy cast before it starts: with an interrupt ability that's ready (if the
## spell can be interrupted), or by chance with an interrupt effect (8 sec cooldown each).
func _try_interrupt(e: Unit, ab: Dictionary) -> bool:
	if ab.get("interruptible", true):
		for m in party:
			if not m.alive or m.is_priest or m.cc():
				continue
			var sk := _ready_skill(m, "interrupt")
			if sk.is_empty():
				continue
			sk["ready"] = time + sk["cd"]
			if sk.has("coef"):
				_skill_hit(m, sk, e, alive_enemies().size())
			floating.emit(e, "Interrupted", "info")
			log_line.emit("[color=#ffd86b]%s[/color] interrupts %s with %s!" % [m.name, _spell_of(e, ab), sk["name"]])
			return true
	for m in party:
		if not m.alive or m.is_priest or m.cc() or m.mod("interrupt") <= 0.0:
			continue
		if m.used.get("interrupt_ready", 0.0) > time:
			continue
		if rng.randf() * 100.0 < m.mod("interrupt"):
			m.used["interrupt_ready"] = time + INTERRUPT_COOLDOWN
			floating.emit(e, "Interrupted", "info")
			log_line.emit("[color=#ffd86b]%s[/color] interrupts %s!" % [m.name, _spell_of(e, ab)])
			return true
	return false


## "the Defias Pillager's Fireball", or just "Lucifron's Curse" when the spell already names its caster.
func _spell_of(e: Unit, ab: Dictionary) -> String:
	var nm: String = ab["name"]
	return nm if nm.begins_with(e.name) else "%s's %s" % [e.name, nm]


func _retarget(e: Unit) -> void:
	if e.is_boss:
		return
	var holder: Unit = e.target
	var t := tank()
	if holder != null and holder.role == "tank":
		if rng.randf() > holder.aggro:
			var other := _random_member(holder)
			if other != null:
				if "feign_death" in other.utils and rng.randf() < 0.7:
					return
				e.target = other
	elif t != null and rng.randf() < t.aggro:
		e.target = t
	elif holder == null or rng.randf() < 0.25:
		e.target = _pick_tank()


func _ability_target(e: Unit, ab: Dictionary) -> Unit:
	match ab["kind"]:
		"bolt", "charge", "poison", "disease", "curse", "magic_dot", "bomb":
			return _random_member(null, true)
		"hex":
			var pool := alive_party().filter(func(m): return not m.is_priest and not m.cc())
			return pool[rng.randi() % pool.size()] if not pool.is_empty() else null
		"heal":
			var low: Unit = null
			for x in alive_enemies():
				if low == null or x.frac() < low.frac():
					low = x
			return low
	return e.target


func _use_ability(e: Unit, ab: Dictionary, tgt) -> void:
	if not e.alive:
		return
	var amt: float = ab["amount"] * rng.randf_range(0.9, 1.1)
	var nm: String = ab["name"]
	match ab["kind"]:
		"bolt", "charge", "mortal":
			if tgt == null or not tgt.alive:
				tgt = _random_member()
			if tgt != null:
				damage(tgt, amt, e, nm)
				if ab["kind"] == "mortal" and tgt.alive:
					tgt.remove("mortal")
					tgt.auras.append({"id": "mortal", "name": nm, "remaining": 6.0, "heal_taken": 0.5, "harmful": true, "icon": "mortal", "dispel": "", "kind": "mortal"})
		"cleave", "breath":
			var hit := [e.target]
			for i in 2:
				var o := _random_member(e.target)
				if o != null and not (o in hit) and not o.is_priest:
					hit.append(o)
			for m in hit:
				damage(m, amt, e, nm)
		"aoe":
			for m in alive_party():
				damage(m, amt * rng.randf_range(0.9, 1.1), e, nm)
		"bleed", "poison", "disease", "curse", "magic_dot":
			var m: Unit = e.target if ab["kind"] == "bleed" else tgt
			if m != null and m.alive:
				m.remove("dot_" + nm)
				m.auras.append({"id": "dot_" + nm, "name": nm, "remaining": Encounters.DOT_TICKS * Encounters.DOT_PERIOD,
					"period": Encounters.DOT_PERIOD, "tick_timer": Encounters.DOT_PERIOD, "dot": amt, "source": e,
					"dispel": ab.get("dispel", ""), "harmful": true, "icon": "debuff", "kind": ab["kind"]})
		"bomb":
			if tgt != null:
				tgt.auras.append({"id": "bomb_" + str(e.uid), "name": nm, "remaining": ab.get("delay", 6.0), "bomb": amt,
					"source": e, "harmful": true, "dispel": "", "icon": "bomb", "kind": "bomb"})
				log_line.emit("[color=#ff8000]%s[/color] is afflicted by %s!" % [tgt.name, nm])
		"fear":
			for m in alive_party():
				if not m.is_priest:
					m.remove("fear")
					m.auras.append({"id": "fear", "name": nm, "remaining": 3.0, "cc": true, "harmful": true, "dispel": "", "icon": "fear", "kind": "fear"})
			log_line.emit("%s's %s scatters the party!" % [e.name, nm])
		"hex":
			if tgt != null:
				tgt.remove("hex")
				tgt.auras.append({"id": "hex", "name": nm, "remaining": 7.0, "cc": true, "harmful": true, "dispel": "magic", "icon": "hex", "kind": "hex"})
				log_line.emit("[color=#3c8cff]%s[/color] is under %s. Dispel it!" % [tgt.name, nm])
		"silence":
			if not casting.is_empty():
				casting = {}
				silenced = 3.0
				log_line.emit("[color=#ff5050]%s interrupts your spell! (%s)[/color]" % [e.name, nm])
				floating.emit(priest, "Interrupted", "damage")
			else:
				silenced = 1.5
		"mana_burn":
			var burn: float = max_mana * ab["amount"]
			mana = maxf(0.0, mana - burn)
			floating.emit(priest, "-%d mana" % int(burn), "mana_burn")
			log_line.emit("%s's %s burns your mana." % [e.name, nm])
		"heal":
			if tgt != null and tgt.alive:
				var h: float = tgt.max_hp * ab["amount"] * (1.0 - _group("anti_heal") / 100.0) * _mult(tgt, "heal_taken")
				tgt.hp = minf(tgt.max_hp, tgt.hp + h)
				log_line.emit("%s heals %s with %s." % [e.name, tgt.name, nm])
		"summon":
			var alive_count := alive_enemies().size()
			for i in ab.get("count", 1):
				if alive_count >= 6:
					break
				var add: Dictionary = ab["add"].duplicate()
				_spawn(add)
				alive_count += 1
			log_line.emit("%s summons [color=#ffd100]%s[/color]!" % [e.name, nm])


func _tick_lightwell(dt: float) -> void:
	if lightwell.is_empty():
		return
	lightwell["remaining"] -= dt
	lightwell_tick -= dt
	if lightwell["remaining"] <= 0.0 or lightwell["charges"] <= 0:
		lightwell = {}
		return
	if lightwell_tick <= 0.0:
		lightwell_tick = 1.0
		for m in alive_party():
			if m.frac() < 0.5 and not m.has("lightwell_renew"):
				var per: float = _base_heal("lightwell") / 3.0
				m.auras.append({"id": "lightwell_renew", "name": "Lightwell Renew", "remaining": 6.0, "period": 2.0,
					"tick_timer": 2.0, "heal": per, "icon": "lightwell", "mine": true})
				lightwell["charges"] -= 1
				return


func _check_end(dt: float) -> void:
	if alive_enemies().is_empty():
		over = true
		won = true
		casting = {}
		ended.emit(true)
		return
	var members_alive := false
	for m in party:
		if m.alive and not m.is_priest:
			members_alive = true
	var priest_down := not priest.alive and soulstone_timer <= 0.0
	if priest_down:
		priest_dead_for += dt
	if not members_alive or (priest_down and priest_dead_for > 1.0):
		over = true
		won = false
		casting = {}
		ended.emit(false)
