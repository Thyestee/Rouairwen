class_name Buildings
## The settlement's buildings: what each one is, what it costs to build, and its upgrades.
## Every building has its own menu (building_menu.gd) listing these upgrades.
##
## An upgrade belongs to one building and has a "max" level. It costs either an explicit list of
## "costs" (one per level) or a "cost" that grows by "growth" each level. "value" is its effect per
## level; "effect" is a sentence with one %s for the total effect, printed in its "format":
## percent (12%), plus (+2), hours (4h) or plain (0.5).

const ORDER := ["hall", "farm", "mill", "lodge", "tannery", "inn", "guild"]

## "cost" builds it (the guild's is the price of founding Lumens); buildings with no cost are always
## there. "requires" names a building that has to come first.
const INFO := {
	"hall": {"name": "Great Hall", "upgrades": ["hall_tier", "peon_barracks", "warchiefs_vault"],
		"about": "The heart of the settlement, where Peons drop off what they gather."},
	"farm": {"name": "Pig Farms", "upgrades": ["bigger_pens", "roasting_spits"],
		"about": "Pigs feed the Horde. Every farm raises the food cap, so you can train more Peons."},
	"mill": {"name": "War Mill", "cost": {"gold": 60.0, "lumber": 40.0}, "upgrades": ["lumber_harvesting", "sawpit"],
		"about": "Saws, axes and grindstones for the lumberjacks."},
	"lodge": {"name": "Hunter's Lodge", "cost": {"gold": 120.0, "lumber": 80.0}, "upgrades": ["tracking", "trophy_hunting", "smokehouse"],
		"about": "Home of the Skinners, who hunt the beasts of Durotar for their skins and meat."},
	"tannery": {"name": "Tannery", "cost": {"gold": 150.0, "lumber": 100.0, "skins": 10.0}, "upgrades": ["tanning_racks", "salt_curing"],
		"about": "Leatherworkers scrape and cure skins into leather for bags."},
	"inn": {"name": "Inn", "cost": {"gold": 250.0, "lumber": 120.0}, "requires": "guild",
		"upgrades": ["inn_renown", "recruitment_board", "comfortable_beds"],
		"about": "Adventurers of every class drink here, and some will join the guild."},
	"guild": {"name": "Lumens Guild Hall", "cost": {"gold": 150.0, "lumber": 75.0},
		"upgrades": ["training_grounds", "quartermaster", "war_chest"],
		"about": "The guild's banner and war room, where parties are sent questing."},
}

const UPGRADES := {
	# Great Hall
	"hall_tier": {"building": "hall", "name": "Hall Upgrade", "max": 2, "value": 1.0,
		"costs": [{"gold": 250.0, "lumber": 120.0}, {"gold": 2500.0, "lumber": 1200.0}]},
	"peon_barracks": {"building": "hall", "name": "Peon Barracks", "max": 3, "value": 0.12, "format": "percent",
		"cost": {"gold": 150.0, "lumber": 80.0}, "growth": 3.0, "effect": "Peons cost %s less to train"},
	"warchiefs_vault": {"building": "hall", "name": "Warchief's Vault", "max": 3, "value": 4.0, "format": "hours",
		"cost": {"gold": 300.0, "lumber": 200.0}, "growth": 3.0, "effect": "Keeps gathering %s longer while away"},
	# Pig Farms
	"bigger_pens": {"building": "farm", "name": "Bigger Pens", "max": 3, "value": 1.0, "format": "plus",
		"cost": {"gold": 100.0, "lumber": 60.0}, "growth": 3.0, "effect": "%s food per Pig Farm"},
	"roasting_spits": {"building": "farm", "name": "Roasting Spits", "max": 3, "value": 0.06, "format": "percent",
		"cost": {"gold": 120.0, "lumber": 80.0}, "growth": 2.5, "effect": "Well-fed Peons walk %s faster"},
	# War Mill
	"lumber_harvesting": {"building": "mill", "name": "Lumber Harvesting", "max": 5, "value": 0.5, "format": "percent",
		"cost": {"gold": 60.0, "lumber": 40.0}, "growth": 2.0, "effect": "%s more lumber per delivery"},
	"sawpit": {"building": "mill", "name": "Sawpit", "max": 3, "value": 0.15, "format": "percent",
		"cost": {"gold": 150.0, "lumber": 120.0}, "growth": 2.5, "effect": "Lumberjacks chop %s faster"},
	# Hunter's Lodge
	"tracking": {"building": "lodge", "name": "Tracking", "max": 3, "value": 0.2, "format": "percent",
		"cost": {"gold": 120.0, "lumber": 60.0, "skins": 10.0}, "growth": 2.5, "effect": "Skinners hunt %s faster"},
	"trophy_hunting": {"building": "lodge", "name": "Trophy Hunting", "max": 3, "value": 1.0, "format": "plus",
		"cost": {"gold": 200.0, "lumber": 100.0, "skins": 20.0}, "growth": 3.0, "effect": "%s skins per hunt"},
	"smokehouse": {"building": "lodge", "name": "Smokehouse", "max": 3, "value": 1.0, "format": "percent",
		"cost": {"gold": 150.0, "lumber": 120.0}, "growth": 2.5, "effect": "%s more food from every hunt"},
	# Tannery
	"tanning_racks": {"building": "tannery", "name": "Tanning Racks", "max": 3, "value": 0.2, "format": "percent",
		"cost": {"gold": 150.0, "lumber": 100.0, "leather": 5.0}, "growth": 2.5, "effect": "Leatherworkers work %s faster"},
	"salt_curing": {"building": "tannery", "name": "Salt Curing", "max": 3, "value": 0.25, "format": "plain",
		"cost": {"gold": 200.0, "skins": 30.0}, "growth": 2.5, "effect": "%s fewer skins per leather"},
	# Inn
	"inn_renown": {"building": "inn", "name": "Inn Renown", "max": 10, "value": 0.12, "format": "percent",
		"cost": {"gold": 200.0, "lumber": 100.0}, "growth": 1.7, "effect": "Better odds of high-tier recruits"},
	"recruitment_board": {"building": "inn", "name": "Recruitment Board", "max": 3, "value": 0.1, "format": "percent",
		"cost": {"gold": 250.0, "lumber": 120.0}, "growth": 3.0, "effect": "Recruiting costs %s less"},
	"comfortable_beds": {"building": "inn", "name": "Comfortable Beds", "max": 3, "value": 0.15, "format": "percent",
		"cost": {"gold": 300.0, "cloth": 10.0}, "growth": 3.0, "effect": "Rested members gain %s more experience"},
	# Lumens Guild Hall
	"training_grounds": {"building": "guild", "name": "Training Grounds", "max": 5, "value": 0.05, "format": "percent",
		"cost": {"gold": 400.0, "lumber": 200.0}, "growth": 2.2, "effect": "Members fight with %s more health and power"},
	"quartermaster": {"building": "guild", "name": "Quartermaster", "max": 3, "value": 0.15, "format": "percent",
		"cost": {"gold": 500.0, "cloth": 15.0}, "growth": 3.0, "effect": "%s more gear from quests, of better quality"},
	"war_chest": {"building": "guild", "name": "War Chest", "max": 3, "value": 0.2, "format": "percent",
		"cost": {"gold": 400.0, "lumber": 200.0}, "growth": 3.0, "effect": "Quests bring back %s more gold and cloth"},
}


static func upgrade_cost(id: String, level: int) -> Dictionary:
	var upgrade: Dictionary = UPGRADES[id]
	if upgrade.has("costs"):
		return upgrade.costs[level]
	var factor := pow(upgrade.growth, level)
	var cost := {}
	for resource in upgrade.cost:
		cost[resource] = ceilf(upgrade.cost[resource] * factor)
	return cost


## The upgrade's effect at a given level, e.g. "Peons cost 24% less to train".
static func effect_text(id: String, level: int) -> String:
	var upgrade: Dictionary = UPGRADES[id]
	var total: float = upgrade.value * level
	var amount := ""
	match upgrade.get("format", "plain"):
		"percent":
			amount = "%d%%" % roundi(total * 100.0)
		"plus":
			amount = "+%d" % roundi(total)
		"hours":
			amount = "%dh" % roundi(total)
		_:
			amount = ("%.2f" % total).rstrip("0").rstrip(".")
	var effect: String = upgrade.get("effect", "")
	return effect % amount if "%s" in effect else effect
