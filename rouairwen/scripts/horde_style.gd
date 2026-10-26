class_name HordeStyle
## The game's look: Horde names, fonts, border style and colour palette.

const NAMES := {
	"faction": "Horde",
	"worker": "Peon",
	"workers": "Peons",
	"farm": "Pig Farm",
	"halls": ["Great Hall", "Stronghold", "Fortress"],
	"mill": "War Mill",
	"train_flavor": "Work work.",
	"greeting": "Lok'tar, Warchief! Put your Peons to work at the mine and in the forest, then build Pig Farms.",
	"job_workers": {"gold": "Miners", "lumber": "Lumberjacks", "skins": "Skinners", "leather": "Leatherworkers"},
}

const BODY_FONTS := ["Trebuchet MS", "Verdana", "sans-serif"]
const BODY_WEIGHT := 600
const HEADING_FONTS := ["Impact", "Haettenschweiler", "Arial Black", "sans-serif"]
const HEADING_WEIGHT := 400
## Panels and buttons: cut corners (corner_detail 1), thick borders, slightly slanted buttons.
const BORDER := {"corner_radius": 12, "corner_detail": 1, "border_width": 3, "button_skew": 0.08}

const PALETTE := {
	# Interface
	"text": Color("f4e8d8"),
	"muted": Color("c09f86"),
	"accent": Color("ff9a3c"),
	"outline": Color("1a0603"),
	"panel": Color(0.13, 0.05, 0.03, 0.92),
	"panel_solid": Color("2a0f08"),
	"border": Color("8e2a1a"),
	"button": Color("3d1a10"),
	"button_hover": Color("5e2616"),
	"primary": Color("a3241a"),
	"bg_top": Color("1a0503"),
	"bg_bottom": Color("4a1408"),
	"mote": Color("ff8a3a"),
	# Scenery
	"sky_top": Color("5a1a10"),
	"sky_bottom": Color("e0773a"),
	"sun": Color("ff5a2a"),
	"hills_far": Color("6a2c1c"),
	"hills_near": Color("4a2316"),
	"ground_top": Color("8a5a33"),
	"ground_bottom": Color("5a3a20"),
	"path": Color("a87a4a"),
	"tree_dark": Color("2f3a1c"),
	"tree_light": Color("4a5426"),
	"trunk": Color("3d2614"),
	"rock": Color("7a6a5e"),
	"rock_dark": Color("5e5148"),
	"wood": Color("6b4424"),
	"banner": Color("a3241a"),
	"trim": Color("ff9a3c"),
	"skin": Color("6f9a3b"),
	"tunic": Color("5b3b22"),
	"window_light": Color("ffb04a"),
	"hide": Color("a7774a"),
	"hide_dark": Color("7a5232"),
	"bone": Color("eadcc0"),
	"pen": Color("6a4a2c"),
	"pig": Color("e3a0a6"),
	# The Lumens guild: deep violet with a radiant golden sun
	"guild": Color("3b2675"),
	"guild_light": Color("ffd86b"),
	"guild_core": Color("fff4cf"),
}
