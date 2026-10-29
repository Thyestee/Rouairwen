class_name Stats
## World of Warcraft style stats.
##
## Primary: Strength, Agility, Stamina, Intellect, Spirit. Secondary: Attack Power, Spell Damage,
## Healing, Critical strike chance, Defense, Armor. Items carry stat lines (from their "of the Owl"
## style suffix, or their role), characters have base stats from class and level, and talents can
## raise stats by a percentage.
##
## Stats behave like in WoW: Strength and/or Agility give Attack Power depending on class, Agility
## gives physical crit and dodge, Intellect gives mana and spell crit, Spirit gives mana regeneration,
## Stamina gives health, Armor reduces physical damage, Defense raises dodge. The combat engine works
## in level-scaled units, so each stat is converted relative to what a character of that level has
## naked; at-level green gear lands on the same strength as before stats existed.
##
## Healing and Spell Damage add to Thyeste's spells like in WoW: each spell adds its coefficient of
## them (see Spells). Spell amounts grow 6% a level, so these two grow the same way on items
## (power_points), and a coefficient is worth as much at level 10 as at 60.

const PRIMARY := ["str", "agi", "sta", "int", "spi"]
const SECONDARY := ["ap", "sp", "heal", "crit", "def"]
const NAMES := {"str": "Strength", "agi": "Agility", "sta": "Stamina", "int": "Intellect", "spi": "Spirit",
	"ap": "Attack Power", "sp": "Spell Damage", "heal": "Healing", "crit": "Critical Strike", "def": "Defense", "armor": "Armor"}

## Level 1 base stats per class (Classic-like, Horde races averaged).
const TEMPLATES := {
	"warrior": {"str": 23, "agi": 20, "sta": 22, "int": 18, "spi": 19},
	"shaman": {"str": 21, "agi": 17, "sta": 22, "int": 20, "spi": 22},
	"rogue": {"str": 20, "agi": 24, "sta": 20, "int": 18, "spi": 19},
	"hunter": {"str": 19, "agi": 24, "sta": 21, "int": 19, "spi": 20},
	"mage": {"str": 17, "agi": 18, "sta": 19, "int": 24, "spi": 22},
	"warlock": {"str": 18, "agi": 18, "sta": 21, "int": 22, "spi": 22},
	"druid": {"str": 20, "agi": 18, "sta": 20, "int": 22, "spi": 22},
	"priest": {"str": 17, "agi": 18, "sta": 19, "int": 23, "spi": 24},
}
## Attack Power per point of Strength / Agility (Classic: warriors, shamans and druids 2 per Strength,
## rogues 1 per Strength and Agility, hunters 2 per Agility at range).
const AP_FROM := {"warrior": [2, 0], "shaman": [2, 0], "druid": [2, 0], "rogue": [1, 1], "hunter": [0, 2],
	"mage": [1, 0], "warlock": [1, 0], "priest": [1, 0]}
const ARMOR_TYPE := {"warrior": "plate", "shaman": "mail", "hunter": "mail", "rogue": "leather", "druid": "leather",
	"mage": "cloth", "warlock": "cloth", "priest": "cloth"}

## How stat points are bought on items: a point of budget buys 1 primary stat, 2 Attack Power,
## 1.2 Spell Damage, 2.2 Healing (both times power_points), 1 Defense, or 1/14 of a percent of crit.
const PER_POINT := {"str": 1.0, "agi": 1.0, "sta": 1.0, "int": 1.0, "spi": 1.0, "ap": 2.0, "sp": 1.2, "heal": 2.2, "def": 1.0, "crit": 1.0 / 14.0}
## Healing and Spell Damage per budget point, times scale(ilvl) / ilvl: a full set of at-level greens
## gives about 34 x Balance.scale(level) healing power, which Lesser Heal (71%) turns into +43%.
const POWER_K := 5.68
const POWER_STATS := ["heal", "sp"]

## Classic random suffixes.
const SUFFIX_STATS := {
	"of Healing": {"heal": 1.0}, "of the Owl": {"int": 0.5, "spi": 0.5}, "of the Eagle": {"sta": 0.5, "int": 0.5},
	"of Spirit": {"spi": 1.0}, "of the Sorcerer": {"sta": 0.34, "int": 0.33, "sp": 0.33}, "of Fiery Wrath": {"sp": 1.0},
	"of Frozen Wrath": {"sp": 1.0}, "of Arcane Wrath": {"sp": 1.0}, "of Intellect": {"int": 1.0},
	"of the Monkey": {"agi": 0.5, "sta": 0.5}, "of the Tiger": {"str": 0.5, "agi": 0.5}, "of Strength": {"str": 1.0},
	"of Agility": {"agi": 1.0}, "of Power": {"ap": 1.0}, "of the Falcon": {"agi": 0.5, "int": 0.5},
	"of the Bear": {"str": 0.5, "sta": 0.5}, "of the Gorilla": {"str": 0.5, "int": 0.5}, "of Defense": {"def": 1.0},
	"of Stamina": {"sta": 1.0}, "of the Whale": {"sta": 0.5, "spi": 0.5},
}
## Items without a suffix (named loot) split their budget by role.
const PROFILE_STATS := {
	"healing": {"int": 0.3, "spi": 0.2, "sta": 0.15, "heal": 0.35},
	"spell": {"int": 0.3, "sta": 0.25, "sp": 0.35, "crit": 0.1},
	"physical_str": {"str": 0.4, "agi": 0.1, "sta": 0.3, "crit": 0.1, "ap": 0.1},
	"physical_agi": {"agi": 0.4, "str": 0.1, "sta": 0.3, "crit": 0.1, "ap": 0.1},
	"tank": {"sta": 0.45, "str": 0.15, "def": 0.25, "agi": 0.15},
}
const CLASS_PROFILE := {"priest": "healing", "shaman": "healing", "druid": "healing", "mage": "spell", "warlock": "spell",
	"rogue": "physical_agi", "hunter": "physical_agi", "warrior": "tank"}
const AGI_TYPES := ["leather", "bow", "gun", "dagger"]
## Agility needed for 1% critical strike, relative to warriors (Classic hunters need about 2.5 times more).
const AGI_CRIT := {"rogue": 1.25, "hunter": 2.0}

static var _item_cache := {}


# ---------------------------------------------------------------- level references

## Base stats grow linearly, about 6.3 times from level 1 to 60, like in Classic.
static func level_factor(level: float) -> float:
	return 1.0 + 0.09 * (level - 1.0)


static func base(class_id: String, level: int) -> Dictionary:
	var t: Dictionary = TEMPLATES.get(class_id, TEMPLATES["warrior"])
	var out := {}
	for k in PRIMARY:
		out[k] = t[k] * level_factor(level)
	return out


static func agi_per_crit(level: int, class_id := "") -> float:
	return 4.0 * level_factor(level) * AGI_CRIT.get(class_id, 1.0)


static func int_per_crit(level: int) -> float:
	return 9.5 * level_factor(level)


## What a budget point of Healing or Spell Damage is multiplied by at an item level. It follows the
## spells' 6% a level up to 60; raid items past it only grow with their budget.
static func power_points(ilvl: int) -> float:
	var l := clampi(ilvl, 3, Balance.MAX_LEVEL)
	return POWER_K * Balance.scale(l) / l


## Spell Damage that doubles a caster guildmate's damage.
static func spell_power_ref(level: int) -> float:
	return 8.4 * maxi(level, 2) * power_points(level)


## Healing power that doubles Lesser Heal: what a heal's gain from gear is measured against.
static func healing_ref(level: int) -> float:
	return 13.8 * maxi(level, 3) * power_points(level)


## Classic armor formula: reduction = armor / (armor + 400 + 85 x attacker level).
static func armor_reduction(armor: float, level: int) -> float:
	return armor / (armor + 400.0 + 85.0 * level)


# ---------------------------------------------------------------- items

static func item_budget(item: Dictionary) -> float:
	var slot_rel: float = Items.SLOT_WEIGHT[item["slot"]] / 0.036
	return maxf(1.0, item["ilvl"]) * 0.7 * slot_rel * Items.QUALITY_MULT[item["quality"]]


## An item's stat lines, from its suffix or its role. Cached per item.
static func item_stats(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {}
	var key := "%s|%d|%s|%s|%s" % [item["name"], item["ilvl"], item["quality"], item["slot"], item["profile"]]
	if _item_cache.has(key):
		return _item_cache[key]
	var split := {}
	var nm: String = item["name"]
	for suffix in SUFFIX_STATS:
		if nm.ends_with(" " + suffix):
			split = SUFFIX_STATS[suffix]
			break
	if split.is_empty():
		var profile: String = item["profile"]
		if profile.begins_with("class:"):
			profile = CLASS_PROFILE.get(profile.substr(6), "healing")
		if profile == "physical":
			var agi: bool = item.get("type", "") in AGI_TYPES or (item.get("type", "") == "" and nm.hash() % 2 == 0)
			profile = "physical_agi" if agi else "physical_str"
		split = PROFILE_STATS.get(profile, PROFILE_STATS["healing"])
	var budget := item_budget(item)
	var out := {}
	var leftover := 0.0
	for k in split:
		var v: float = budget * split[k] * PER_POINT[k]
		if k in POWER_STATS:
			v *= power_points(int(item["ilvl"]))
		if k == "crit":
			v = floorf(v)
			if v < 1.0:
				leftover += budget * split[k]
				continue
		else:
			v = roundf(v)
		if v > 0.0:
			out[k] = v
	var main_key: String = split.keys()[0]
	if leftover > 0.0:
		out[main_key] = out.get(main_key, 0.0) + roundf(leftover * PER_POINT[main_key])
	# The smallest pieces (a level 1 ring) still carry a point of their main stat.
	if out.values().all(func(x): return x <= 0.0):
		out[main_key] = 1.0
	var armor := float(Items.armor_value(item))
	if armor > 0.0:
		out["armor"] = armor
	_item_cache[key] = out
	return out


static func add_into(into: Dictionary, stats: Dictionary, times := 1.0) -> void:
	for k in stats:
		into[k] = into.get(k, 0.0) + stats[k] * times


static func gear_stats(gear: Dictionary) -> Dictionary:
	var out := {}
	for slot in gear:
		add_into(out, item_stats(gear[slot]))
	return out


# ---------------------------------------------------------------- characters

## Every stat of a character: base + grade (Tiers.stats) + gear, talent percentages applied, then
## derived values, measured against an F-grade character of the level with nothing on.
## kind is "physical", "spell", "tank" or "priest" (how the character fights).
static func compute(class_id: String, kind: String, level: int, gear: Dictionary, mods := {}, grade := {}) -> Dictionary:
	return compute_stats(class_id, kind, level, gear_stats(gear), mods, grade)


## Same as compute, from gear stats already summed (the balance simulation's reference gear).
static func compute_stats(class_id: String, kind: String, level: int, gear: Dictionary, mods := {}, grade := {}) -> Dictionary:
	var s := base(class_id, level)
	add_into(s, grade)
	add_into(s, gear)
	for k in PRIMARY:
		s[k] = s.get(k, 0.0) * (1.0 + mods.get(k + "%", 0.0) / 100.0)
	for k in SECONDARY + ["armor"]:
		s[k] = s.get(k, 0.0)
	var b := base(class_id, level)
	var apf: Array = AP_FROM.get(class_id, [1, 0])
	s["armor"] += s["agi"] * 2.0
	s["attack_power"] = 3.0 * level + apf[0] * s["str"] + apf[1] * s["agi"] + s["ap"]
	s["attack_power_base"] = 3.0 * level + apf[0] * b["str"] + apf[1] * b["agi"]
	s["melee_crit"] = 5.0 + s["agi"] / agi_per_crit(level, class_id) + s["crit"]
	s["spell_crit"] = (3.0 if kind == "priest" else 6.0) + s["int"] / int_per_crit(level) + s["crit"]
	s["dodge"] = 1.0 + s["agi"] / agi_per_crit(level) * 0.35 + s["def"] * 0.04
	s["armor_reduction"] = armor_reduction(s["armor"], level)
	match kind:
		"spell":
			s["offense"] = 1.0 + s["sp"] / spell_power_ref(level)
			s["crit_chance"] = s["spell_crit"]
		"priest":
			s["offense"] = 1.0 + s["sp"] / spell_power_ref(level)
			s["crit_chance"] = s["spell_crit"]
		_:
			s["offense"] = 0.55 + 0.45 * s["attack_power"] / s["attack_power_base"]
			s["crit_chance"] = s["melee_crit"]
	# Health, mana and regeneration as multipliers of the level's base (1.0 when naked).
	s["health_mult"] = 0.85 + 0.15 * s["sta"] / b["sta"]
	s["mana_mult"] = 0.75 + 0.25 * s["int"] / b["int"]
	s["regen_mult"] = 0.78 + 0.22 * s["spi"] / b["spi"]
	# Spell Damage gear raises healing too ("damage and healing done by magical spells"). Spells add a
	# coefficient of these; heal_mult is what they do for Lesser Heal, the healer's overall power.
	s["heal_power"] = s["heal"] + s["sp"]
	s["heal_mult"] = 1.0 + s["heal_power"] / healing_ref(level)
	return s


## Damage taken relative to wearing at-level green armor of the class's own type (1.0). Missing armor
## costs at most +10% damage taken, so new recruits in rags aren't made of paper.
static func armor_factor(class_id: String, level: int, armor: float) -> float:
	var ref := reference_armor(class_id, level)
	return minf(1.1, (1.0 - armor_reduction(armor, level)) / (1.0 - armor_reduction(ref, level)))


static func reference_armor(class_id: String, level: int) -> float:
	var type: String = ARMOR_TYPE.get(class_id, "cloth")
	var total: float = base(class_id, level)["agi"] * 2.0
	for slot in Items.ARMOR_SLOTS:
		total += Items.armor_value({"slot": slot, "type": type, "ilvl": level, "quality": "uncommon"})
	total += Items.armor_value({"slot": "back", "type": "cloth", "ilvl": level, "quality": "uncommon"})
	return total


## A full set of at-level items of one role, as stats: what the balance simulation calls "gear".
static func reference_gear_stats(profile: String, level: int, quality := "uncommon") -> Dictionary:
	var out := {}
	for slot in Items.SLOTS:
		var it := {"name": "Reference", "slot": slot, "ilvl": level, "quality": quality, "profile": profile,
			"type": "dagger" if profile == "physical_agi" else ("mace" if slot == "weapon" else "")}
		var split: Dictionary = PROFILE_STATS[profile]
		var budget := item_budget(it)
		for k in split:
			out[k] = out.get(k, 0.0) + budget * split[k] * PER_POINT[k] * (power_points(level) if k in POWER_STATS else 1.0)
	return out


# ---------------------------------------------------------------- item value

## What one point of each stat is worth to a character, as a fraction of its power (for upgrades).
static func weights(class_id: String, kind: String, level: int) -> Dictionary:
	var b := base(class_id, level)
	var apf: Array = AP_FROM.get(class_id, [1, 0])
	var ap0: float = 3.0 * level + apf[0] * b["str"] + apf[1] * b["agi"]
	var w := {}
	var surv := 1.0 if kind == "tank" else (0.25 if kind == "priest" else 0.35)
	w["sta"] = 0.15 / b["sta"] * surv
	match kind:
		"spell":
			w["sp"] = 1.0 / spell_power_ref(level)
			w["int"] = 0.01 / int_per_crit(level)
			w["crit"] = 0.01
		"priest":
			w["heal"] = 1.0 / healing_ref(level)
			w["int"] = 0.25 / b["int"] * 0.6 + 0.01 / int_per_crit(level) * 0.5
			w["spi"] = 0.22 / b["spi"] * 0.5
			w["crit"] = 0.005
			w["sp"] = 1.0 / healing_ref(level)
		_:
			var k: float = 0.45 / ap0 * (0.6 if kind == "tank" else 1.0)
			w["ap"] = k
			w["str"] = k * apf[0]
			w["agi"] = k * apf[1] + 0.01 / agi_per_crit(level, class_id) + (0.0035 / agi_per_crit(level) if kind == "tank" else 0.0)
			w["crit"] = 0.01
			if kind == "tank":
				w["def"] = 0.0004 * 1.5
				w["armor"] = 0.25 / maxf(1.0, reference_armor(class_id, level))
	if not w.has("armor"):
		w["armor"] = 0.02 / maxf(1.0, reference_armor(class_id, level))
	return w


static func item_value(item: Dictionary, w: Dictionary) -> float:
	var v := 0.0
	var st := item_stats(item)
	for k in st:
		v += st[k] * w.get(k, 0.0)
	return v


## Item tooltip lines in Classic order.
static func lines(item: Dictionary) -> Array:
	var st := item_stats(item)
	var out := []
	for k in PRIMARY:
		if st.has(k):
			out.append("+%d %s" % [int(st[k]), NAMES[k]])
	if st.has("def"):
		out.append("[color=#1eff00]Equip: Increased Defense +%d.[/color]" % int(st["def"]))
	if st.has("crit"):
		out.append("[color=#1eff00]Equip: Improves your chance to get a critical strike by %d%%.[/color]" % int(st["crit"]))
	if st.has("ap"):
		out.append("[color=#1eff00]Equip: +%d Attack Power.[/color]" % int(st["ap"]))
	if st.has("sp"):
		out.append("[color=#1eff00]Equip: Increases damage and healing done by magical spells and effects by up to %d.[/color]" % int(st["sp"]))
	if st.has("heal"):
		out.append("[color=#1eff00]Equip: Increases healing done by spells and effects by up to %d.[/color]" % int(st["heal"]))
	return out
