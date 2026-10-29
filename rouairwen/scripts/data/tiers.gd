class_name Tiers
## Guildmate grades from F to SSS+. A grade is how much a guildmate grows: each grade above F adds
## the stats their spec fights with (see GROWTH), mostly as extra gains every level, so a grade
## shows more and more as they level. The guild hall decides which grades show up, up to A.
##
## Training raises a guildmate one grade at a time: gold up to A, gold and prestige past it.
## Some grades unlock more: B a random perk (crit or damage), A a class spell, S a racial spell
## (see SpecTalents.CLASS_SPELLS and RACE_SPELLS).

const NAMES := ["F", "F+", "E", "E+", "D", "D+", "C", "C+", "B", "B+", "A", "A+", "S", "S+", "SS", "SS+", "SSS", "SSS+"]
const COLORS := [
	Color("8a8a8a"), Color("a3a3a3"),
	Color("e6e6e6"), Color("ffffff"),
	Color("4fd64f"), Color("1eff00"),
	Color("3d8cff"), Color("2fb4ff"),
	Color("a335ee"), Color("c45cff"),
	Color("ff8000"), Color("ffa040"),
	Color("ff3b3b"), Color("ff5c7a"),
	Color("ffd700"), Color("fff07a"),
	Color("4ff0ff"), Color("ff6bf0"),
]

const EXCEPTIONAL_CHANCE := 0.08
const EXCEPTIONAL_BONUS := 4.0
const SPREAD := 1.5

## Grades that unlock something besides damage.
const B := 8
const A := 10
const S := 12
## The best grade recruits can have, whatever the guild hall: the rest comes from training.
const RECRUIT_MAX := A
## Prestige to train past A, by starting grade (A -> A+ first).
const TRAIN_PRESTIGE := [25, 40, 60, 85, 115, 150, 190]
## The perk a guildmate gets on reaching B, picked at random.
const B_PERKS := [["Keen Edge", {"crit": 4}], ["Battle-Hardened", {"dps": 5}]]


static func count() -> int:
	return NAMES.size()


static func name_of(t: int) -> String:
	return NAMES[clampi(t, 0, NAMES.size() - 1)]


static func color_of(t: int) -> Color:
	return COLORS[clampi(t, 0, COLORS.size() - 1)]


## What grade t was worth when it multiplied damage: what its stats are tuned to give at level 60.
static func power(t: int) -> float:
	return 1.0 + 0.075 * t


## The stats each grade above F adds, by how the spec fights, as a share of the class's own gains:
## "attack" is whatever gives the class Attack Power (Strength, Agility, or both for rogues), "sp" a
## share of the level's Spell Damage reference, "def" Defense points per level.
## Agility is for crits here, so classes that already grow it for Attack Power skip it.
const GROWTH := {
	"physical": {"attack": 0.4, "sta": 0.35, "agi": 0.1},
	"spell": {"sp": 0.105, "int": 0.3, "sta": 0.35},
	"tank": {"sta": 0.42, "attack": 0.3, "def": 0.06},
}
## The stats a spec deals damage with ("attack", "sp") grow faster at the top grades, where gear
## adds the most of them too: grade t counts as damage_steps(t) steps.
const DAMAGE_STATS := ["attack", "sp"]


static func damage_steps(t: int) -> float:
	return t * (0.955 + 0.00275 * t * t)


## How a spec fights, for its growth: "physical", "spell" or "tank".
static func growth_kind(spec_id: String) -> String:
	var sp: Dictionary = ClassData.SPECS[spec_id]
	if sp["role"] == "tank":
		return "tank"
	return "spell" if sp["stat"] == "spell" else "physical"


## A level's worth of growth, in multiples of the class's level-1 stats: a quarter from the start,
## then 9% a level, like the stats themselves (Stats.level_factor) without their first point.
static func gains(level: int) -> float:
	return 0.25 + 0.09 * (level - 1)


## The stats grade t adds to a guildmate of this spec at this level.
static func stats(spec_id: String, t: int, level: int) -> Dictionary:
	var out := {}
	if t <= 0:
		return out
	var cls := ClassData.class_of(spec_id)
	var base: Dictionary = Stats.TEMPLATES.get(cls, Stats.TEMPLATES["warrior"])
	var apf: Array = Stats.AP_FROM.get(cls, [1, 0])
	var g := gains(level)
	var growth: Dictionary = GROWTH[growth_kind(spec_id)]
	for k in growth:
		var r: float = growth[k] * (damage_steps(t) if k in DAMAGE_STATS else float(t))
		match k:
			"attack":
				if apf[0] > 0:
					out["str"] = out.get("str", 0.0) + r * base["str"] * g
				if apf[1] > 0:
					out["agi"] = out.get("agi", 0.0) + r * base["agi"] * g
			"agi":
				if apf[1] == 0:
					out["agi"] = out.get("agi", 0.0) + r * base["agi"] * g
			"sp":
				out["sp"] = r * Stats.spell_power_ref(level) * g / Stats.level_factor(level)
			"def":
				out["def"] = r * level
			_:
				out[k] = out.get(k, 0.0) + r * base[k] * g
	return out


## "+412 Strength, +318 Stamina": a grade's stats as text, biggest first.
static func stats_text(stats: Dictionary) -> String:
	var keys := stats.keys()
	keys.sort_custom(func(a, b): return stats[a] > stats[b])
	var parts := []
	for k in keys:
		if stats[k] >= 1.0:
			parts.append("+%d %s" % [int(round(stats[k])), Stats.NAMES[k]])
	return ", ".join(parts)


static func mean_for_hall(hall: int) -> float:
	return 1.0 + 1.2 * (hall - 1)


static func cap_for_hall(hall: int) -> int:
	return mini(RECRUIT_MAX, 3 + 2 * (hall - 1))


static func is_max(t: int) -> bool:
	return t >= NAMES.size() - 1


## Gold to train from grade t to t + 1, priced on the guild's level like every other cost.
static func train_gold(level: int, t: int) -> int:
	return int(round(Balance.income(level) * (2.0 + 1.1 * t)))


## Prestige to train from grade t to t + 1 (none up to A).
static func train_prestige(t: int) -> int:
	if t < A or is_max(t):
		return 0
	return TRAIN_PRESTIGE[t - A]


## What reaching grade t unlocks besides damage: "perk", "class", "race" or "".
static func unlock_at(t: int) -> String:
	match t:
		B:
			return "perk"
		A:
			return "class"
		S:
			return "race"
	return ""


## Rolls a candidate grade for a guild hall level.
static func roll(hall: int, rng: RandomNumberGenerator) -> int:
	var mean := mean_for_hall(hall)
	if rng.randf() < EXCEPTIONAL_CHANCE:
		mean += EXCEPTIONAL_BONUS
	var t := int(round(rng.randfn(mean, SPREAD)))
	return clampi(t, 0, cap_for_hall(hall))
