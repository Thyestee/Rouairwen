class_name Items
## Gear for guild members, dropped by quests: WoW Classic style random-suffix items such as
## "Rugged Boots of the Bear". Stats come from the item level, the slot, the quality and the suffix.
##
## An item is a Dictionary: {"id", "name", "slot", "quality", "level", "stats": {stat: points}, "armor"}.

const SLOTS := ["weapon", "head", "chest", "legs", "feet"]
const SLOT_NAMES := {"weapon": "Weapon", "head": "Head", "chest": "Chest", "legs": "Legs", "feet": "Feet"}
## Share of the stat budget, and of the armor, that each slot gets.
const SLOT_BUDGET := {"weapon": 1.3, "head": 0.85, "chest": 1.0, "legs": 1.0, "feet": 0.75}
const SLOT_ARMOR := {"weapon": 0.0, "head": 0.8, "chest": 1.0, "legs": 0.9, "feet": 0.7}

## Uncommon (green), rare (blue), epic (purple). "mult" scales the stat budget.
const QUALITIES := [
	{"name": "Uncommon", "color": Color("1eff00"), "mult": 1.0, "weight": 70.0},
	{"name": "Rare", "color": Color("3d9bff"), "mult": 1.3, "weight": 25.0},
	{"name": "Epic", "color": Color("b65cff"), "mult": 1.7, "weight": 5.0},
]

const BASES := {
	"weapon": ["Axe", "Sword", "Mace", "Staff", "Dagger", "Bow", "Wand", "Hammer"],
	"head": ["Cap", "Helm", "Hood", "Coif", "Circlet"],
	"chest": ["Tunic", "Vest", "Robe", "Breastplate", "Hauberk", "Jerkin"],
	"legs": ["Pants", "Leggings", "Kilt", "Legguards", "Trousers"],
	"feet": ["Boots", "Sandals", "Greaves", "Treads", "Sabatons"],
}
## Name prefixes by minimum item level, from Classic's random-suffix green item families.
const PREFIXES := [
	[1, ["Worn", "Ragged", "Rough", "Rugged"]],
	[10, ["Bandit", "Scouting", "Glimmering", "Ivycloth"]],
	[20, ["Sage's", "Defender", "Battleforge", "Superior"]],
	[30, ["Knight's", "Fortified", "Durable", "Pagan"]],
	[40, ["Ornate", "Mighty", "Merciless", "Embersilk"]],
	[50, ["Champion's", "Triumphant", "Imposing", "Engraved"]],
]
## Classic random suffixes and the stats they give.
const SUFFIXES := {
	"of the Bear": ["str", "sta"], "of the Eagle": ["int", "sta"], "of the Monkey": ["agi", "sta"],
	"of the Owl": ["int", "spi"], "of the Tiger": ["str", "agi"], "of the Whale": ["sta", "spi"],
	"of the Gorilla": ["str", "int"], "of the Boar": ["str", "spi"], "of the Falcon": ["agi", "int"],
	"of the Wolf": ["agi", "spi"], "of Strength": ["str"], "of Agility": ["agi"], "of Stamina": ["sta"],
	"of Intellect": ["int"], "of Spirit": ["spi"],
}


## A random item of about the given level. `better_odds` makes rare and epic more likely.
static func create(id: int, item_level: int, better_odds := 1.0) -> Dictionary:
	var slot: String = SLOTS.pick_random()
	var quality := _roll_quality(better_odds)
	var suffix: String = SUFFIXES.keys().pick_random()
	var budget := maxf(1.0, (item_level * 0.45 + 2.0) * QUALITIES[quality].mult * SLOT_BUDGET[slot])
	var suffix_stats: Array = SUFFIXES[suffix]
	var stats := {}
	if suffix_stats.size() == 1:
		stats[suffix_stats[0]] = maxi(1, roundi(budget))
	else:
		var split := randf_range(0.4, 0.6)
		stats[suffix_stats[0]] = maxi(1, roundi(budget * split))
		stats[suffix_stats[1]] = maxi(1, roundi(budget * (1.0 - split)))
	return {
		"id": id,
		"name": "%s %s %s" % [_prefix(item_level), BASES[slot].pick_random(), suffix],
		"slot": slot,
		"quality": quality,
		"level": item_level,
		"stats": stats,
		"armor": roundi(item_level * 1.2 * SLOT_ARMOR[slot] * (1.0 + 0.15 * quality)),
	}


## "+5 Strength, +3 Stamina, 24 armor".
static func describe(item: Dictionary) -> String:
	var parts := []
	for stat in Fighters.STATS:
		if item.stats.has(stat):
			parts.append("+%d %s" % [item.stats[stat], Fighters.STAT_NAMES[stat]])
	if item.armor > 0:
		parts.append("%d armor" % item.armor)
	return ", ".join(PackedStringArray(parts))


static func color_of(item: Dictionary) -> Color:
	return QUALITIES[item.quality].color


static func sell_price(item: Dictionary) -> float:
	return float(item.level * 3 * (1 + item.quality * 2))


static func _roll_quality(better_odds: float) -> int:
	var weights := []
	var total := 0.0
	for i in QUALITIES.size():
		var weight: float = QUALITIES[i].weight * pow(better_odds, i)
		weights.append(weight)
		total += weight
	var roll := randf() * total
	for i in weights.size():
		roll -= weights[i]
		if roll < 0.0:
			return i
	return 0


static func _prefix(item_level: int) -> String:
	var names: Array = PREFIXES[0][1]
	for band in PREFIXES:
		if item_level >= band[0]:
			names = band[1]
	return names.pick_random()
