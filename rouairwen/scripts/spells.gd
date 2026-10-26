class_name Spells
## Spell books for every WoW Classic class and spec, used in quest fights.
## Each recruit gets a random kit: their spec's signature spell (listed first) plus KIT_SIZE - 1 other
## spells of that spec, on top of their class's basic attack.
##
## A spell has a "kind" (attack, heal or support), a "target" (foe, foes, ally, allies or self),
## a "cd" (cooldown in turns) and any of these effects, scaled by the caster's potency:
##   mult: direct damage or healing           dot / hot: [amount per turn, turns]
##   stun: turns the target loses             shield: absorb amount
##   taunt: turns foes must attack the caster buff: [extra party damage, turns]
##   empower: [extra own damage, turns]       defend: [damage taken factor, turns]
##   weaken: [foe damage factor, turns]       drain: share of the damage healed back
##   execute: true to deal 2.5x damage to foes under 25% health

const KIT_SIZE := 3

const BOOK := {
	"warrior": {
		"Arms": [
			{"name": "Mortal Strike", "kind": "attack", "target": "foe", "mult": 1.7, "cd": 2},
			{"name": "Overpower", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 1},
			{"name": "Rend", "kind": "attack", "target": "foe", "mult": 0.3, "dot": [0.35, 4], "cd": 3},
			{"name": "Execute", "kind": "attack", "target": "foe", "mult": 1.0, "execute": true, "cd": 1},
			{"name": "Sweeping Strikes", "kind": "attack", "target": "foes", "mult": 0.8, "cd": 3},
			{"name": "Battle Shout", "kind": "support", "target": "allies", "buff": [0.15, 4], "cd": 6},
		],
		"Fury": [
			{"name": "Bloodthirst", "kind": "attack", "target": "foe", "mult": 1.6, "cd": 2},
			{"name": "Whirlwind", "kind": "attack", "target": "foes", "mult": 1.0, "cd": 3},
			{"name": "Heroic Strike", "kind": "attack", "target": "foe", "mult": 1.15, "cd": 0},
			{"name": "Execute", "kind": "attack", "target": "foe", "mult": 1.0, "execute": true, "cd": 1},
			{"name": "Death Wish", "kind": "support", "target": "self", "empower": [0.3, 3], "cd": 7},
			{"name": "Battle Shout", "kind": "support", "target": "allies", "buff": [0.15, 4], "cd": 6},
		],
		"Protection": [
			{"name": "Taunt", "kind": "support", "target": "self", "taunt": 3, "cd": 4},
			{"name": "Shield Slam", "kind": "attack", "target": "foe", "mult": 1.3, "cd": 2},
			{"name": "Revenge", "kind": "attack", "target": "foe", "mult": 1.0, "cd": 1},
			{"name": "Shield Block", "kind": "support", "target": "self", "defend": [0.5, 2], "cd": 4},
			{"name": "Thunder Clap", "kind": "attack", "target": "foes", "mult": 0.6, "weaken": [0.85, 3], "cd": 3},
			{"name": "Demoralizing Shout", "kind": "support", "target": "foes", "weaken": [0.8, 4], "cd": 5},
		],
	},
	"paladin": {
		"Holy": [
			{"name": "Holy Light", "kind": "heal", "target": "ally", "mult": 1.8, "cd": 1},
			{"name": "Flash of Light", "kind": "heal", "target": "ally", "mult": 1.1, "cd": 0},
			{"name": "Holy Shock", "kind": "heal", "target": "ally", "mult": 1.4, "cd": 2},
			{"name": "Lay on Hands", "kind": "heal", "target": "ally", "mult": 4.0, "cd": 10},
			{"name": "Blessing of Kings", "kind": "support", "target": "allies", "buff": [0.1, 5], "cd": 7},
			{"name": "Hammer of Justice", "kind": "attack", "target": "foe", "mult": 0.3, "stun": 1, "cd": 5},
		],
		"Protection": [
			{"name": "Righteous Fury", "kind": "support", "target": "self", "taunt": 3, "cd": 4},
			{"name": "Holy Shield", "kind": "support", "target": "self", "defend": [0.6, 3], "cd": 4},
			{"name": "Consecration", "kind": "attack", "target": "foes", "mult": 0.7, "cd": 2},
			{"name": "Seal of Righteousness", "kind": "attack", "target": "foe", "mult": 1.0, "cd": 0},
			{"name": "Hammer of Justice", "kind": "attack", "target": "foe", "mult": 0.3, "stun": 1, "cd": 5},
			{"name": "Blessing of Sanctuary", "kind": "support", "target": "self", "defend": [0.75, 4], "cd": 6},
		],
		"Retribution": [
			{"name": "Seal of Command", "kind": "attack", "target": "foe", "mult": 1.4, "cd": 1},
			{"name": "Judgement", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 1},
			{"name": "Consecration", "kind": "attack", "target": "foes", "mult": 0.7, "cd": 2},
			{"name": "Hammer of Justice", "kind": "attack", "target": "foe", "mult": 0.3, "stun": 1, "cd": 5},
			{"name": "Blessing of Might", "kind": "support", "target": "allies", "buff": [0.15, 4], "cd": 6},
			{"name": "Repentance", "kind": "attack", "target": "foe", "mult": 0.2, "stun": 1, "cd": 6},
		],
	},
	"hunter": {
		"Beast Mastery": [
			{"name": "Bestial Wrath", "kind": "attack", "target": "foe", "mult": 1.9, "cd": 4},
			{"name": "Arcane Shot", "kind": "attack", "target": "foe", "mult": 1.1, "cd": 1},
			{"name": "Multi-Shot", "kind": "attack", "target": "foes", "mult": 0.8, "cd": 2},
			{"name": "Serpent Sting", "kind": "attack", "target": "foe", "mult": 0.2, "dot": [0.35, 5], "cd": 3},
			{"name": "Intimidation", "kind": "attack", "target": "foe", "mult": 0.4, "stun": 1, "cd": 5},
			{"name": "Aspect of the Hawk", "kind": "support", "target": "self", "empower": [0.2, 4], "cd": 6},
		],
		"Marksmanship": [
			{"name": "Aimed Shot", "kind": "attack", "target": "foe", "mult": 1.8, "cd": 3},
			{"name": "Arcane Shot", "kind": "attack", "target": "foe", "mult": 1.1, "cd": 1},
			{"name": "Multi-Shot", "kind": "attack", "target": "foes", "mult": 0.8, "cd": 2},
			{"name": "Serpent Sting", "kind": "attack", "target": "foe", "mult": 0.2, "dot": [0.35, 5], "cd": 3},
			{"name": "Trueshot Aura", "kind": "support", "target": "allies", "buff": [0.1, 5], "cd": 7},
			{"name": "Scatter Shot", "kind": "attack", "target": "foe", "mult": 0.3, "stun": 1, "cd": 5},
		],
		"Survival": [
			{"name": "Mongoose Bite", "kind": "attack", "target": "foe", "mult": 1.4, "cd": 2},
			{"name": "Raptor Strike", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 1},
			{"name": "Wyvern Sting", "kind": "attack", "target": "foe", "mult": 0.2, "stun": 1, "dot": [0.3, 3], "cd": 5},
			{"name": "Explosive Trap", "kind": "attack", "target": "foes", "mult": 0.6, "dot": [0.2, 3], "cd": 4},
			{"name": "Serpent Sting", "kind": "attack", "target": "foe", "mult": 0.2, "dot": [0.35, 5], "cd": 3},
			{"name": "Deterrence", "kind": "support", "target": "self", "defend": [0.5, 2], "cd": 6},
		],
	},
	"rogue": {
		"Assassination": [
			{"name": "Eviscerate", "kind": "attack", "target": "foe", "mult": 1.8, "cd": 2},
			{"name": "Sinister Strike", "kind": "attack", "target": "foe", "mult": 1.0, "cd": 0},
			{"name": "Rupture", "kind": "attack", "target": "foe", "mult": 0.2, "dot": [0.45, 5], "cd": 3},
			{"name": "Cold Blood", "kind": "attack", "target": "foe", "mult": 2.3, "cd": 6},
			{"name": "Kidney Shot", "kind": "attack", "target": "foe", "mult": 0.3, "stun": 1, "cd": 5},
			{"name": "Garrote", "kind": "attack", "target": "foe", "mult": 0.3, "dot": [0.4, 4], "cd": 4},
		],
		"Combat": [
			{"name": "Blade Flurry", "kind": "attack", "target": "foes", "mult": 1.0, "cd": 4},
			{"name": "Sinister Strike", "kind": "attack", "target": "foe", "mult": 1.0, "cd": 0},
			{"name": "Eviscerate", "kind": "attack", "target": "foe", "mult": 1.8, "cd": 2},
			{"name": "Adrenaline Rush", "kind": "support", "target": "self", "empower": [0.4, 3], "cd": 7},
			{"name": "Riposte", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 2},
			{"name": "Kick", "kind": "attack", "target": "foe", "mult": 0.4, "stun": 1, "cd": 5},
		],
		"Subtlety": [
			{"name": "Ambush", "kind": "attack", "target": "foe", "mult": 2.2, "cd": 6},
			{"name": "Hemorrhage", "kind": "attack", "target": "foe", "mult": 1.1, "cd": 0},
			{"name": "Eviscerate", "kind": "attack", "target": "foe", "mult": 1.8, "cd": 2},
			{"name": "Gouge", "kind": "attack", "target": "foe", "mult": 0.3, "stun": 1, "cd": 4},
			{"name": "Evasion", "kind": "support", "target": "self", "defend": [0.4, 2], "cd": 6},
			{"name": "Premeditation", "kind": "support", "target": "self", "empower": [0.25, 3], "cd": 5},
		],
	},
	"priest": {
		"Discipline": [
			{"name": "Power Word: Shield", "kind": "heal", "target": "ally", "shield": 1.6, "cd": 1},
			{"name": "Flash Heal", "kind": "heal", "target": "ally", "mult": 1.2, "cd": 0},
			{"name": "Greater Heal", "kind": "heal", "target": "ally", "mult": 2.1, "cd": 2},
			{"name": "Renew", "kind": "heal", "target": "ally", "hot": [0.4, 4], "cd": 2},
			{"name": "Power Infusion", "kind": "support", "target": "allies", "buff": [0.2, 3], "cd": 7},
			{"name": "Inner Fire", "kind": "support", "target": "self", "defend": [0.8, 5], "cd": 8},
		],
		"Holy": [
			{"name": "Prayer of Healing", "kind": "heal", "target": "allies", "mult": 0.8, "cd": 3},
			{"name": "Greater Heal", "kind": "heal", "target": "ally", "mult": 2.1, "cd": 2},
			{"name": "Flash Heal", "kind": "heal", "target": "ally", "mult": 1.2, "cd": 0},
			{"name": "Renew", "kind": "heal", "target": "ally", "hot": [0.4, 4], "cd": 2},
			{"name": "Holy Fire", "kind": "attack", "target": "foe", "mult": 1.3, "dot": [0.2, 3], "cd": 2},
			{"name": "Holy Nova", "kind": "heal", "target": "allies", "mult": 0.5, "cd": 2},
		],
		"Shadow": [
			{"name": "Mind Blast", "kind": "attack", "target": "foe", "mult": 1.5, "cd": 2},
			{"name": "Shadow Word: Pain", "kind": "attack", "target": "foe", "mult": 0.1, "dot": [0.4, 6], "cd": 4},
			{"name": "Mind Flay", "kind": "attack", "target": "foe", "mult": 1.1, "cd": 0},
			{"name": "Vampiric Embrace", "kind": "attack", "target": "foe", "mult": 0.8, "drain": 0.5, "cd": 3},
			{"name": "Psychic Scream", "kind": "attack", "target": "foes", "mult": 0.1, "stun": 1, "cd": 6},
			{"name": "Shadowform", "kind": "support", "target": "self", "empower": [0.2, 5], "cd": 8},
		],
	},
	"shaman": {
		"Elemental": [
			{"name": "Lightning Bolt", "kind": "attack", "target": "foe", "mult": 1.3, "cd": 0},
			{"name": "Chain Lightning", "kind": "attack", "target": "foes", "mult": 0.9, "cd": 2},
			{"name": "Earth Shock", "kind": "attack", "target": "foe", "mult": 1.1, "cd": 1},
			{"name": "Flame Shock", "kind": "attack", "target": "foe", "mult": 0.5, "dot": [0.3, 4], "cd": 3},
			{"name": "Elemental Mastery", "kind": "attack", "target": "foe", "mult": 2.3, "cd": 6},
			{"name": "Searing Totem", "kind": "attack", "target": "foe", "mult": 0.2, "dot": [0.3, 5], "cd": 5},
		],
		"Enhancement": [
			{"name": "Stormstrike", "kind": "attack", "target": "foe", "mult": 1.6, "cd": 2},
			{"name": "Windfury Totem", "kind": "support", "target": "allies", "buff": [0.15, 4], "cd": 6},
			{"name": "Earth Shock", "kind": "attack", "target": "foe", "mult": 1.1, "cd": 1},
			{"name": "Flame Shock", "kind": "attack", "target": "foe", "mult": 0.5, "dot": [0.3, 4], "cd": 3},
			{"name": "Lightning Shield", "kind": "support", "target": "self", "defend": [0.8, 4], "cd": 5},
			{"name": "Strength of Earth Totem", "kind": "support", "target": "allies", "buff": [0.1, 5], "cd": 7},
		],
		"Restoration": [
			{"name": "Chain Heal", "kind": "heal", "target": "allies", "mult": 0.9, "cd": 2},
			{"name": "Healing Wave", "kind": "heal", "target": "ally", "mult": 2.0, "cd": 1},
			{"name": "Lesser Healing Wave", "kind": "heal", "target": "ally", "mult": 1.2, "cd": 0},
			{"name": "Healing Stream Totem", "kind": "heal", "target": "allies", "hot": [0.15, 5], "cd": 5},
			{"name": "Nature's Swiftness", "kind": "heal", "target": "ally", "mult": 3.0, "cd": 8},
			{"name": "Earth Shock", "kind": "attack", "target": "foe", "mult": 1.0, "cd": 1},
		],
	},
	"mage": {
		"Arcane": [
			{"name": "Arcane Missiles", "kind": "attack", "target": "foe", "mult": 1.4, "cd": 1},
			{"name": "Arcane Explosion", "kind": "attack", "target": "foes", "mult": 0.8, "cd": 1},
			{"name": "Arcane Power", "kind": "support", "target": "self", "empower": [0.3, 3], "cd": 7},
			{"name": "Presence of Mind", "kind": "attack", "target": "foe", "mult": 2.4, "cd": 6},
			{"name": "Polymorph", "kind": "attack", "target": "foe", "mult": 0.0, "stun": 2, "cd": 7},
			{"name": "Frostbolt", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 0},
		],
		"Fire": [
			{"name": "Fireball", "kind": "attack", "target": "foe", "mult": 1.3, "dot": [0.15, 3], "cd": 0},
			{"name": "Pyroblast", "kind": "attack", "target": "foe", "mult": 2.3, "dot": [0.25, 3], "cd": 5},
			{"name": "Fire Blast", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 1},
			{"name": "Flamestrike", "kind": "attack", "target": "foes", "mult": 0.9, "dot": [0.15, 3], "cd": 3},
			{"name": "Combustion", "kind": "support", "target": "self", "empower": [0.35, 3], "cd": 7},
			{"name": "Blast Wave", "kind": "attack", "target": "foes", "mult": 0.8, "stun": 1, "cd": 6},
		],
		"Frost": [
			{"name": "Frostbolt", "kind": "attack", "target": "foe", "mult": 1.3, "cd": 0},
			{"name": "Blizzard", "kind": "attack", "target": "foes", "mult": 0.9, "cd": 3},
			{"name": "Cone of Cold", "kind": "attack", "target": "foes", "mult": 0.7, "cd": 2},
			{"name": "Frost Nova", "kind": "attack", "target": "foes", "mult": 0.2, "stun": 1, "cd": 6},
			{"name": "Ice Block", "kind": "support", "target": "self", "defend": [0.0, 1], "cd": 8},
			{"name": "Ice Barrier", "kind": "support", "target": "self", "shield": 1.2, "cd": 5},
		],
	},
	"warlock": {
		"Affliction": [
			{"name": "Corruption", "kind": "attack", "target": "foe", "mult": 0.0, "dot": [0.5, 5], "cd": 4},
			{"name": "Curse of Agony", "kind": "attack", "target": "foe", "mult": 0.0, "dot": [0.3, 8], "cd": 6},
			{"name": "Drain Life", "kind": "attack", "target": "foe", "mult": 1.0, "drain": 0.6, "cd": 1},
			{"name": "Shadow Bolt", "kind": "attack", "target": "foe", "mult": 1.4, "cd": 0},
			{"name": "Fear", "kind": "attack", "target": "foe", "mult": 0.0, "stun": 1, "cd": 5},
			{"name": "Siphon Life", "kind": "attack", "target": "foe", "mult": 0.0, "dot": [0.3, 5], "drain": 0.3, "cd": 4},
		],
		"Demonology": [
			{"name": "Summon Voidwalker", "kind": "support", "target": "self", "taunt": 3, "cd": 5},
			{"name": "Shadow Bolt", "kind": "attack", "target": "foe", "mult": 1.4, "cd": 0},
			{"name": "Soul Link", "kind": "support", "target": "self", "defend": [0.7, 4], "cd": 6},
			{"name": "Demonic Sacrifice", "kind": "support", "target": "self", "empower": [0.3, 4], "cd": 8},
			{"name": "Corruption", "kind": "attack", "target": "foe", "mult": 0.0, "dot": [0.5, 5], "cd": 4},
			{"name": "Hellfire", "kind": "attack", "target": "foes", "mult": 0.9, "cd": 3},
		],
		"Destruction": [
			{"name": "Shadow Bolt", "kind": "attack", "target": "foe", "mult": 1.5, "cd": 0},
			{"name": "Conflagrate", "kind": "attack", "target": "foe", "mult": 1.8, "cd": 3},
			{"name": "Immolate", "kind": "attack", "target": "foe", "mult": 0.6, "dot": [0.3, 4], "cd": 2},
			{"name": "Rain of Fire", "kind": "attack", "target": "foes", "mult": 1.0, "cd": 3},
			{"name": "Shadowburn", "kind": "attack", "target": "foe", "mult": 2.0, "cd": 4},
			{"name": "Searing Pain", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 1},
		],
	},
	"druid": {
		"Balance": [
			{"name": "Starfire", "kind": "attack", "target": "foe", "mult": 1.6, "cd": 1},
			{"name": "Wrath", "kind": "attack", "target": "foe", "mult": 1.1, "cd": 0},
			{"name": "Moonfire", "kind": "attack", "target": "foe", "mult": 0.5, "dot": [0.3, 4], "cd": 2},
			{"name": "Hurricane", "kind": "attack", "target": "foes", "mult": 1.0, "cd": 3},
			{"name": "Entangling Roots", "kind": "attack", "target": "foe", "mult": 0.1, "stun": 1, "cd": 5},
			{"name": "Moonkin Form", "kind": "support", "target": "self", "empower": [0.2, 5], "cd": 8},
		],
		"Feral Combat": [
			{"name": "Growl", "kind": "support", "target": "self", "taunt": 3, "cd": 4},
			{"name": "Maul", "kind": "attack", "target": "foe", "mult": 1.2, "cd": 0},
			{"name": "Swipe", "kind": "attack", "target": "foes", "mult": 0.7, "cd": 1},
			{"name": "Frenzied Regeneration", "kind": "heal", "target": "self", "mult": 1.5, "cd": 5},
			{"name": "Demoralizing Roar", "kind": "support", "target": "foes", "weaken": [0.8, 4], "cd": 5},
			{"name": "Bash", "kind": "attack", "target": "foe", "mult": 0.4, "stun": 1, "cd": 5},
		],
		"Restoration": [
			{"name": "Healing Touch", "kind": "heal", "target": "ally", "mult": 2.2, "cd": 2},
			{"name": "Rejuvenation", "kind": "heal", "target": "ally", "hot": [0.45, 4], "cd": 1},
			{"name": "Regrowth", "kind": "heal", "target": "ally", "mult": 1.0, "hot": [0.25, 3], "cd": 2},
			{"name": "Tranquility", "kind": "heal", "target": "allies", "mult": 1.4, "cd": 7},
			{"name": "Swiftmend", "kind": "heal", "target": "ally", "mult": 1.6, "cd": 3},
			{"name": "Barkskin", "kind": "support", "target": "self", "defend": [0.7, 3], "cd": 6},
		],
	},
}

## What each class does when nothing better is ready: melee, a hunter's shot, or a caster's wand.
const BASIC_ATTACKS := {
	"hunter": {"name": "Auto Shot", "kind": "attack", "target": "foe", "mult": 0.7, "cd": 0},
	"priest": {"name": "Shoot", "kind": "attack", "target": "foe", "mult": 0.55, "cd": 0},
	"mage": {"name": "Shoot", "kind": "attack", "target": "foe", "mult": 0.55, "cd": 0},
	"warlock": {"name": "Shoot", "kind": "attack", "target": "foe", "mult": 0.55, "cd": 0},
}
const MELEE_ATTACK := {"name": "Attack", "kind": "attack", "target": "foe", "mult": 0.6, "cd": 0}


static func spec_spells(class_id: String, spec: String) -> Array:
	return BOOK[class_id][spec]


## Spell names for a new recruit: the signature spell, then random others from the spec.
static func random_kit(class_id: String, spec: String) -> Array[String]:
	var spells := spec_spells(class_id, spec)
	var others := spells.slice(1)
	others.shuffle()
	var kit: Array[String] = [spells[0].name]
	for spell in others.slice(0, KIT_SIZE - 1):
		kit.append(spell.name)
	return kit


## The fighter's spells as full spell dictionaries.
static func kit_of(fighter: Dictionary) -> Array:
	var kit := []
	for spell in spec_spells(fighter.class_id, fighter.spec):
		if spell.name in fighter.spells:
			kit.append(spell)
	return kit


static func basic_attack(class_id: String) -> Dictionary:
	return BASIC_ATTACKS.get(class_id, MELEE_ATTACK)


## A short line for the character sheet, e.g. "Damage x1.7 to one foe · 2-turn cooldown".
static func describe(spell: Dictionary) -> String:
	var parts := []
	var who := {"foe": "one foe", "foes": "all foes", "ally": "the most hurt ally", "allies": "the whole party", "self": "self"}
	var mult: float = spell.get("mult", 0.0)
	if mult > 0.0:
		parts.append("%s x%s to %s" % ["Damage" if spell.kind == "attack" else "Heals", _num(mult), who[spell.target]])
	if spell.has("dot"):
		parts.append("x%s damage per turn for %d turns" % [_num(spell.dot[0]), spell.dot[1]])
	if spell.has("hot"):
		parts.append("heals x%s per turn for %d turns" % [_num(spell.hot[0]), spell.hot[1]])
	if spell.has("shield"):
		parts.append("absorbs x%s damage" % _num(spell.shield))
	if spell.has("stun"):
		parts.append("stuns for %d turn%s" % [spell.stun, "s" if spell.stun > 1 else ""])
	if spell.has("taunt"):
		parts.append("foes must attack the caster for %d turns" % spell.taunt)
	if spell.has("buff"):
		parts.append("party deals +%d%% damage for %d turns" % [roundi(spell.buff[0] * 100.0), spell.buff[1]])
	if spell.has("empower"):
		parts.append("+%d%% own damage for %d turns" % [roundi(spell.empower[0] * 100.0), spell.empower[1]])
	if spell.has("defend"):
		parts.append("takes %d%% less damage for %d turns" % [roundi((1.0 - spell.defend[0]) * 100.0), spell.defend[1]])
	if spell.has("weaken"):
		parts.append("foes deal %d%% less damage for %d turns" % [roundi((1.0 - spell.weaken[0]) * 100.0), spell.weaken[1]])
	if spell.has("drain"):
		parts.append("heals self for %d%% of the damage" % roundi(spell.drain * 100.0))
	if spell.get("execute", false):
		parts.append("x2.5 on foes under 25% health")
	var cooldown: int = spell.cd
	parts.append("no cooldown" if cooldown == 0 else "%d-turn cooldown" % cooldown)
	return _sentence(parts)


static func _sentence(parts: Array) -> String:
	var text := ", ".join(PackedStringArray(parts))
	return text.substr(0, 1).to_upper() + text.substr(1)


static func _num(value: float) -> String:
	return ("%.2f" % value).rstrip("0").rstrip(".")
