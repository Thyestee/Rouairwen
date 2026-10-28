class_name Tiers
## Guildmate grades from F to SSS+. The grade multiplies a guildmate's damage
## (and, square-rooted, their health), and the guild hall decides which grades show up, up to A.
##
## Training raises a guildmate one grade at a time: gold up to A, gold and prestige past it.
## Some grades unlock more than damage: B a random perk (crit or damage), A a class spell,
## S a racial spell (see SpecTalents.CLASS_SPELLS and RACE_SPELLS).

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


static func power(t: int) -> float:
	return 1.0 + 0.075 * t


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
