class_name Missions
## Guild missions (garrison style): guildmates leave for 5 to 20 minutes of real time and come back
## with experience, and with spoils, unless the mission fails. The experience is set and shown on the
## board (30-50% of what the guild's level needs); the spoils, gold, gear or both, are a surprise
## rolled when they come back (see spoils()).
##
## Success comes from team power against the mission's requirement, plus counters: each threat a
## guildmate counters adds its share of +50%. At 150% the mission always succeeds, so a team that
## counters nothing must be 50% stronger than required, while countering every threat makes matching
## the requirement enough.

const BOARD_SIZE := 3
const MAX_ACTIVE := 3
const MIN_MINUTES := 5
const MAX_MINUTES := 20
const COUNTER_BONUS := 0.5

## Each threat lists what counters it: a member effect above 0, an ability kind, a role, a class, or a utility.
const THREATS := {
	"spellcasters": {"name": "Spellcasters", "desc": "Enemy casters weave dangerous spells.",
		"counter": "an interrupt (Kick, Pummel, Counterspell...)", "mods": ["interrupt"], "kinds": ["interrupt"]},
	"heavy_armor": {"name": "Heavy Armor", "desc": "Plate-clad foes shrug off blows.",
		"counter": "armor-breaking effects or a warrior", "mods": ["enemy_vuln"], "classes": ["warrior"]},
	"swarm": {"name": "Swarm", "desc": "Far too many enemies at once.",
		"counter": "area damage", "mods": ["aoe"], "kinds": ["aoe", "stun_all"]},
	"brute": {"name": "Brute", "desc": "A huge champion leads the enemy.",
		"counter": "a tank", "roles": ["tank"]},
	"poison": {"name": "Venom", "desc": "Spiders, scorpids and poisoned blades.",
		"counter": "a shaman or a druid", "classes": ["shaman", "druid"]},
	"curses": {"name": "Curses", "desc": "Witch doctors and warlocks lay curses.",
		"counter": "a mage or a druid", "utils": ["remove_curse"]},
	"ambush": {"name": "Ambush", "desc": "The enemy strikes first, from hiding.",
		"counter": "a hunter, a stun or someone quick to dodge", "classes": ["hunter"], "mods": ["dodge"], "kinds": ["stun"]},
	"race_against_time": {"name": "Race Against Time", "desc": "It must be done before reinforcements arrive.",
		"counter": "fast attackers, opening bursts or cooldowns", "mods": ["haste", "opener"], "kinds": ["burst"]},
	"overwhelming_force": {"name": "Overwhelming Force", "desc": "The enemy hits hard and keeps coming.",
		"counter": "party protection or weakening effects", "mods": ["party_mit", "enemy_dmg", "party_hp"], "kinds": ["debuff_all"]},
	"magic_wards": {"name": "Magic Wards", "desc": "Arcane and fel wards seal the way.",
		"counter": "a mage or a warlock", "classes": ["mage", "warlock"]},
}

const TEMPLATES := [
	["Escort the Kodo Caravan", "Guard a Horde caravan crossing %s."],
	["Scout %s", "Map enemy movements around %s and report back."],
	["Raid the Camp", "Strike an enemy camp near %s and seize its supplies."],
	["Recover Lost Relics", "Dig up relics the Horde lost near %s."],
	["Hunt the Beast", "A monstrous beast stalks %s. Bring back its hide."],
	["Hold the Line", "Reinforce the defenders of %s for a while."],
	["Burn the Supplies", "Destroy enemy stockpiles hidden around %s."],
	["Rescue the Captives", "Free Horde prisoners held near %s."],
	["Message for the Warchief", "Carry sealed orders through %s."],
	["Gather Reagents", "Collect rare herbs and reagents in %s for the guild's alchemist."],
]

## The experience a mission gives, as a share of what the guild's level needs (%).
const XP_SHARE := [30, 50]


## A mission near the player's level. `talent_factor` keeps the requirement on the recommended-power scale.
static func make(level: int, rng: RandomNumberGenerator, talent_factor: float) -> Dictionary:
	var zones := Zones.for_level(level)
	var z: Dictionary = zones[rng.randi() % zones.size()]
	var subs: Array = z["subzones"]
	var place: String = subs[rng.randi() % subs.size()]
	var tpl: Array = TEMPLATES[rng.randi() % TEMPLATES.size()]
	var minutes := rng.randi_range(MIN_MINUTES, MAX_MINUTES)
	var slots := 1 if minutes < 9 else (2 if minutes < 15 else 3)
	if rng.randf() < 0.25:
		slots = clampi(slots + (1 if rng.randf() < 0.5 else -1), 1, 3)
	var keys := THREATS.keys()
	keys.shuffle()
	var threats := keys.slice(0, slots)
	var mdiff := snappedf(rng.randf_range(0.9, 1.5), 0.05)
	var share := rng.randi_range(XP_SHARE[0], XP_SHARE[1])
	var rw := {"xp": int(Balance.xp_to_next(level) * share / 100.0), "xp_share": share}
	var title: String = tpl[0] % place if tpl[0].contains("%s") else tpl[0]
	return {
		"title": title, "text": tpl[1] % place, "place": "%s, %s" % [place, z["name"]], "level": level,
		"minutes": minutes, "slots": slots, "threats": threats,
		"required": int(round(100.0 * mdiff * talent_factor)), "diff": mdiff, "rewards": rw,
	}


## A successful mission's spoils, rolled when the guildmates come back: gold, gear or both (one chance
## in three each), more for longer and harder missions. {gold, items, ilvl_min, ilvl_max, rare_chance,
## epic_chance}, the gear keys only with gear.
static func spoils(mission: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var level: int = mission["level"]
	var minutes: int = mission["minutes"]
	var mdiff: float = mission["diff"]
	var kind := rng.randi() % 3
	var out := {}
	if kind != 1:
		out["gold"] = int(Balance.income(level) * minutes * mdiff * 0.9 * Balance.LOOT_RATE * rng.randf_range(0.7, 1.3))
	if kind != 0:
		out["items"] = (1 if minutes < 15 else 2) * Balance.LOOT_RATE
		out["ilvl_min"] = level
		out["ilvl_max"] = mini(level + 2, Balance.MAX_LEVEL + 2)
		out["rare_chance"] = clampf(0.1 + 0.3 * (mdiff - 0.9) + 0.012 * minutes, 0.0, 0.7)
		out["epic_chance"] = 0.03 + 0.05 * (mdiff - 0.9) if level >= 50 else 0.0
	return out


static func counters(threat_id: String, m: Dictionary, mods: Dictionary) -> bool:
	var t: Dictionary = THREATS[threat_id]
	var sp: Dictionary = ClassData.SPECS.get(m.get("spec", ""), {})
	for k in t.get("mods", []):
		if mods.get(k, 0.0) > 0.0:
			return true
	if t.has("kinds") and m.has("spec"):
		for a in SpecTalents.abilities_for(m["spec"], m.get("talents", {}), mods):
			if a["kind"] in t["kinds"]:
				return true
	if sp.get("role", "") in t.get("roles", []):
		return true
	if m.get("class", "") in t.get("classes", []):
		return true
	for u in t.get("utils", []):
		if u in sp.get("util", []):
			return true
	return false


## Who counters each threat: {threat_id: member name or ""}.
static func counter_map(mission: Dictionary, team: Array, mods_of: Callable) -> Dictionary:
	var out := {}
	for th in mission["threats"]:
		out[th] = ""
		for m in team:
			if counters(th, m, mods_of.call(m)):
				out[th] = m["name"]
				break
	return out


## {ratio, bonus, effective, chance}. `powers` are the team's member powers (1.0 = 100).
static func odds(mission: Dictionary, powers: Array, countered: int) -> Dictionary:
	var total := 0.0
	for p in powers:
		total += p
	var ratio: float = 100.0 * total / mission["slots"] / maxf(1.0, mission["required"])
	var bonus: float = COUNTER_BONUS * countered / maxf(1.0, mission["threats"].size())
	var effective: float = ratio + bonus
	var chance := clampf(effective - 0.5, 0.0, 1.0) if not powers.is_empty() else 0.0
	return {"ratio": ratio, "bonus": bonus, "effective": effective, "chance": chance}


static func now() -> float:
	return Time.get_unix_time_from_system()


static func time_left(active: Dictionary) -> float:
	return maxf(0.0, active["end"] - now())


static func clock(seconds: float) -> String:
	var s := int(ceil(seconds))
	return "%d:%02d" % [s / 60, s % 60]
