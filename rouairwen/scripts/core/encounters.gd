class_name Encounters
## Turns a fight description into enemy stat blocks for the combat engine.
##
## Enemy health is sized so a party whose power matches the content difficulty kills it in
## a target time; enemy damage scales with the square root of the difficulty, matching how
## guildmate health scales with their power.

const FIGHT_TIME := {"pack": 48.0, "elite": 62.0, "boss": 80.0, "raid_boss": 100.0}
const INCOMING_MULT := {"pack": 1.15, "elite": 1.05, "boss": 1.0, "raid_boss": 0.93}

## Cooldown, cast time and whether the ability has a damage budget.
const KINDS := {
	"bolt": {"cd": 7.0, "cast": 2.0, "dmg": true},
	"cleave": {"cd": 8.0, "cast": 0.0, "dmg": true},
	"breath": {"cd": 9.0, "cast": 0.0, "dmg": true},
	"aoe": {"cd": 13.0, "cast": 1.5, "dmg": true},
	"charge": {"cd": 10.0, "cast": 0.0, "dmg": true},
	"bleed": {"cd": 12.0, "cast": 0.0, "dmg": true},
	"poison": {"cd": 13.0, "cast": 0.0, "dmg": true},
	"disease": {"cd": 14.0, "cast": 0.0, "dmg": true},
	"curse": {"cd": 15.0, "cast": 1.0, "dmg": true},
	"magic_dot": {"cd": 13.0, "cast": 1.0, "dmg": true},
	"mortal": {"cd": 11.0, "cast": 0.0, "dmg": true},
	"bomb": {"cd": 24.0, "cast": 0.0, "dmg": true},
	"fear": {"cd": 24.0, "cast": 1.5, "dmg": false},
	"silence": {"cd": 19.0, "cast": 0.0, "dmg": false},
	"mana_burn": {"cd": 17.0, "cast": 1.5, "dmg": false},
	"heal": {"cd": 16.0, "cast": 2.5, "dmg": false},
	"hex": {"cd": 18.0, "cast": 1.5, "dmg": false},
	"summon": {"cd": 30.0, "cast": 1.0, "dmg": false},
}
const DOT_TICKS := 4
## How much enemies grow with expected guildmate talents (see talent_hp_scale).
const TALENT_HP := 0.42
const TALENT_HP_PER_MEMBER := 0.02
const TALENT_DAMAGE := 0.25
const DOT_PERIOD := 3.0


## Share of their talent points guildmates are expected to have at a level (0 below 10, 1 at 45+).
static func talent_frac(level: int) -> float:
	return float(SpecTalents.points_at(level)) / SpecTalents.MAX_POINTS


## Enemies get tougher as guildmates gain talents, so a talented party at par feels like before.
## Bigger parties stack more party auras and enemy debuffs, hence the party-size term.
static func talent_hp_scale(level: int, party_size: int) -> float:
	return 1.0 + talent_frac(level) * (TALENT_HP + TALENT_HP_PER_MEMBER * party_size)


static func talent_damage_scale(level: int) -> float:
	return 1.0 + talent_frac(level) * TALENT_DAMAGE


## fight: {"type": "pack"|"elite"|"boss"|"raid_boss", "mobs": [[name, abilities]], "boss": {name, abilities, enrage?}}
static func build(fight: Dictionary, level: int, diff: float, party_size: int, rng: RandomNumberGenerator) -> Array:
	var type: String = fight["type"]
	var u := Balance.scale(level)
	var r := Balance.ramp(level)
	var n := maxi(party_size, 3)
	var t: float = FIGHT_TIME[type] * (1.2 if fight.get("final", false) and type == "raid_boss" else 1.0)
	var dps_ref := (n - 1) * 14.0 * diff
	var total_hp := dps_ref * t * u * (0.65 + 0.35 * r) * talent_hp_scale(level, n)
	var incoming: float = (21.0 + 4.6 * n) * sqrt(diff) * u * r * INCOMING_MULT[type] * talent_damage_scale(level)

	var defs := []  # [name, abilities, weight, is_main, enrage]
	if fight.has("boss"):
		var b: Dictionary = fight["boss"]
		defs.append([b["name"], b.get("abilities", []), 4.0 if type != "elite" else 3.0, true, b.get("enrage", false)])
	for m in fight.get("mobs", []):
		defs.append([m[0], m[1], 1.0, false, false])
	var wsum := 0.0
	for d in defs:
		wsum += d[2]

	var out := []
	for d in defs:
		var share: float = d[2] / wsum
		var e := {
			"name": d[0], "max_hp": total_hp * share, "boss": d[3] and type in ["boss", "raid_boss"],
			"elite": d[3] or type != "pack", "swing_speed": 2.0 if d[3] else rng.randf_range(1.8, 2.3),
			"abilities": [], "enrage_at": 0.3 if d[4] else 0.0,
			"berserk": t * 2.6 if d[3] and type != "pack" else 0.0,
		}
		var dps_share := incoming * share
		var dmg_abilities := 0
		for a in d[1]:
			var kind: String = String(a).get_slice(":", 0)
			if KINDS.has(kind) and KINDS[kind]["dmg"]:
				dmg_abilities += 1
		var swing_frac := 1.0
		if dmg_abilities > 0:
			swing_frac = 0.5 if d[3] else 0.62
		e["swing"] = dps_share * swing_frac * e["swing_speed"]
		var abil_dps := 0.0
		if dmg_abilities > 0:
			abil_dps = dps_share * (1.0 - swing_frac) / dmg_abilities
		# Single hits are capped so nobody is taken from full to dead in a blink; the excess goes into melee.
		var burst_cap := 42.0 * sqrt(diff) * u * r
		for a in d[1]:
			var ab := make_ability(String(a), abil_dps, n, e, rng, d[3])
			if ab.is_empty():
				continue
			if ab["kind"] in ["bolt", "charge", "mortal", "cleave", "breath"] and ab["amount"] > burst_cap:
				var hits: float = 2.6 if ab["kind"] in ["cleave", "breath"] else 1.0
				e["swing"] += (ab["amount"] - burst_cap) * hits / ab["cd"] * e["swing_speed"]
				ab["amount"] = burst_cap
			e["abilities"].append(ab)
		out.append(e)
	return out


static func make_ability(code: String, abil_dps: float, n: int, owner: Dictionary, rng: RandomNumberGenerator, is_main: bool) -> Dictionary:
	var kind := code.get_slice(":", 0)
	var name := code.get_slice(":", 1) if code.contains(":") else kind.capitalize()
	if not KINDS.has(kind):
		return {}
	var k: Dictionary = KINDS[kind]
	var cd: float = k["cd"] * rng.randf_range(0.9, 1.15)
	var per_use := abil_dps * cd
	var ab := {"kind": kind, "name": name, "cd": cd, "timer": cd * rng.randf_range(0.35, 0.9), "cast": k["cast"], "amount": per_use}
	match kind:
		"aoe":
			ab["amount"] = per_use / n
			if is_main:
				ab["cast"] = 2.0
		"cleave", "breath":
			ab["amount"] = per_use / 2.6
		"bleed", "poison", "disease", "curse", "magic_dot":
			ab["amount"] = per_use / DOT_TICKS
			ab["dispel"] = {"bleed": "", "poison": "poison", "disease": "disease", "curse": "curse", "magic_dot": "magic"}[kind]
		"mortal":
			ab["amount"] = per_use
		"bomb":
			ab["amount"] = per_use / n
			ab["delay"] = 6.0
		"mana_burn":
			ab["amount"] = 0.07
		"heal":
			ab["amount"] = 0.12
		"summon":
			ab["add"] = {"name": name, "max_hp": owner["max_hp"] * (0.06 if is_main else 0.12),
				"swing": owner["swing"] * 0.18, "swing_speed": 2.0}
			ab["count"] = 2 if is_main else 1
	return ab
