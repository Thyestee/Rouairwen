class_name Runes
## Runes: three slots Thyeste engraves as he levels, one rune in each, changed for free between fights.
## A spell rune changes how one of his spells works, a personal rune is a passive for him and a group
## rune a passive for the whole party. The slots open at levels 20, 30 and 40, and each rune unlocks at a
## level where what it improves is within reach: Flash Heal and Power Word: Shield are known by 20,
## Prayer of Mending and Penance are talents from 20 (10 points in their tree), Prayer of Healing is
## learned at 30.
##
## A rune's numbers ("value" and the like) fill the {placeholders} of its description.

const SLOTS := [
	{"id": "spell", "name": "Spell Rune", "level": 20, "color": Color("ffd86b"), "desc": "Changes how one of your spells works."},
	{"id": "personal", "name": "Personal Rune", "level": 30, "color": Color("8fd3ff"), "desc": "A passive of your own."},
	{"id": "group", "name": "Group Rune", "level": 40, "color": Color("6ee06e"), "desc": "A passive for your whole party."},
]

## In each slot's order. "spell": the spell a spell rune changes; "icon": the drawn glyph (SpellIcon),
## "wow": the WoW icon.
const LIST := {
	# Spell runes
	"mending": {"slot": "spell", "name": "Rune of Mending", "level": 20, "spell": "prayer_of_mending", "icon": "pom",
		"wow": "spell_holy_prayerofmendingtga",
		"desc": "Prayer of Mending also casts Renew on each ally it heals."},
	"binding": {"slot": "spell", "name": "Rune of Binding Light", "level": 20, "spell": "flash_heal", "icon": "flash",
		"wow": "spell_holy_blindingheal", "value": 100,
		"desc": "Flash Heal also heals the most injured other ally for the same amount."},
	"penitence": {"slot": "spell", "name": "Rune of Penitence", "level": 20, "spell": "penance", "icon": "penance",
		"wow": "spell_holy_penance", "value": 2, "cooldown": 4,
		"desc": "Penance fires {value} more bolts (5 over 4 sec), and its cooldown is {cooldown} sec shorter."},
	"soul_warding": {"slot": "spell", "name": "Rune of Soul Warding", "level": 20, "spell": "shield", "icon": "shield",
		"wow": "spell_holy_powerwordbarrier", "value": 30,
		"desc": "Power Word: Shield no longer causes Weakened Soul and costs {value}% less mana: shield anyone, again and again."},
	"echoing_prayer": {"slot": "spell", "name": "Rune of Echoing Prayer", "level": 30, "spell": "prayer_of_healing", "icon": "poh",
		"wow": "spell_holy_prayerofspirit", "value": 100, "duration": 6,
		"desc": "Prayer of Healing heals each ally it reaches as much again over {duration} sec."},
	# Personal runes
	"warding_light": {"slot": "personal", "name": "Rune of Warding Light", "level": 30, "icon": "aegis",
		"wow": "spell_holy_divineprotection", "value": 20, "crit": 10,
		"desc": "Your heals are {crit}% more likely to be critical, and each critical heal also shields the target for {value}% of the amount healed."},
	"clarity": {"slot": "personal", "name": "Rune of Clarity", "level": 30, "icon": "focus",
		"wow": "spell_shadow_manaburn", "value": 3,
		"desc": "After every {value} spells you pay for, you gain Clearcasting: your next spell costs no mana."},
	"desperate_prayer": {"slot": "personal", "name": "Rune of Desperate Prayer", "level": 35, "icon": "heal",
		"wow": "spell_holy_restoration", "value": 40, "below": 35, "bonus": 30, "cooldown": 60,
		"desc": "Your heals on allies below {below}% health are {bonus}% stronger. When your own health drops below {below}%, you heal yourself for {value}% of your maximum health, once every {cooldown} sec."},
	"overflow": {"slot": "personal", "name": "Rune of Overflowing Light", "level": 40, "icon": "lightwell",
		"wow": "spell_holy_aspiration", "value": 50, "cap": 20,
		"desc": "{value}% of your overhealing becomes a shield on the target, up to {cap}% of their maximum health."},
	"fervor": {"slot": "personal", "name": "Rune of Fervor", "level": 50, "icon": "fury",
		"wow": "spell_holy_innerfire", "value": 3, "stacks": 5, "duration": 10,
		"desc": "Each spell you cast makes your heals and shields {value}% stronger for {duration} sec, stacking {stacks} times."},
	# Group runes
	"shared_pain": {"slot": "group", "name": "Rune of Shared Pain", "level": 40, "icon": "suppression",
		"wow": "spell_shaman_spiritlink", "value": 20,
		"desc": "{value}% of the damage any ally takes is spread evenly across the whole party instead. Shared damage isn't shared again."},
	"fortitude": {"slot": "group", "name": "Rune of Fortitude", "level": 40, "icon": "strength",
		"wow": "spell_holy_wordfortitude", "value": 15,
		"desc": "Everyone in your party, you included, has {value}% more maximum health."},
	"zeal": {"slot": "group", "name": "Rune of Zeal", "level": 45, "icon": "infusion",
		"wow": "spell_holy_fanaticism", "value": 15,
		"desc": "Your guildmates deal {value}% more damage."},
	"atonement": {"slot": "group", "name": "Rune of Atonement", "level": 50, "icon": "penance",
		"wow": "ability_priest_atonement", "value": 5,
		"desc": "{value}% of the damage your guildmates deal heals the most injured ally, once a second."},
	"guardian": {"slot": "group", "name": "Rune of the Guardian Spirit", "level": 55, "icon": "spirit",
		"wow": "spell_holy_guardianspirit", "value": 40, "cooldown": 40,
		"desc": "When an ally (you included) would die, they are instead healed to {value}% of their maximum health. Once every {cooldown} sec."},
}


static func slot(slot_id: String) -> Dictionary:
	for s in SLOTS:
		if s["id"] == slot_id:
			return s
	return {}


## The runes of a slot, in order.
static func in_slot(slot_id: String) -> Array:
	return LIST.keys().filter(func(id): return LIST[id]["slot"] == slot_id)


static func value(id: String, key := "value") -> float:
	return float(LIST[id].get(key, 0))


static func describe(id: String) -> String:
	return LIST[id]["desc"].format(LIST[id])


static func slot_open(slot_id: String, level: int) -> bool:
	return level >= slot(slot_id)["level"]


static func unlocked(id: String, level: int) -> bool:
	return LIST.has(id) and level >= LIST[id]["level"]


## The engraved spell rune that changes this spell, if any.
static func for_spell(spell_id: String, engraved: Array) -> String:
	for id in engraved:
		if LIST.get(id, {}).get("spell", "") == spell_id:
			return id
	return ""


## A spell's engraved rune as a tooltip line ("" when none changes it).
static func spell_line(spell_id: String, engraved: Array) -> String:
	var r := for_spell(spell_id, engraved)
	return "" if r == "" else "[color=#ffd86b]%s:[/color] %s" % [LIST[r]["name"], describe(r)]


## Slots and runes that become available at exactly this level, for the level-up message.
static func new_at(level: int) -> Array:
	var out := []
	for s in SLOTS:
		if s["level"] == level:
			out.append(s["name"] + " slot")
	for id in LIST:
		if LIST[id]["level"] == level:
			out.append(LIST[id]["name"])
	return out
