class_name Gear
## Worker gear, bought in order along three lines, named after WoW Classic items:
## boots make workers walk faster, tools make them work faster, bags let them carry more per trip.
## Miners and lumberjacks are equipped separately: miners use picks, lumberjacks use axes.
## "value" is the walk speed multiplier, work speed multiplier, or amount carried per trip.

const BOOTS := [
	{"name": "Rough Leather Boots", "value": 1.2, "cost": {"gold": 30.0, "lumber": 10.0}},
	{"name": "Embossed Leather Boots", "value": 1.4, "cost": {"gold": 120.0, "lumber": 40.0}},
	{"name": "Fine Leather Boots", "value": 1.6, "cost": {"gold": 400.0, "lumber": 150.0}},
	{"name": "Dusky Boots", "value": 1.85, "cost": {"gold": 1200.0, "lumber": 500.0}},
	{"name": "Nightscape Boots", "value": 2.1, "cost": {"gold": 4000.0, "lumber": 1500.0}},
	{"name": "Swift Boots", "value": 2.5, "cost": {"gold": 12000.0, "lumber": 5000.0}},
]

## Mining picks, up the Classic metals. "color" tints the tool the peons hold.
const PICKS := [
	{"name": "Copper Pick", "value": 1.25, "color": Color("d0773f"), "cost": {"gold": 40.0, "lumber": 15.0}},
	{"name": "Bronze Pick", "value": 1.5, "color": Color("c9a046"), "cost": {"gold": 150.0, "lumber": 60.0}},
	{"name": "Iron Pick", "value": 1.8, "color": Color("9aa0a6"), "cost": {"gold": 500.0, "lumber": 200.0}},
	{"name": "Steel Pick", "value": 2.2, "color": Color("c9d1d8"), "cost": {"gold": 1500.0, "lumber": 600.0}},
	{"name": "Mithril Pick", "value": 2.7, "color": Color("a8e0ff"), "cost": {"gold": 5000.0, "lumber": 2000.0}},
	{"name": "Thorium Pick", "value": 3.3, "color": Color("7fd6c2"), "cost": {"gold": 15000.0, "lumber": 6000.0}},
	{"name": "Arcanite Pick", "value": 4.0, "color": Color("e07bff"), "cost": {"gold": 45000.0, "lumber": 18000.0}},
]

## Woodcutting axes, same metals, ending with the legendary Arcanite Reaper.
const AXES := [
	{"name": "Copper Axe", "value": 1.25, "color": Color("d0773f"), "cost": {"gold": 40.0, "lumber": 15.0}},
	{"name": "Bronze Axe", "value": 1.5, "color": Color("c9a046"), "cost": {"gold": 150.0, "lumber": 60.0}},
	{"name": "Iron Axe", "value": 1.8, "color": Color("9aa0a6"), "cost": {"gold": 500.0, "lumber": 200.0}},
	{"name": "Steel Axe", "value": 2.2, "color": Color("c9d1d8"), "cost": {"gold": 1500.0, "lumber": 600.0}},
	{"name": "Mithril Axe", "value": 2.7, "color": Color("a8e0ff"), "cost": {"gold": 5000.0, "lumber": 2000.0}},
	{"name": "Thorium Axe", "value": 3.3, "color": Color("7fd6c2"), "cost": {"gold": 15000.0, "lumber": 6000.0}},
	{"name": "Arcanite Reaper", "value": 4.0, "color": Color("e07bff"), "cost": {"gold": 45000.0, "lumber": 18000.0}},
]

## Bags are sewn from leather (from the Tannery) and cloth (brought back from quests).
const BAGS := [
	{"name": "Linen Bag", "value": 2.0, "cost": {"gold": 25.0, "leather": 2.0, "cloth": 3.0}},
	{"name": "Woolen Bag", "value": 3.0, "cost": {"gold": 100.0, "leather": 5.0, "cloth": 8.0}},
	{"name": "Red Woolen Bag", "value": 4.0, "cost": {"gold": 350.0, "leather": 12.0, "cloth": 20.0}},
	{"name": "Mageweave Bag", "value": 5.0, "cost": {"gold": 1000.0, "leather": 30.0, "cloth": 50.0}},
	{"name": "Runecloth Bag", "value": 6.0, "cost": {"gold": 3000.0, "leather": 70.0, "cloth": 120.0}},
	{"name": "Mooncloth Bag", "value": 8.0, "cost": {"gold": 9000.0, "leather": 150.0, "cloth": 300.0}},
	{"name": "Bottomless Bag", "value": 10.0, "cost": {"gold": 27000.0, "leather": 350.0, "cloth": 700.0}},
	{"name": "Onyxia Hide Backpack", "value": 12.0, "cost": {"gold": 80000.0, "leather": 800.0, "cloth": 1500.0}},
]

## The gear lines of each job.
const LINES := {
	"gold": {"boots": BOOTS, "tools": PICKS, "bags": BAGS},
	"lumber": {"boots": BOOTS, "tools": AXES, "bags": BAGS},
}
## Values before buying anything: normal speed, carrying 1.
const BASE := {"boots": 1.0, "tools": 1.0, "bags": 1.0}
const BASE_TOOL_COLOR := Color("8f8a80")  # crude stone tools


## Colour of the tool a job's workers hold at the given tools level.
static func tool_color(job: String, level: int) -> Color:
	return BASE_TOOL_COLOR if level == 0 else LINES[job].tools[level - 1].color
