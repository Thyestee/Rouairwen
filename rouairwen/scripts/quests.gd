class_name Quests
## The quest board: WoW Classic places (Horde side), from Durotar to Blackrock Depths.
## A party of three goes for 5 minutes, then fights the quest's foes turn by turn (see combat.gd).
## Victory brings back gold, cloth and sometimes gear, in random amounts revealed only on return.
## Each quest favours three random specs, rerolled after every run: members of those specs fight
## stronger. Everyone gains experience, more on a victory.

const PARTY_SIZE := 3
const DURATION := 300.0  # seconds

## Experience per run, out of Fighters.XP_PER_LEVEL, for a quest around the fighter's level.
const XP_VICTORY := 34
const XP_DEFEAT := 12
## Quests more than this many levels below a fighter give less experience (20% less per level).
const XP_GRACE_LEVELS := 2

## "difficulty" scales the foes; "share" splits their total health and damage between them.
## A foe "ability" fires every few rounds: aoe hits the whole party, heavy hits one target hard,
## heal restores the foe, enrage makes it hit harder once it's low.
const LIST := [
	{"id": "valley_of_trials", "name": "Valley of Trials", "zone": "Durotar", "level": 1, "difficulty": 0.45, "foes": [
		{"name": "Vile Familiar", "share": 0.3},
		{"name": "Sarkoth", "share": 0.7, "boss": true, "ability": {"name": "Venomous Sting", "type": "heavy", "every": 3}},
	]},
	{"id": "echo_isles", "name": "Echo Isles", "zone": "Durotar", "level": 4, "difficulty": 0.75, "foes": [
		{"name": "Voodoo Troll", "share": 0.3},
		{"name": "Voodoo Troll", "share": 0.3},
		{"name": "Zalazane", "share": 0.4, "boss": true, "ability": {"name": "Healing Wave", "type": "heal", "every": 4}},
	]},
	{"id": "tiragarde_keep", "name": "Tiragarde Keep", "zone": "Durotar", "level": 7, "difficulty": 0.9, "foes": [
		{"name": "Kul Tiras Marine", "share": 0.3},
		{"name": "Kul Tiras Marine", "share": 0.3},
		{"name": "Lieutenant Benedict", "share": 0.4, "boss": true, "ability": {"name": "Shield Bash", "type": "heavy", "every": 3}},
	]},
	{"id": "kolkar_raiders", "name": "Kolkar Raiders", "zone": "The Barrens", "level": 11, "difficulty": 1.0, "foes": [
		{"name": "Kolkar Wrangler", "share": 0.3},
		{"name": "Kolkar Stormer", "share": 0.25},
		{"name": "Barak Kodobane", "share": 0.45, "boss": true, "ability": {"name": "Thunderclap", "type": "aoe", "every": 3}},
	]},
	{"id": "wailing_caverns", "name": "Wailing Caverns", "zone": "The Barrens", "level": 17, "difficulty": 1.0, "foes": [
		{"name": "Deviate Raptor", "share": 0.25},
		{"name": "Lord Cobrahn", "share": 0.3, "ability": {"name": "Druid's Slumber", "type": "heal", "every": 4}},
		{"name": "Mutanus the Devourer", "share": 0.45, "boss": true, "ability": {"name": "Thundercrack", "type": "aoe", "every": 3}},
	]},
	{"id": "shadowfang_keep", "name": "Shadowfang Keep", "zone": "Silverpine Forest", "level": 21, "difficulty": 0.9, "foes": [
		{"name": "Shadowfang Moonwalker", "share": 0.25},
		{"name": "Shadowfang Moonwalker", "share": 0.25},
		{"name": "Archmage Arugal", "share": 0.5, "boss": true, "ability": {"name": "Void Bolt", "type": "heavy", "every": 3}},
	]},
	{"id": "blackfathom_deeps", "name": "Blackfathom Deeps", "zone": "Ashenvale", "level": 25, "difficulty": 1.0, "foes": [
		{"name": "Twilight Acolyte", "share": 0.25, "ability": {"name": "Renew", "type": "heal", "every": 4}},
		{"name": "Twilight Acolyte", "share": 0.25},
		{"name": "Aku'mai", "share": 0.5, "boss": true, "ability": {"name": "Frenzied Rage", "type": "enrage"}},
	]},
	{"id": "razorfen_kraul", "name": "Razorfen Kraul", "zone": "The Barrens", "level": 29, "difficulty": 1.0, "foes": [
		{"name": "Razorfen Quilguard", "share": 0.3},
		{"name": "Razorfen Spearhide", "share": 0.25},
		{"name": "Charlga Razorflank", "share": 0.45, "boss": true, "ability": {"name": "Chain Bolt", "type": "aoe", "every": 3}},
	]},
	{"id": "scarlet_monastery", "name": "Scarlet Monastery", "zone": "Tirisfal Glades", "level": 35, "difficulty": 1.0, "foes": [
		{"name": "Scarlet Myrmidon", "share": 0.25},
		{"name": "Scarlet Myrmidon", "share": 0.25},
		{"name": "Herod", "share": 0.5, "boss": true, "ability": {"name": "Whirlwind", "type": "aoe", "every": 3}},
	]},
	{"id": "uldaman", "name": "Uldaman", "zone": "Badlands", "level": 42, "difficulty": 1.0, "foes": [
		{"name": "Stone Keeper", "share": 0.25},
		{"name": "Stone Keeper", "share": 0.25},
		{"name": "Archaedas", "share": 0.5, "boss": true, "ability": {"name": "Ground Tremor", "type": "aoe", "every": 3}},
	]},
	{"id": "zul_farrak", "name": "Zul'Farrak", "zone": "Tanaris", "level": 46, "difficulty": 1.0, "foes": [
		{"name": "Sandfury Executioner", "share": 0.3, "ability": {"name": "Cleave", "type": "heavy", "every": 3}},
		{"name": "Chief Ukorz Sandscalp", "share": 0.7, "boss": true, "ability": {"name": "Frenzy", "type": "enrage"}},
	]},
	{"id": "maraudon", "name": "Maraudon", "zone": "Desolace", "level": 50, "difficulty": 0.92, "foes": [
		{"name": "Primordial Behemoth", "share": 0.35, "ability": {"name": "Boulder", "type": "heavy", "every": 3}},
		{"name": "Princess Theradras", "share": 0.65, "boss": true, "ability": {"name": "Dust Field", "type": "aoe", "every": 3}},
	]},
	{"id": "blackrock_depths", "name": "Blackrock Depths", "zone": "Blackrock Mountain", "level": 56, "difficulty": 0.88, "foes": [
		{"name": "Anvilrage Guardsman", "share": 0.2},
		{"name": "Anvilrage Guardsman", "share": 0.2},
		{"name": "Emperor Dagran Thaurissan", "share": 0.6, "boss": true, "ability": {"name": "Hand of Thaurissan", "type": "heavy", "every": 3}},
	]},
]


static func get_quest(id: String) -> Dictionary:
	for quest in LIST:
		if quest.id == id:
			return quest
	return {}


## Rough party power the quest is built for: three average C-tier members at its level, no gear.
static func recommended_power(quest: Dictionary) -> int:
	return roundi(PARTY_SIZE * Fighters.reference_power(quest.level) * quest.difficulty)


## Three different specs, picked at random, that this quest favours.
static func roll_favoured() -> Array[String]:
	var keys := Fighters.all_spec_keys()
	keys.shuffle()
	return keys.slice(0, PARTY_SIZE)


## What a victory brings back: random gold and cloth, and a chance at gear (better in dungeons).
## `loot_bonus` (the Quartermaster) raises the gear chance and quality; `wealth` (the War Chest)
## multiplies the gold and cloth.
static func roll_rewards(quest: Dictionary, next_item_id: int, loot_bonus := 0.0, wealth := 1.0) -> Dictionary:
	var level: int = quest.level
	var items := []
	var dungeon := level >= 17
	var quality_odds := (1.4 if dungeon else 1.0) * (1.0 + loot_bonus * 2.0)
	if randf() < (0.8 if dungeon else 0.6) + loot_bonus:
		items.append(Items.create(next_item_id, maxi(1, level + randi_range(-1, 2)), quality_odds))
	if dungeon and randf() < 0.25 + loot_bonus:
		items.append(Items.create(next_item_id + 1, maxi(1, level + randi_range(0, 3)), quality_odds))
	return {
		"gold": roundf((randi_range(6, 12) * level + randi_range(10, 30)) * wealth),
		"cloth": roundf((randi_range(1, 3) + floori(level / 4.0)) * wealth),
		"items": items,
	}


## A sensible party: one Tank, one Healer and one DPS where possible (favoured specs first, then
## the most powerful), and the strongest remaining members for any role nobody can fill.
static func suggest_party(free: Array, favoured: Array) -> Array:
	var pool := free.duplicate()
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_favoured := Fighters.spec_key(a) in favoured
		var b_favoured := Fighters.spec_key(b) in favoured
		if a_favoured != b_favoured:
			return a_favoured
		return Fighters.power(a) > Fighters.power(b))
	var party := []
	for role in Fighters.ROLES:
		for fighter in pool:
			if not party.has(fighter) and Fighters.spec_of(fighter).role == role:
				party.append(fighter)
				break
	for fighter in pool:
		if party.size() >= PARTY_SIZE:
			break
		if not party.has(fighter):
			party.append(fighter)
	return party


## Experience for one member: full at or near the quest's level, less if they've outgrown it.
static func xp_for(fighter_level: int, quest: Dictionary, victory: bool) -> int:
	var base := XP_VICTORY if victory else XP_DEFEAT
	var gap: int = fighter_level - quest.level - XP_GRACE_LEVELS
	var factor := 1.0 if gap <= 0 else maxf(0.1, 1.0 - 0.2 * gap)
	return roundi(base * factor)
