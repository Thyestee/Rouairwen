class_name Prestige
## Prestige: earned by killing raid bosses, spent on training guildmates past grade A, and ranked
## (everything ever earned, spending included) against the Horde's other raiding guilds.
##
## The ladder is fixed: 100 rival guilds. Its top score is what a guild earns in about 50 hours at
## level 60 (see the prestige model in tools/balance_sim.gd), so taking the #1 spot is the long goal;
## the others step down evenly to a few kills' worth, so the first raids already climb dozens of ranks.

## The #1 guild's prestige.
const TOP := 5600
## Each guild down the ladder has this share of the one above it (the last has about 10).
const STEP := 0.938
const RIVALS := ["Kor'kron Legacy", "Bloodfang Vanguard", "Warsong Outriders", "Spirit Walkers", "Crimson Oath",
	"Darkspear Pact", "Thunder Ridge", "Ashen Tusk", "Stormreaver", "Sunwalker Circle", "Dreadmaw",
	"Blackrock Defiance", "Mok'Nathal Hunters", "Ironwood Grove", "Shattered Hand", "Bonechewers",
	"Grim Totem", "Razormane Raiders", "Frostwolf Exiles", "Echo Isles Tide",
	"Hellscream's Fist", "Doomhammer Legacy", "Burning Blade", "Dragonmaw Reavers", "Onyxia's Bane",
	"Molten Hearts", "Firelord's End", "Blackwing Breakers", "Scourge Bane", "Deathguard Watch",
	"Dark Ranger Vigil", "Forsaken Choir", "Plaguewalkers", "Kodo Stampede", "Bloodhoof Kin",
	"Red Cloud Mesa", "Earthen Seers", "Totemic Fury", "Windfury Brothers", "Wolfrider Pack",
	"Spinebreakers", "Skullsplitters", "Gutrippers", "Sen'jin Hexers", "Zandalari Envoys",
	"Hakkar's Bane", "Gurubashi Champions", "Sandfury Raiders", "Bael'dun Breakers", "Razorfen Diggers",
	"Stonetalon Raiders", "Splintertree Post", "Desolace Nomads", "Needlerock Racers", "Gadgetzan Bruisers",
	"Tanaris Sandstorm", "Un'Goro Stalkers", "Felwood Purifiers", "Winterspring Frost", "Azshara Tides",
	"Silithid Slayers", "Sands of Time", "Tirisfal Shades", "Brill Gravediggers", "Silverpine Howl",
	"Tarren Mill Veterans", "Alterac Wolves", "Hammerfall Defenders", "Kargath Iron", "Searing Gorge",
	"Burning Steppes", "Stonard Watch", "Grom'gol Expedition", "Booty Bay Buccaneers", "Zul'Farrak Seekers",
	"Maraudon Wardens", "Bilgewater Brawlers", "Ratchet Riggers", "Crossroads Watch", "Ragefire Delvers",
	"Wailing Fangs", "Blackfathom Divers", "Orgrimmar Night Watch", "Valley of Honor Pit", "Durotar Dust",
	"Thousand Needles", "Mulgore Plainsmen", "Ashenvale Hunters", "Lordaeron Ruins", "Swamp of Sorrows",
	"Badlands Prospectors", "Everlook Traders", "Cenarion Shadows", "Naxxramas Bound", "Lich Hunters",
	"Dustwallow Mire", "Theramore Sackers", "Arathi Defiance", "Stranglethorn Fishers", "Kalimdor Vanguard"]


## Prestige for killing a boss of a raid; the final boss is worth double.
static func for_boss(raid: Dictionary, final: bool) -> int:
	return raid.get("prestige", 0) * (2 if final else 1)


## Prestige for a whole clear of a raid.
static func for_clear(raid: Dictionary) -> int:
	var total := 0
	for b in raid["bosses"]:
		total += for_boss(raid, b.get("final", false))
	return total


static func rival_score(i: int) -> int:
	return int(round(TOP * pow(STEP, i)))


## The ladder with <Lumens> in it: [{name, score, you}], best first.
static func ladder(total: int) -> Array:
	var out := []
	var placed := false
	for i in RIVALS.size():
		var s := rival_score(i)
		if not placed and total > s:
			out.append({"name": "Lumens", "score": total, "you": true})
			placed = true
		out.append({"name": RIVALS[i], "score": s, "you": false})
	if not placed:
		out.append({"name": "Lumens", "score": total, "you": true})
	return out


## <Lumens>' rank on the ladder (1 is the top).
static func rank(total: int) -> int:
	var r := 1
	for i in RIVALS.size():
		if rival_score(i) >= total:
			r += 1
	return r


static func guild_count() -> int:
	return RIVALS.size() + 1
