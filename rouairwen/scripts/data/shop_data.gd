class_name ShopData
## Consumables sold on the Drag in Orgrimmar. Each category has ranks unlocked by level;
## the shop sells the best rank you can use. "value" is a percent for buffs,
## or an amount in level units (at the rank's level) for potions.

const CATEGORIES := {
	"mana_potion": {"name": "Mana Potions", "kind": "potion", "price": 1.2, "icon": "mana_potion",
		"desc": "Drink one in combat (key F) to restore mana. 60s cooldown.",
		"ranks": [["Minor Mana Potion", 1, 120], ["Lesser Mana Potion", 14, 120], ["Mana Potion", 22, 120],
			["Greater Mana Potion", 31, 120], ["Superior Mana Potion", 41, 120], ["Major Mana Potion", 49, 120]]},
	"healing_potion": {"name": "Healing Potions", "kind": "potion", "price": 0.9, "icon": "healing_potion",
		"desc": "Guildmates drink one automatically below 25% health, once per fight each.",
		"ranks": [["Minor Healing Potion", 1, 55], ["Lesser Healing Potion", 6, 55], ["Healing Potion", 12, 55],
			["Greater Healing Potion", 21, 55], ["Superior Healing Potion", 35, 55], ["Major Healing Potion", 45, 55]]},
	"battle_elixir": {"name": "Battle Elixirs", "kind": "buff", "price": 2.5, "icon": "elixir_red",
		"desc": "Your guildmates deal more damage for the next activity.",
		"ranks": [["Elixir of Lion's Strength", 1, 4], ["Elixir of Lesser Agility", 12, 5], ["Elixir of Agility", 27, 6],
			["Elixir of Greater Agility", 38, 8], ["Elixir of the Mongoose", 46, 10], ["Juju Power", 55, 12]]},
	"guardian_elixir": {"name": "Guardian Elixirs", "kind": "buff", "price": 2.5, "icon": "elixir_green",
		"desc": "Your guildmates have more health for the next activity.",
		"ranks": [["Elixir of Minor Fortitude", 2, 4], ["Elixir of Fortitude", 25, 6], ["Elixir of Superior Defense", 43, 8],
			["Spirit of Zanza", 52, 10], ["Flask of the Titans", 58, 14]]},
	"priest_elixir": {"name": "Wisdom Elixirs", "kind": "buff", "price": 2.5, "icon": "elixir_blue",
		"desc": "Your maximum mana and healing are increased for the next activity.",
		"ranks": [["Elixir of Wisdom", 8, 4], ["Elixir of Greater Intellect", 37, 6], ["Mageblood Potion", 48, 8],
			["Flask of Distilled Wisdom", 56, 12]]},
	"food": {"name": "Feast", "kind": "buff", "price": 1.5, "icon": "food",
		"desc": "The whole party eats before setting out: mana regeneration increased for the next activity.",
		"ranks": [["Herb Baked Egg", 1, 6], ["Crispy Bat Wing", 10, 8], ["Goldthorn Tea", 30, 10],
			["Nightfin Soup", 40, 13], ["Runn Tum Tuber Surprise", 52, 16]]},
}

const ORDER := ["mana_potion", "healing_potion", "battle_elixir", "guardian_elixir", "priest_elixir", "food"]


## Index of the best rank available at a level (-1 if none yet).
static func best_rank(cat: String, level: int) -> int:
	var ranks: Array = CATEGORIES[cat]["ranks"]
	var best := -1
	for i in ranks.size():
		if ranks[i][1] <= level:
			best = i
	return best


static func rank_name(cat: String, rank: int) -> String:
	return CATEGORIES[cat]["ranks"][rank][0]


static func rank_level(cat: String, rank: int) -> int:
	return CATEGORIES[cat]["ranks"][rank][1]


static func rank_value(cat: String, rank: int) -> float:
	return CATEGORIES[cat]["ranks"][rank][2]


static func price(cat: String, rank: int) -> int:
	return int(round(Balance.income(rank_level(cat, rank)) * CATEGORIES[cat]["price"])) + 1
