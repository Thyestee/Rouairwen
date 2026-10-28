class_name ClassData
## Horde classes and specs available to recruits (no Shadow priests), with their role,
## base numbers (in level units) and the party utility each one brings.

const CLASSES := {
	"warrior": {"name": "Warrior", "color": Color("c79c6e"), "armor": ["plate", "mail", "leather", "cloth"],
		"weapons": ["sword", "axe", "mace", "polearm", "dagger", "staff"],
		"races": ["orc", "tauren", "troll", "undead"]},
	"shaman": {"name": "Shaman", "color": Color("0070de"), "armor": ["mail", "leather", "cloth"],
		"weapons": ["axe", "mace", "staff", "dagger"], "races": ["orc", "tauren", "troll"]},
	"rogue": {"name": "Rogue", "color": Color("fff569"), "armor": ["leather", "cloth"],
		"weapons": ["dagger", "sword", "mace"], "races": ["orc", "troll", "undead"]},
	"hunter": {"name": "Hunter", "color": Color("abd473"), "armor": ["mail", "leather", "cloth"],
		"weapons": ["bow", "gun", "axe", "sword", "polearm"], "races": ["orc", "tauren", "troll"]},
	"mage": {"name": "Mage", "color": Color("69ccf0"), "armor": ["cloth"],
		"weapons": ["staff", "dagger", "sword", "wand"], "races": ["troll", "undead"]},
	"warlock": {"name": "Warlock", "color": Color("9482c9"), "armor": ["cloth"],
		"weapons": ["staff", "dagger", "sword", "wand"], "races": ["orc", "undead"]},
	"druid": {"name": "Druid", "color": Color("ff7d0a"), "armor": ["leather", "cloth"],
		"weapons": ["staff", "mace", "dagger", "polearm"], "races": ["tauren"]},
	"priest": {"name": "Priest", "color": Color("ffffff"), "armor": ["cloth"],
		"weapons": ["staff", "mace", "dagger", "wand"], "races": ["troll", "undead"]},
}

## role: tank / melee / ranged (the priest is the guild's only healer). stat: which item profile suits them.
## dps and hp are in level units; mit multiplies damage taken; aggro is how well they hold enemies.
const SPECS := {
	"warrior_arms": {"class": "warrior", "name": "Arms", "role": "melee", "stat": "physical",
		"dps": 12.0, "hp": 150, "mit": 0.85, "aggro": 0.55, "util": ["battle_shout"]},
	"warrior_fury": {"class": "warrior", "name": "Fury", "role": "melee", "stat": "physical",
		"dps": 12.8, "hp": 150, "mit": 0.85, "aggro": 0.6, "util": ["battle_shout"]},
	"warrior_protection": {"class": "warrior", "name": "Protection", "role": "tank", "stat": "tank",
		"dps": 5.5, "hp": 215, "mit": 0.6, "aggro": 0.93, "util": ["battle_shout"]},
	"shaman_elemental": {"class": "shaman", "name": "Elemental", "role": "ranged", "stat": "spell",
		"dps": 12.0, "hp": 118, "mit": 0.95, "aggro": 0.0, "util": ["totems", "poison_cleansing"]},
	"shaman_enhancement": {"class": "shaman", "name": "Enhancement", "role": "melee", "stat": "physical",
		"dps": 11.6, "hp": 142, "mit": 0.88, "aggro": 0.45, "util": ["windfury", "poison_cleansing"]},
	"rogue_assassination": {"class": "rogue", "name": "Assassination", "role": "melee", "stat": "physical",
		"dps": 13.2, "hp": 128, "mit": 0.92, "aggro": 0.35, "util": ["evasion"]},
	"rogue_combat": {"class": "rogue", "name": "Combat", "role": "melee", "stat": "physical",
		"dps": 13.6, "hp": 128, "mit": 0.92, "aggro": 0.35, "util": ["evasion"]},
	"rogue_subtlety": {"class": "rogue", "name": "Subtlety", "role": "melee", "stat": "physical",
		"dps": 13.0, "hp": 128, "mit": 0.92, "aggro": 0.3, "util": ["evasion"]},
	"hunter_beast_mastery": {"class": "hunter", "name": "Beast Mastery", "role": "ranged", "stat": "physical",
		"dps": 12.6, "hp": 130, "mit": 0.95, "aggro": 0.0, "util": ["trueshot_aura", "feign_death"]},
	"hunter_marksmanship": {"class": "hunter", "name": "Marksmanship", "role": "ranged", "stat": "physical",
		"dps": 13.0, "hp": 128, "mit": 0.95, "aggro": 0.0, "util": ["trueshot_aura", "feign_death"]},
	"hunter_survival": {"class": "hunter", "name": "Survival", "role": "ranged", "stat": "physical",
		"dps": 12.6, "hp": 134, "mit": 0.93, "aggro": 0.0, "util": ["trueshot_aura", "feign_death"]},
	"mage_arcane": {"class": "mage", "name": "Arcane", "role": "ranged", "stat": "spell",
		"dps": 12.6, "hp": 106, "mit": 1.0, "aggro": 0.0, "util": ["arcane_intellect", "remove_curse"]},
	"mage_fire": {"class": "mage", "name": "Fire", "role": "ranged", "stat": "spell",
		"dps": 13.8, "hp": 106, "mit": 1.0, "aggro": 0.0, "util": ["arcane_intellect", "remove_curse"]},
	"mage_frost": {"class": "mage", "name": "Frost", "role": "ranged", "stat": "spell",
		"dps": 13.0, "hp": 110, "mit": 0.95, "aggro": 0.0, "util": ["arcane_intellect", "remove_curse"]},
	"warlock_affliction": {"class": "warlock", "name": "Affliction", "role": "ranged", "stat": "spell",
		"dps": 12.8, "hp": 118, "mit": 1.0, "aggro": 0.0, "util": ["soulstone", "healthstone"]},
	"warlock_destruction": {"class": "warlock", "name": "Destruction", "role": "ranged", "stat": "spell",
		"dps": 13.6, "hp": 116, "mit": 1.0, "aggro": 0.0, "util": ["soulstone", "healthstone"]},
	"warlock_demonology": {"class": "warlock", "name": "Demonology", "role": "ranged", "stat": "spell",
		"dps": 12.4, "hp": 130, "mit": 0.95, "aggro": 0.0, "util": ["soulstone", "healthstone"]},
	"druid_balance": {"class": "druid", "name": "Balance", "role": "ranged", "stat": "spell",
		"dps": 11.6, "hp": 122, "mit": 0.92, "aggro": 0.0, "util": ["innervate", "remove_curse"]},
	"druid_feral": {"class": "druid", "name": "Feral (Bear)", "role": "tank", "stat": "tank",
		"dps": 6.5, "hp": 210, "mit": 0.64, "aggro": 0.86, "util": ["innervate", "barkskin"]},
	"druid_cat": {"class": "druid", "name": "Feral (Cat)", "role": "melee", "stat": "physical",
		"dps": 12.8, "hp": 136, "mit": 0.9, "aggro": 0.4, "util": ["innervate"]},
}

const UTILS := {
	"battle_shout": {"name": "Battle Shout", "desc": "Melee guildmates deal 5% more damage."},
	"totems": {"name": "Mana Spring Totem", "desc": "Your mana regeneration is increased by 10%."},
	"windfury": {"name": "Windfury Totem", "desc": "Every hit by a guildmate has a 5% chance to deal double damage."},
	"poison_cleansing": {"name": "Poison Cleansing Totem", "desc": "Removes a poison from the party every 6s."},
	"evasion": {"name": "Evasion", "desc": "Once per fight when attacked below 50% health: takes 50% less damage for 8s."},
	"trueshot_aura": {"name": "Trueshot Aura", "desc": "Physical guildmates deal 4% more damage."},
	"feign_death": {"name": "Feign Death", "desc": "Drops aggro shortly after being attacked."},
	"arcane_intellect": {"name": "Arcane Intellect", "desc": "Your maximum mana is increased by 8%."},
	"remove_curse": {"name": "Remove Curse", "desc": "Removes a curse from the party every 6s."},
	"soulstone": {"name": "Soulstone", "desc": "Once per activity, brings you back to life if you fall."},
	"healthstone": {"name": "Healthstone", "desc": "Each guildmate eats a Healthstone once per fight below 30% health."},
	"innervate": {"name": "Innervate", "desc": "Once per fight below 35% mana: your mana regeneration is quadrupled for 10s."},
	"barkskin": {"name": "Barkskin", "desc": "Once per fight below 30% health: takes 30% less damage for 12s."},
}

const RACES := {
	"orc": "Orc", "troll": "Troll", "tauren": "Tauren", "undead": "Undead",
}

const ROLE_NAMES := {"tank": "Tank", "melee": "Melee", "ranged": "Ranged", "priest": "Healer"}

## Healer specs from older saves, and what those guildmates retrain into (priests leave the guild).
const RETIRED_SPECS := {"shaman_restoration": "shaman_elemental", "druid_restoration": "druid_balance",
	"priest_holy": "", "priest_discipline": ""}


static func spec(spec_id: String) -> Dictionary:
	return SPECS.get(spec_id, {})


static func class_of(spec_id: String) -> String:
	return SPECS.get(spec_id, {}).get("class", "priest")


static func color(class_id: String) -> Color:
	return CLASSES.get(class_id, {}).get("color", Color.WHITE)


static func class_name_of(class_id: String) -> String:
	return CLASSES.get(class_id, {}).get("name", class_id.capitalize())


static func role(spec_id: String) -> String:
	return SPECS.get(spec_id, {}).get("role", "melee")


static func specs_of_class(class_id: String) -> Array:
	var out := []
	for id in SPECS:
		if SPECS[id]["class"] == class_id:
			out.append(id)
	return out


## Spec weights for recruitment: tanks are rarer than damage dealers. Nobody else heals.
static func random_spec(rng: RandomNumberGenerator) -> String:
	var want_tank := rng.randf() < 0.2
	var pool: Array = []
	for id in SPECS:
		if (SPECS[id]["role"] == "tank") == want_tank:
			pool.append(id)
	return pool[rng.randi() % pool.size()]
