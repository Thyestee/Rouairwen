class_name Items
## Gear: slots, qualities, random Classic-style items, named loot, tier sets and stat lines.
##
## An item is a Dictionary: {uid, name, slot, quality, ilvl, profile, type, set?}.
## profile is "healing", "spell", "physical", "tank" or "class:<id>" for tier pieces.

const SLOTS := ["head", "neck", "shoulders", "back", "chest", "wrist", "hands", "waist", "legs", "feet", "finger", "trinket", "weapon"]
const SLOT_NAMES := {"head": "Head", "neck": "Neck", "shoulders": "Shoulders", "back": "Back", "chest": "Chest", "wrist": "Wrist",
	"hands": "Hands", "waist": "Waist", "legs": "Legs", "feet": "Feet", "finger": "Finger", "trinket": "Trinket", "weapon": "Weapon"}
## How much each slot contributes; sums to ~0.40 for a full set of level-appropriate greens.
const SLOT_WEIGHT := {"head": 0.036, "neck": 0.022, "shoulders": 0.028, "back": 0.022, "chest": 0.036, "wrist": 0.02,
	"hands": 0.026, "waist": 0.026, "legs": 0.036, "feet": 0.026, "finger": 0.022, "trinket": 0.03, "weapon": 0.07}
const ARMOR_SLOTS := ["head", "shoulders", "chest", "wrist", "hands", "waist", "legs", "feet"]

const QUALITIES := ["poor", "common", "uncommon", "rare", "epic", "legendary"]
const QUALITY_MULT := {"poor": 0.45, "common": 0.7, "uncommon": 1.0, "rare": 1.3, "epic": 1.7, "legendary": 2.3}
const QUALITY_COLOR := {"poor": Color("9d9d9d"), "common": Color("ffffff"), "uncommon": Color("1eff00"),
	"rare": Color("0070dd"), "epic": Color("a335ee"), "legendary": Color("ff8000")}
const QUALITY_NAMES := {"poor": "Poor", "common": "Common", "uncommon": "Uncommon", "rare": "Rare", "epic": "Epic", "legendary": "Legendary"}

const PROFILES := ["healing", "spell", "physical", "tank"]
const PROFILE_NAMES := {"healing": "Healer", "spell": "Caster", "physical": "Physical", "tank": "Tank"}

## How well an item profile (row) suits a wearer's stat profile (column).
const MATCH := {
	"healing": {"healing": 1.0, "spell": 0.55, "physical": 0.15, "tank": 0.15},
	"spell": {"healing": 0.6, "spell": 1.0, "physical": 0.15, "tank": 0.15},
	"physical": {"healing": 0.15, "spell": 0.15, "physical": 1.0, "tank": 0.7},
	"tank": {"healing": 0.15, "spell": 0.15, "physical": 0.55, "tank": 1.0},
}

const NOUNS := {
	"plate": {"head": "Helm", "shoulders": "Pauldrons", "chest": "Breastplate", "wrist": "Bracers", "hands": "Gauntlets", "waist": "Girdle", "legs": "Legplates", "feet": "Sabatons"},
	"mail": {"head": "Helmet", "shoulders": "Spaulders", "chest": "Chain Armor", "wrist": "Bracers", "hands": "Gauntlets", "waist": "Belt", "legs": "Legguards", "feet": "Boots"},
	"leather": {"head": "Cover", "shoulders": "Shoulderpads", "chest": "Tunic", "wrist": "Bindings", "hands": "Gloves", "waist": "Belt", "legs": "Pants", "feet": "Boots"},
	"cloth": {"head": "Circlet", "shoulders": "Mantle", "chest": "Robe", "wrist": "Cuffs", "hands": "Gloves", "waist": "Sash", "legs": "Leggings", "feet": "Sandals"},
}
const JEWEL_NOUNS := {"neck": ["Pendant", "Necklace", "Choker", "Amulet"], "finger": ["Ring", "Band", "Signet", "Loop"],
	"trinket": ["Talisman", "Charm", "Idol", "Figurine"], "back": ["Cloak", "Cape", "Drape", "Shroud"]}
const WEAPON_NOUNS := {"sword": ["Blade", "Longsword", "Saber"], "axe": ["Axe", "Cleaver", "Hatchet"], "mace": ["Mace", "Hammer", "Scepter"],
	"dagger": ["Dagger", "Dirk", "Kris", "Shiv"], "staff": ["Staff", "Quarterstaff", "Walking Stick"], "polearm": ["Halberd", "Glaive", "Spear"],
	"bow": ["Longbow", "Shortbow", "Recurve"], "gun": ["Rifle", "Blunderbuss", "Musket"], "wand": ["Wand", "Rod"]}

## Green item families by armor type and minimum level.
const SERIES := {
	"cloth": [[1, "Linen"], [8, "Native"], [14, "Greenweave"], [20, "Spellbinder"], [26, "Durable"], [32, "Conjurer's"], [38, "Darkmist"], [44, "Mystical"], [50, "Celestial"], [56, "Arcane"]],
	"leather": [[1, "Rawhide"], [8, "Rugged"], [14, "Scouting"], [20, "Bandit"], [26, "Pathfinder"], [32, "Ranger"], [38, "Sentinel"], [44, "Tracker's"], [50, "Wanderer's"], [56, "Nightshade"]],
	"mail": [[1, "Chainmail"], [8, "Ringed"], [14, "Glimmering"], [20, "Raider's"], [26, "Banded"], [32, "Brigade"], [38, "Jade"], [44, "Bonelink"], [50, "Alabaster"], [56, "Emerald"]],
	"plate": [[1, "Bronze"], [8, "Iron-bound"], [14, "Steel"], [20, "Dwarven"], [26, "Glorious"], [32, "Revenant"], [40, "Templar"], [48, "Warbringer"], [54, "Thorium"], [58, "Crusader"]],
	"jewel": [[1, "Copper"], [10, "Silver"], [20, "Golden"], [30, "Truesilver"], [40, "Mithril"], [50, "Thorium"], [57, "Arcanite"]],
	"weapon": [[1, "Crude"], [8, "Tribal"], [16, "Militant"], [24, "Battle"], [32, "Bonecaster's"], [40, "Ebon"], [48, "Runic"], [55, "Thorium"]],
}
const SUFFIXES := {
	"healing": ["of Healing", "of the Owl", "of the Eagle", "of Spirit"],
	"spell": ["of the Sorcerer", "of Fiery Wrath", "of Frozen Wrath", "of Arcane Wrath", "of Intellect"],
	"physical": ["of the Monkey", "of the Tiger", "of Strength", "of Agility", "of Power", "of the Falcon"],
	"tank": ["of the Bear", "of the Gorilla", "of Defense", "of Stamina", "of the Whale"],
}
const RARE_PREFIXES := ["Gloomweave", "Stormshroud", "Emberforged", "Duskwoven", "Ironhide", "Bloodstained", "Runed", "Starfall",
	"Ghostwalker", "Grimtusk", "Thunderhorn", "Warsong", "Darkspear", "Blackrock", "Bonechill", "Whisperwind", "Dreamweave",
	"Sandstalker", "Venomweave", "Cinderhide", "Frostbitten", "Sunscorched", "Moonlit", "Spiritbound", "Wolfrider's"]

const ARMOR_BY_PROFILE := {
	"healing": [["cloth", 45], ["leather", 25], ["mail", 30]],
	"spell": [["cloth", 85], ["leather", 10], ["mail", 5]],
	"physical": [["leather", 40], ["mail", 40], ["plate", 20]],
	"tank": [["plate", 70], ["mail", 15], ["leather", 15]],
}
const WEAPON_BY_PROFILE := {
	"healing": ["staff", "mace", "dagger", "wand"],
	"spell": ["staff", "dagger", "sword", "wand"],
	"physical": ["sword", "axe", "mace", "dagger", "polearm", "bow", "gun"],
	"tank": ["sword", "axe", "mace"],
}

static var _next_uid := 1


static func set_next_uid(n: int) -> void:
	_next_uid = maxi(_next_uid, n)


static func new_uid() -> int:
	_next_uid += 1
	return _next_uid - 1


static func make(name: String, slot: String, quality: String, ilvl: int, profile: String, type: String) -> Dictionary:
	return {"uid": new_uid(), "name": name, "slot": slot, "quality": quality, "ilvl": ilvl, "profile": profile, "type": type}


static func _pick_weighted(pairs: Array, rng: RandomNumberGenerator) -> String:
	var total := 0
	for p in pairs:
		total += p[1]
	var r := rng.randi() % total
	for p in pairs:
		r -= p[1]
		if r < 0:
			return p[0]
	return pairs[0][0]


static func _series(kind: String, ilvl: int) -> String:
	var out: String = SERIES[kind][0][1]
	for s in SERIES[kind]:
		if ilvl >= s[0]:
			out = s[1]
	return out


static func random_slot(rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if r < 0.12:
		return "weapon"
	if r < 0.30:
		return ["neck", "back", "finger", "trinket"][rng.randi() % 4]
	return ARMOR_SLOTS[rng.randi() % ARMOR_SLOTS.size()]


## A random item in Classic style: greens get "of the Owl" suffixes, rares a unique-sounding prefix.
static func random_item(ilvl: int, quality: String, rng: RandomNumberGenerator, profile := "", slot := "") -> Dictionary:
	if profile == "":
		profile = PROFILES[rng.randi() % PROFILES.size()]
	if slot == "":
		slot = random_slot(rng)
	var type := ""
	var noun := ""
	var series := ""
	if slot in ARMOR_SLOTS:
		type = _pick_weighted(ARMOR_BY_PROFILE[profile], rng)
		noun = NOUNS[type][slot]
		series = _series(type, ilvl)
	elif slot == "weapon":
		var kinds: Array = WEAPON_BY_PROFILE[profile]
		type = kinds[rng.randi() % kinds.size()]
		var nouns: Array = WEAPON_NOUNS[type]
		noun = nouns[rng.randi() % nouns.size()]
		series = _series("weapon", ilvl)
	else:
		if slot == "back":
			type = "cloth"
		var jn: Array = JEWEL_NOUNS[slot]
		noun = jn[rng.randi() % jn.size()]
		series = _series("jewel", ilvl)
	var name := ""
	match quality:
		"uncommon":
			var suf: Array = SUFFIXES[profile]
			name = "%s %s %s" % [series, noun, suf[rng.randi() % suf.size()]]
		"rare", "epic", "legendary":
			name = "%s %s" % [RARE_PREFIXES[rng.randi() % RARE_PREFIXES.size()], noun]
		_:
			name = "%s %s" % [series, noun]
	return make(name, slot, quality, ilvl, profile, type)


## Builds an item from a loot table entry [name, slot, profile, type(, quality)].
static func from_entry(e: Array, ilvl: int, default_quality: String) -> Dictionary:
	var q: String = e[4] if e.size() > 4 else default_quality
	var bump := 0
	if q == "epic" and default_quality == "rare":
		bump = 3
	if q == "legendary":
		bump = 10
	return make(e[0], e[1], q, ilvl + bump, e[2], e[3])


## A tier set piece for a class ("Circlet of Prophecy", "Earthfury Helmet"...).
static func tier_piece(class_id: String, tier: int, ilvl: int, rng: RandomNumberGenerator, slot := "") -> Dictionary:
	if slot == "":
		slot = ARMOR_SLOTS[rng.randi() % ARMOR_SLOTS.size()]
	var armor: String = Raids.TIER_ARMOR[class_id]
	var set_name: String = Raids.SETS[class_id][clampi(tier, 0, 4)]
	var noun: String = NOUNS[armor][slot]
	var name := ""
	if set_name.begins_with("the ") or set_name in ["Valor", "Might", "Wrath", "Prophecy", "Transcendence", "Faith"]:
		name = "%s of %s" % [noun, set_name]
	else:
		name = "%s %s" % [set_name, noun]
	var q := "rare" if tier == 0 else "epic"
	var it := make(name, slot, q, ilvl, "class:" + class_id, armor)
	it["set"] = set_name
	return it


static func color(item: Dictionary) -> Color:
	return QUALITY_COLOR.get(item.get("quality", "common"), Color.WHITE)


static func quality_rank(q: String) -> int:
	return QUALITIES.find(q)


## Can a class wear this item at all?
static func can_use(item: Dictionary, class_id: String) -> bool:
	var profile: String = item.get("profile", "")
	if profile.begins_with("class:"):
		return profile.substr(6) == class_id
	var c: Dictionary = ClassData.CLASSES.get(class_id, {})
	var slot: String = item["slot"]
	if slot in ARMOR_SLOTS:
		return item["type"] in c.get("armor", [])
	if slot == "weapon":
		return item["type"] in c.get("weapons", [])
	return true


## The stat bonus an item gives a wearer of a level, class and stat profile.
static func bonus(item: Dictionary, level: int, class_id: String, stat: String) -> float:
	if item.is_empty():
		return 0.0
	var profile: String = item.get("profile", "")
	var m := 1.0
	if profile.begins_with("class:"):
		m = 1.08 if profile.substr(6) == class_id else 0.0
	else:
		m = MATCH.get(profile, {}).get(stat, 0.3)
	var rel := Balance.item_scale(item["ilvl"]) / Balance.scale(level)
	return SLOT_WEIGHT[item["slot"]] * QUALITY_MULT[item["quality"]] * rel * m


static func gear_bonus(gear: Dictionary, level: int, class_id: String, stat: String) -> float:
	var total := 0.0
	for slot in gear:
		total += bonus(gear[slot], level, class_id, stat)
	return total


static func sell_price(item: Dictionary) -> int:
	var base: float = Balance.income(mini(item["ilvl"], 60)) * SLOT_WEIGHT[item["slot"]] * 12.0
	return maxi(1, int(round(base * QUALITY_MULT[item["quality"]] * QUALITY_MULT[item["quality"]])))


## Tooltip stat lines, generated from the item's budget so they look like real Classic stats.
static func stat_lines(item: Dictionary) -> Array:
	var budget: float = Balance.item_scale(item["ilvl"]) * QUALITY_MULT[item["quality"]] * SLOT_WEIGHT[item["slot"]] * 26.0
	var profile: String = item["profile"]
	if profile.begins_with("class:"):
		var cid := profile.substr(6)
		var st: String = "healing" if cid == "priest" else ("tank" if cid == "warrior" else ("spell" if cid in ["mage", "warlock"] else "physical"))
		if cid in ["shaman", "druid"]:
			st = "healing"
		profile = st
	var lines := []
	var b := maxf(budget, 1.0)
	match profile:
		"healing":
			lines.append("+%d Intellect" % maxi(1, int(b * 0.3)))
			lines.append("+%d Stamina" % maxi(1, int(b * 0.18)))
			lines.append("+%d Spirit" % maxi(1, int(b * 0.2)))
			lines.append("[color=#1eff00]Equip: Increases healing done by spells and effects by up to %d.[/color]" % maxi(1, int(b * 0.65)))
		"spell":
			lines.append("+%d Intellect" % maxi(1, int(b * 0.3)))
			lines.append("+%d Stamina" % maxi(1, int(b * 0.25)))
			lines.append("[color=#1eff00]Equip: Increases damage and healing done by magical spells and effects by up to %d.[/color]" % maxi(1, int(b * 0.4)))
		"physical":
			var main := "Agility" if item["type"] in ["leather", "bow", "gun", "dagger"] else "Strength"
			lines.append("+%d %s" % [maxi(1, int(b * 0.45)), main])
			lines.append("+%d Stamina" % maxi(1, int(b * 0.3)))
			if b > 12:
				lines.append("[color=#1eff00]Equip: Improves your chance to get a critical strike by 1%.[/color]")
		"tank":
			lines.append("+%d Stamina" % maxi(1, int(b * 0.45)))
			lines.append("+%d Strength" % maxi(1, int(b * 0.2)))
			lines.append("[color=#1eff00]Equip: Increased Defense +%d.[/color]" % maxi(1, int(b * 0.18)))
	return lines


static func armor_value(item: Dictionary) -> int:
	var t: String = item.get("type", "")
	var per := {"cloth": 1.0, "leather": 2.0, "mail": 4.2, "plate": 7.5}
	if not per.has(t) or not (item["slot"] in ARMOR_SLOTS or item["slot"] == "back"):
		return 0
	var slot_f: float = SLOT_WEIGHT[item["slot"]] / 0.036
	return int(round(per[t] * (item["ilvl"] * 1.6 + 8) * slot_f * (0.8 + 0.2 * QUALITY_MULT[item["quality"]])))


static func type_label(item: Dictionary) -> String:
	var t: String = item.get("type", "")
	if t == "":
		return ""
	if item["slot"] == "weapon":
		return t.capitalize()
	return t.capitalize()


## BBCode tooltip, Classic layout.
static func tooltip_bb(item: Dictionary, compare_text := "") -> String:
	var c := color(item).to_html(false)
	var s := "[b][color=#%s]%s[/color][/b]\n" % [c, item["name"]]
	if item.get("set", "") != "":
		s += "[color=#ffd100]Tier set: %s[/color]\n" % item["set"]
	s += "%s    %s\n" % [SLOT_NAMES[item["slot"]], type_label(item)]
	var av := armor_value(item)
	if av > 0:
		s += "%d Armor\n" % av
	for l in stat_lines(item):
		s += l + "\n"
	var profile: String = item["profile"]
	if profile.begins_with("class:"):
		s += "[color=#c0c0c0]Classes: %s[/color]\n" % ClassData.class_name_of(profile.substr(6))
	else:
		s += "[color=#c0c0c0]Best for: %s[/color]\n" % PROFILE_NAMES.get(profile, profile)
	s += "[color=#ffd100]Item Level %d[/color]\n" % item["ilvl"]
	s += "[color=#c0c0c0]Sell Price: [/color]%s" % Balance.money_bb(sell_price(item))
	if compare_text != "":
		s += "\n" + compare_text
	return s
