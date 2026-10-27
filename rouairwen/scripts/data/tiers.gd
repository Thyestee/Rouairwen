class_name Tiers
## Guildmate grades from F to SSS+. The grade multiplies a guildmate's damage
## (and, square-rooted, their health), and the guild hall decides which grades show up.

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
	return mini(NAMES.size() - 1, 3 + 2 * (hall - 1))


## Rolls a candidate grade for a guild hall level.
static func roll(hall: int, rng: RandomNumberGenerator) -> int:
	var mean := mean_for_hall(hall)
	if rng.randf() < EXCEPTIONAL_CHANCE:
		mean += EXCEPTIONAL_BONUS
	var t := int(round(rng.randfn(mean, SPREAD)))
	return clampi(t, 0, cap_for_hall(hall))
