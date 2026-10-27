class_name Balance
## Core numbers: level scaling, experience, gold income and prices.
##
## Every combat number is expressed in "units" that are multiplied by scale(level),
## so a fight at level 12 plays like a fight at level 48, only with bigger numbers.

const MAX_LEVEL := 60
const GROWTH := 1.06

## Classic experience needed to go from a level to the next one.
const XP_TABLE := [0,
	400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,
	8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
	25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,
	50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,
	95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,
	153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800]

## Guild hall: player level needed to build each hall level (index = hall level).
const HALL_LEVEL_REQ := [0, 1, 6, 12, 18, 24, 30, 38, 46, 54, 60]
const HALL_MAX := 10
const HALL_NAMES := ["", "Rented Hut", "Hide Tent", "Spiked Longhouse", "Warband Lodge", "Guild Barracks",
	"Hall of Embers", "Sunlit Hall", "Hall of the Lumens", "Radiant Bastion", "Citadel of Dawn"]

## Talent point schedule: one point per level from 10 to 60.
const TALENT_START_LEVEL := 10


static func scale(level: float) -> float:
	return pow(GROWTH, level - 1.0)


## Items keep scaling past level 60 (raid item levels), but linearly.
static func item_scale(ilvl: int) -> float:
	if ilvl <= MAX_LEVEL:
		return scale(ilvl)
	return scale(MAX_LEVEL) * (1.0 + 0.03 * (ilvl - MAX_LEVEL))


## Early levels hit softer so level 1 is playable with only Lesser Heal and Smite.
static func ramp(level: float) -> float:
	return clampf(0.62 + 0.038 * level, 0.0, 1.0)


static func xp_to_next(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return XP_TABLE[level]


## Average number of won fights needed per level; tuned for ~20 hours to reach 60.
static func fights_per_level(level: int) -> float:
	return 4.5 + 0.75 * level


static func xp_per_fight(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return int(round(xp_to_next(level) / fights_per_level(level)))


## Experience falls off when the content is far below the party.
static func xp_level_factor(player_level: int, content_level: int) -> float:
	var gap := player_level - content_level
	if gap <= 2:
		return 1.0
	return maxf(0.1, 1.0 - 0.18 * (gap - 2))


## Copper earned per won fight at a content level: the "gold unit" every price is built from.
static func income(level: int) -> int:
	return int(round(12.0 * pow(scale(level), 1.45)))


static func talent_points_at(level: int) -> int:
	return maxi(0, level - TALENT_START_LEVEL + 1)


static func hall_cost(hall_level: int) -> int:
	var lvl: int = HALL_LEVEL_REQ[clampi(hall_level, 1, HALL_MAX)]
	return int(round(income(lvl) * (14.0 + 10.0 * hall_level)))


static func recruit_refresh_cost(level: int) -> int:
	return int(round(income(level) * 2.0))


static func recruit_hire_cost(level: int, tier: int) -> int:
	return int(round(income(level) * (3.0 + 0.32 * tier * tier)))


static func respec_cost(level: int, respecs: int) -> int:
	return int(round(income(level) * mini(5 + 5 * respecs, 30)))


## Formats copper as "1g 23s 45c".
static func money(copper: int) -> String:
	var g := copper / 10000
	var s := (copper / 100) % 100
	var c := copper % 100
	var parts: Array[String] = []
	if g > 0:
		parts.append("%dg" % g)
	if s > 0 or (g > 0 and c > 0):
		parts.append("%ds" % s)
	if c > 0 or parts.is_empty():
		parts.append("%dc" % c)
	return " ".join(parts)


## BBCode version with coin colours.
static func money_bb(copper: int) -> String:
	var g := copper / 10000
	var s := (copper / 100) % 100
	var c := copper % 100
	var out := ""
	if g > 0:
		out += "%d[color=#ffd24a]g[/color] " % g
	if s > 0 or g > 0:
		out += "%d[color=#c9d1d9]s[/color] " % s
	out += "%d[color=#d9875a]c[/color]" % c
	return out


static func big(n: float) -> String:
	var v := int(round(n))
	if absi(v) >= 100000:
		return "%.1fk" % (v / 1000.0)
	return str(v)
