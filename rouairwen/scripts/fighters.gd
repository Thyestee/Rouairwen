class_name Fighters
## Guild members: classes, specs, tiers, stats and levels, and the dice rolls used when recruiting.
##
## A fighter is a Dictionary:
##   {"id", "name", "class_id", "spec", "tier", "level", "xp",
##    "talent": {stat: personal multiplier}, "spells": [spell names], "gear": {slot: item}}
## "tier" is an index into TIERS (0 = F ... 8 = SS+). Stats come from the class, the level, the tier
## and the fighter's own talent, plus their gear. Power is a score computed from those stats.

const STATS := ["str", "agi", "sta", "int", "spi"]
const STAT_NAMES := {"str": "Strength", "agi": "Agility", "sta": "Stamina", "int": "Intellect", "spi": "Spirit"}
const MAX_LEVEL := 60
const XP_PER_LEVEL := 100

## The nine classes of WoW Classic. "stats" holds [value at level 1, gain per level] for a C-tier
## fighter. Each spec has the role it filled in Classic raids and its "main" stat, which drives
## its damage or healing. Feral Combat covered both bear tanking and cat DPS back then; it's a tank here.
const CLASSES := {
	"warrior": {"name": "Warrior", "color": Color("c79c6e"),
		"stats": {"str": [12, 2.0], "agi": [8, 1.2], "sta": [12, 1.8], "int": [4, 0.3], "spi": [5, 0.5]},
		"specs": [
			{"name": "Arms", "role": "DPS", "main": "str"},
			{"name": "Fury", "role": "DPS", "main": "str"},
			{"name": "Protection", "role": "Tank", "main": "str"},
		]},
	"paladin": {"name": "Paladin", "color": Color("f58cba"),
		"stats": {"str": [11, 1.7], "agi": [6, 0.8], "sta": [11, 1.5], "int": [8, 1.0], "spi": [8, 1.0]},
		"specs": [
			{"name": "Holy", "role": "Healer", "main": "int"},
			{"name": "Protection", "role": "Tank", "main": "str"},
			{"name": "Retribution", "role": "DPS", "main": "str"},
		]},
	"hunter": {"name": "Hunter", "color": Color("abd473"),
		"stats": {"str": [6, 0.6], "agi": [12, 2.0], "sta": [9, 1.4], "int": [7, 0.8], "spi": [6, 0.8]},
		"specs": [
			{"name": "Beast Mastery", "role": "DPS", "main": "agi"},
			{"name": "Marksmanship", "role": "DPS", "main": "agi"},
			{"name": "Survival", "role": "DPS", "main": "agi"},
		]},
	"rogue": {"name": "Rogue", "color": Color("fff569"),
		"stats": {"str": [9, 1.0], "agi": [13, 2.2], "sta": [8, 1.2], "int": [4, 0.3], "spi": [4, 0.5]},
		"specs": [
			{"name": "Assassination", "role": "DPS", "main": "agi"},
			{"name": "Combat", "role": "DPS", "main": "agi"},
			{"name": "Subtlety", "role": "DPS", "main": "agi"},
		]},
	"priest": {"name": "Priest", "color": Color("ffffff"),
		"stats": {"str": [4, 0.3], "agi": [5, 0.4], "sta": [7, 0.9], "int": [13, 2.0], "spi": [13, 2.0]},
		"specs": [
			{"name": "Discipline", "role": "Healer", "main": "int"},
			{"name": "Holy", "role": "Healer", "main": "int"},
			{"name": "Shadow", "role": "DPS", "main": "int"},
		]},
	"shaman": {"name": "Shaman", "color": Color("0070de"),
		"stats": {"str": [9, 1.2], "agi": [7, 1.0], "sta": [10, 1.4], "int": [10, 1.4], "spi": [9, 1.2]},
		"specs": [
			{"name": "Elemental", "role": "DPS", "main": "int"},
			{"name": "Enhancement", "role": "DPS", "main": "str"},
			{"name": "Restoration", "role": "Healer", "main": "int"},
		]},
	"mage": {"name": "Mage", "color": Color("69ccf0"),
		"stats": {"str": [3, 0.2], "agi": [5, 0.4], "sta": [7, 0.9], "int": [15, 2.4], "spi": [11, 1.6]},
		"specs": [
			{"name": "Arcane", "role": "DPS", "main": "int"},
			{"name": "Fire", "role": "DPS", "main": "int"},
			{"name": "Frost", "role": "DPS", "main": "int"},
		]},
	"warlock": {"name": "Warlock", "color": Color("9482c9"),
		"stats": {"str": [5, 0.4], "agi": [5, 0.4], "sta": [9, 1.2], "int": [13, 2.1], "spi": [10, 1.4]},
		"specs": [
			{"name": "Affliction", "role": "DPS", "main": "int"},
			{"name": "Demonology", "role": "DPS", "main": "int"},
			{"name": "Destruction", "role": "DPS", "main": "int"},
		]},
	"druid": {"name": "Druid", "color": Color("ff7d0a"),
		"stats": {"str": [8, 1.0], "agi": [8, 1.2], "sta": [9, 1.2], "int": [10, 1.4], "spi": [10, 1.3]},
		"specs": [
			{"name": "Balance", "role": "DPS", "main": "int"},
			{"name": "Feral Combat", "role": "Tank", "main": "agi"},
			{"name": "Restoration", "role": "Healer", "main": "int"},
		]},
}

const ROLES := ["Tank", "Healer", "DPS"]
const ROLE_COLORS := {"Tank": Color("4f8fe8"), "Healer": Color("3fc25f"), "DPS": Color("e5533b")}

## Tiers from worst to best. "weight" sets the base recruit odds; "factor" scales the fighter's stats
## (both at level 1 and what they gain per level).
## Colours follow WoW item quality: grey, white, green, blue, purple, orange, then beyond.
const TIERS := [
	{"name": "F", "color": Color("9d9d9d"), "weight": 45.0, "factor": 0.8},
	{"name": "E", "color": Color("ffffff"), "weight": 25.0, "factor": 0.86},
	{"name": "D", "color": Color("1eff00"), "weight": 15.0, "factor": 0.93},
	{"name": "C", "color": Color("3d9bff"), "weight": 8.0, "factor": 1.0},
	{"name": "B", "color": Color("b65cff"), "weight": 4.0, "factor": 1.08},
	{"name": "A", "color": Color("ff8000"), "weight": 2.0, "factor": 1.17},
	{"name": "S", "color": Color("e6cc80"), "weight": 0.8, "factor": 1.27},
	{"name": "SS", "color": Color("ff3b3b"), "weight": 0.18, "factor": 1.4},
	{"name": "SS+", "color": Color("4ef2ff"), "weight": 0.02, "factor": 1.55},
]

## Each inn level multiplies the weight of tier i by (1 + boost * level)^i,
## so the better the tier, the more it gains.
const ODDS_BOOST_PER_INN_LEVEL := 0.12
## Each recruit's stats vary a little from the class average.
const TALENT_RANGE := Vector2(0.9, 1.1)

const NAME_STARTS := ["Gar", "Zul", "Thra", "Mok", "Ruk", "Vol", "Kar", "Dra", "Nok", "Tor",
	"Gri", "Sha", "Ur", "Bru", "Zag", "Rok", "Jin", "Ka", "Mur", "Grek"]
const NAME_ENDS := ["ak", "osh", "gar", "tha", "zin", "rok", "mar", "ka", "dun", "jin",
	"ra", "gul", "nar", "tok", "esh"]


# --- Recruiting ---

## Chance of each tier (summing to 1) for a recruit at the given inn level.
static func tier_chances(inn_level: int) -> Array[float]:
	var boost := 1.0 + ODDS_BOOST_PER_INN_LEVEL * inn_level
	var chances: Array[float] = []
	var total := 0.0
	for i in TIERS.size():
		var weight: float = TIERS[i].weight * pow(boost, i)
		chances.append(weight)
		total += weight
	for i in chances.size():
		chances[i] /= total
	return chances


static func roll_tier(chances: Array[float]) -> int:
	var roll := randf()
	for i in chances.size():
		roll -= chances[i]
		if roll < 0.0:
			return i
	return chances.size() - 1


## A new level 1 recruit with a random class, spec, tier, talent and spell kit.
static func create(id: int, inn_level: int) -> Dictionary:
	var class_id: String = CLASSES.keys().pick_random()
	var spec: Dictionary = CLASSES[class_id].specs.pick_random()
	var talent := {}
	for stat in STATS:
		talent[stat] = snappedf(randf_range(TALENT_RANGE.x, TALENT_RANGE.y), 0.01)
	return {
		"id": id,
		"name": NAME_STARTS.pick_random() + NAME_ENDS.pick_random(),
		"class_id": class_id,
		"spec": spec.name,
		"tier": roll_tier(tier_chances(inn_level)),
		"level": 1,
		"xp": 0,
		"talent": talent,
		"spells": Spells.random_kit(class_id, spec.name),
		"gear": {},
	}


# --- Specs ---

## The fighter's spec entry ({"name", "role", "main"}).
static func spec_of(fighter: Dictionary) -> Dictionary:
	var specs: Array = CLASSES[fighter.class_id].specs
	for spec in specs:
		if spec.name == fighter.spec:
			return spec
	return specs[0]


static func spec_names(class_id: String) -> Array[String]:
	var names: Array[String] = []
	for spec in CLASSES[class_id].specs:
		names.append(spec.name)
	return names


## A spec as one string, "class_id:Spec name", e.g. "warrior:Protection".
static func spec_key(fighter: Dictionary) -> String:
	return "%s:%s" % [fighter.class_id, fighter.spec]


static func all_spec_keys() -> Array[String]:
	var keys: Array[String] = []
	for class_id in CLASSES:
		for spec in CLASSES[class_id].specs:
			keys.append("%s:%s" % [class_id, spec.name])
	return keys


## "warrior:Protection" -> "Protection Warrior".
static func spec_label(key: String) -> String:
	var parts := key.split(":")
	return "%s %s" % [parts[1], CLASSES[parts[0]].name]


static func role_of_key(key: String) -> String:
	var parts := key.split(":")
	for spec in CLASSES[parts[0]].specs:
		if spec.name == parts[1]:
			return spec.role
	return "DPS"


## Class colour, brightened when it's too dark to read on the dark red panels.
static func class_text_color(class_id: String) -> Color:
	var color: Color = CLASSES[class_id].color
	return color.lightened(0.35) if color.get_luminance() < 0.4 else color


# --- Stats ---

## Stats from class, level, tier and talent, before gear.
static func base_stats(fighter: Dictionary) -> Dictionary:
	var template: Dictionary = CLASSES[fighter.class_id].stats
	var factor: float = TIERS[fighter.tier].factor
	var stats := {}
	for stat in STATS:
		var start: float = template[stat][0]
		var growth: float = template[stat][1]
		stats[stat] = (start + growth * (fighter.level - 1)) * factor * fighter.talent.get(stat, 1.0)
	return stats


## Stats with gear, rounded down to whole points.
static func total_stats(fighter: Dictionary) -> Dictionary:
	var stats := base_stats(fighter)
	for item in fighter.gear.values():
		for stat in item.stats:
			stats[stat] += item.stats[stat]
	for stat in stats:
		stats[stat] = floori(stats[stat])
	return stats


## Armor from gear, plus a natural bonus for tanks.
static func armor(fighter: Dictionary) -> int:
	var total: int = fighter.level * 2
	if spec_of(fighter).role == "Tank":
		total += 20 + fighter.level * 8
	for item in fighter.gear.values():
		total += item.armor
	return total


## One number summing up how strong a fighter is: every stat, the main stat once more, and armor.
static func power(fighter: Dictionary) -> int:
	var stats := total_stats(fighter)
	var total := 0.0
	for stat in STATS:
		total += stats[stat]
	total += stats[spec_of(fighter).main]
	return roundi(total + armor(fighter) / 10.0)


## What the stats mean in a fight:
##   hp: health (Stamina)    potency: scales damage and healing (main stat, plus Spirit for healers)
##   crit: chance of 1.5x    dodge: chance to avoid a foe's attack    dr: share of damage armor absorbs
static func combat_profile(fighter: Dictionary) -> Dictionary:
	var stats := total_stats(fighter)
	var spec := spec_of(fighter)
	var main: String = spec.main
	var potency: float = stats[main] * 2.0
	if spec.role == "Healer":
		potency += stats.spi
	var crit: float = 0.05 + (stats.int * 0.001 if main == "int" else stats.agi * 0.0015)
	var dodge: float = 0.03 + stats.agi * 0.001 + (0.05 if spec.role == "Tank" else 0.0)
	var hp: float = 50.0 + stats.sta * 10.0
	if spec.role == "Tank":
		hp *= 1.1
	var total_armor := armor(fighter)
	var level: int = fighter.level
	return {
		"hp": hp,
		"potency": potency,
		"crit": minf(crit, 0.35),
		"dodge": minf(dodge, 0.3),
		"dr": minf(total_armor / (total_armor + 100.0 + 30.0 * level), 0.6),
		"armor": total_armor,
	}


## The power of an average C-tier fighter with no gear at that level, to size quests.
static func reference_power(level: int) -> float:
	var total := 0.0
	var count := 0
	for class_id in CLASSES:
		var template: Dictionary = CLASSES[class_id].stats
		var sum := 0.0
		for stat in STATS:
			sum += template[stat][0] + template[stat][1] * (level - 1)
		var main: String = CLASSES[class_id].specs[0].main
		sum += template[main][0] + template[main][1] * (level - 1)
		total += sum + level * 0.2
		count += 1
	return total / count


# --- Levels ---

## Adds experience, levelling up every XP_PER_LEVEL. Returns how many levels were gained.
static func gain_xp(fighter: Dictionary, amount: int) -> int:
	if fighter.level >= MAX_LEVEL:
		return 0
	fighter.xp += amount
	var gained := 0
	while fighter.xp >= XP_PER_LEVEL and fighter.level < MAX_LEVEL:
		fighter.xp -= XP_PER_LEVEL
		fighter.level += 1
		gained += 1
	if fighter.level >= MAX_LEVEL:
		fighter.xp = 0
	return gained
