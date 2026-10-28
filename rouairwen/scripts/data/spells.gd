class_name Spells
## The priest's spellbook. Amounts are in level units (multiplied by Balance.scale(level)).
##
## target: "ally" (a party frame), "enemy", "self" or "none".
##
## Like in WoW, every heal adds a share of Thyeste's healing power (Healing and Spell Damage from gear),
## and Smite a share of her Spell Damage: the spell's coefficient ("coef", for one "amount": per tick
## total for Renew, per bolt, per target, per charge). Direct spells get their cast time / 3.5 sec
## (instants count as 1.5 sec), heals over time their duration / 15 sec split between the ticks,
## channels their channel time / 3.5 split between the bolts, and party-wide heals half of that.
## Power Word: Shield gets 30%, as in The Burning Crusade.

const BOOK := {
	"heal": {"name": "Lesser Heal", "level": 1, "cast": 2.5, "mana": 18, "amount": 56, "coef": 2.5 / 3.5, "target": "ally", "icon": "heal",
		"desc": "A slow, efficient heal on one target."},
	"smite": {"name": "Smite", "level": 1, "cast": 2.0, "mana": 9, "amount": 28, "coef": 2.0 / 3.5, "power": "spell", "target": "enemy", "icon": "smite",
		"desc": "Holy damage to an enemy."},
	"shield": {"name": "Power Word: Shield", "level": 6, "cast": 0.0, "mana": 19, "amount": 61, "coef": 0.3, "target": "ally", "icon": "shield",
		"cooldown": 4.0, "desc": "Absorbs damage for 30s. The target is Weakened Soul and can't be shielded again for 15s."},
	"renew": {"name": "Renew", "level": 8, "cast": 0.0, "mana": 15, "amount": 52, "coef": 15.0 / 15.0, "target": "ally", "icon": "renew",
		"duration": 15.0, "ticks": 5, "desc": "Heals the target over 15s."},
	"dispel": {"name": "Dispel Magic", "level": 10, "cast": 0.0, "mana": 10, "amount": 0, "target": "ally", "icon": "dispel",
		"desc": "Removes one Magic or Disease effect from the target."},
	"flash_heal": {"name": "Flash Heal", "level": 20, "cast": 1.5, "mana": 25, "amount": 48, "coef": 1.5 / 3.5, "target": "ally", "icon": "flash",
		"desc": "A fast but costly heal."},
	"prayer_of_healing": {"name": "Prayer of Healing", "level": 30, "cast": 3.0, "mana": 50, "amount": 37, "coef": 3.0 / 3.5 / 2.0, "target": "none", "icon": "poh",
		"max_targets": 5, "desc": "Heals the 5 most injured members of your party."},
	# Talent spells
	"penance": {"name": "Penance", "level": 1, "cast": 2.0, "mana": 20, "amount": 32, "coef": 2.0 / 3.5 / 3.0, "target": "ally", "icon": "penance",
		"cooldown": 10.0, "channel": 3, "talent": true, "desc": "Channels three bolts of holy light, each healing the target."},
	"prayer_of_mending": {"name": "Prayer of Mending", "level": 1, "cast": 0.0, "mana": 22, "amount": 23, "coef": 1.5 / 3.5, "target": "ally", "icon": "pom",
		"cooldown": 10.0, "charges": 5, "talent": true,
		"desc": "Heals the target the next time they take damage, then jumps to another party member. 5 jumps."},
	"inner_focus": {"name": "Inner Focus", "level": 1, "cast": 0.0, "mana": 0, "amount": 0, "target": "self", "icon": "focus",
		"cooldown": 45.0, "off_gcd": true, "talent": true, "desc": "Your next spell costs no mana and has +25% critical chance."},
	"power_infusion": {"name": "Power Infusion", "level": 1, "cast": 0.0, "mana": 16, "amount": 0, "target": "ally", "icon": "infusion",
		"cooldown": 90.0, "talent": true, "desc": "The target deals 20% more damage for 15s. On yourself: casts 20% faster."},
	"pain_suppression": {"name": "Pain Suppression", "level": 1, "cast": 0.0, "mana": 8, "amount": 0, "target": "ally", "icon": "suppression",
		"cooldown": 60.0, "off_gcd": true, "talent": true, "desc": "The target takes 40% less damage for 8s."},
	"lightwell": {"name": "Lightwell", "level": 1, "cast": 0.5, "mana": 30, "amount": 51, "coef": 6.0 / 15.0, "target": "none", "icon": "lightwell",
		"cooldown": 120.0, "charges": 8, "talent": true,
		"desc": "Creates a Lightwell for 60s. Members below 50% health draw from it, healing over 6s. 8 charges."},
	"circle_of_healing": {"name": "Circle of Healing", "level": 1, "cast": 0.0, "mana": 28, "amount": 33, "coef": 1.5 / 3.5 / 2.0, "target": "ally", "icon": "coh",
		"cooldown": 6.0, "max_targets": 5, "talent": true, "desc": "Instantly heals the 5 most injured members of your party."},
}

const ORDER := ["heal", "flash_heal", "renew", "shield", "penance", "prayer_of_mending", "circle_of_healing",
	"prayer_of_healing", "dispel", "smite", "power_infusion", "pain_suppression", "inner_focus", "lightwell"]

static func display_name(id: String, level: int) -> String:
	if id == "heal":
		if level >= 40:
			return "Greater Heal"
		if level >= 16:
			return "Heal"
	return BOOK[id]["name"]


## Spells known at a level with a set of talents (Dictionary id -> rank).
static func known(level: int, talents: Dictionary) -> Array:
	var out := []
	for id in ORDER:
		var s: Dictionary = BOOK[id]
		if s.get("talent", false):
			if talents.get(id, 0) > 0:
				out.append(id)
		elif level >= s["level"]:
			out.append(id)
	return out
