class_name Talents
## Discipline and Holy talent trees, reworked for the guild game (no Shadow).
## A talent in tier N needs N * 5 points already spent in its tree.

const POINTS_PER_TIER := 5

const TREES := {
	"discipline": {"name": "Discipline", "color": Color("d8c87a"), "talents": [
		{"id": "twin_disciplines", "name": "Twin Disciplines", "tier": 0, "col": 0, "ranks": 5, "icon": "twin",
			"desc": "Increases the healing and absorption of your instant spells by %d%%.", "per": [2, 4, 6, 8, 10]},
		{"id": "improved_shield", "name": "Improved Power Word: Shield", "tier": 0, "col": 2, "ranks": 3, "icon": "shield",
			"desc": "Increases the damage absorbed by Power Word: Shield by %d%%.", "per": [5, 10, 15]},
		{"id": "mental_agility", "name": "Mental Agility", "tier": 1, "col": 0, "ranks": 3, "icon": "agility",
			"desc": "Reduces the mana cost of your instant spells by %d%%.", "per": [4, 7, 10]},
		{"id": "inner_focus", "name": "Inner Focus", "tier": 1, "col": 1, "ranks": 1, "icon": "focus", "spell": true,
			"desc": "Your next spell costs no mana and has +25% critical chance. 45s cooldown."},
		{"id": "meditation", "name": "Meditation", "tier": 1, "col": 2, "ranks": 3, "icon": "meditation",
			"desc": "Allows %d%% of your mana regeneration to continue while casting.", "per": [10, 20, 30]},
		{"id": "penance", "name": "Penance", "tier": 2, "col": 1, "ranks": 1, "icon": "penance", "spell": true,
			"desc": "Channel three bolts of holy light into an ally, each healing for a moderate amount. 10s cooldown."},
		{"id": "mental_strength", "name": "Mental Strength", "tier": 2, "col": 2, "ranks": 5, "icon": "strength",
			"desc": "Increases your maximum mana by %d%%.", "per": [2, 4, 6, 8, 10]},
		{"id": "reflective_shield", "name": "Reflective Shield", "tier": 3, "col": 0, "ranks": 3, "icon": "reflect",
			"desc": "%d%% of the damage absorbed by your shields is reflected to the attacker.", "per": [15, 30, 45]},
		{"id": "borrowed_time", "name": "Borrowed Time", "tier": 3, "col": 2, "ranks": 3, "icon": "time",
			"desc": "After casting Power Word: Shield, your next spell casts %d%% faster.", "per": [10, 20, 30]},
		{"id": "grace", "name": "Grace", "tier": 4, "col": 1, "ranks": 2, "icon": "grace",
			"desc": "Penance and Flash Heal grant Grace: healing you do to the target is increased by %d%%, stacking 3 times.", "per": [3, 6]},
		{"id": "rapture", "name": "Rapture", "tier": 4, "col": 2, "ranks": 3, "icon": "rapture",
			"desc": "When one of your shields is fully absorbed, you regain %s%% of your maximum mana.", "per": [1.5, 3, 4.5]},
		{"id": "power_infusion", "name": "Power Infusion", "tier": 5, "col": 1, "ranks": 1, "icon": "infusion", "spell": true,
			"desc": "Infuses an ally with power: +20% damage for 15s (or +20% casting speed on yourself). 90s cooldown."},
		{"id": "divine_aegis", "name": "Divine Aegis", "tier": 5, "col": 2, "ranks": 3, "icon": "aegis",
			"desc": "When one of your Power Word: Shields is used up, Divine Aegis shields the most injured ally for %d%% of its strength.", "per": [15, 30, 45]},
		{"id": "pain_suppression", "name": "Pain Suppression", "tier": 6, "col": 1, "ranks": 1, "icon": "suppression", "spell": true,
			"desc": "Reduces all damage taken by an ally by 40% for 8s. Off the global cooldown. 60s cooldown."},
	]},
	"holy": {"name": "Holy", "color": Color("ffe9a8"), "talents": [
		{"id": "spiritual_healing", "name": "Spiritual Healing", "tier": 0, "col": 0, "ranks": 5, "icon": "spiritual",
			"desc": "Increases the amount healed by your spells by %d%%.", "per": [2, 4, 6, 8, 10]},
		{"id": "improved_renew", "name": "Improved Renew", "tier": 0, "col": 2, "ranks": 3, "icon": "renew",
			"desc": "Increases the healing of Renew by %d%%.", "per": [5, 10, 15]},
		{"id": "holy_specialization", "name": "Holy Specialization", "tier": 1, "col": 0, "ranks": 5, "icon": "holy_spec",
			"desc": "Increases the critical chance of your holy spells by %d%%.", "per": [1, 2, 3, 4, 5]},
		{"id": "divine_fury", "name": "Divine Fury", "tier": 1, "col": 2, "ranks": 5, "icon": "fury",
			"desc": "Reduces the casting time of Heal and Prayer of Healing by %s sec.", "per": [0.1, 0.2, 0.3, 0.4, 0.5]},
		{"id": "prayer_of_mending", "name": "Prayer of Mending", "tier": 2, "col": 1, "ranks": 1, "icon": "pom", "spell": true,
			"desc": "Places a prayer on an ally that heals them the next time they take damage, then jumps to another ally. 5 jumps, 10s cooldown."},
		{"id": "inspiration", "name": "Inspiration", "tier": 2, "col": 2, "ranks": 3, "icon": "inspiration",
			"desc": "Your critical heals reduce the target's damage taken by %d%% for 15s.", "per": [3, 6, 9]},
		{"id": "improved_healing", "name": "Improved Healing", "tier": 3, "col": 0, "ranks": 3, "icon": "imp_heal",
			"desc": "Reduces the mana cost of Heal and Prayer of Healing by %d%%.", "per": [5, 10, 15]},
		{"id": "surge_of_light", "name": "Surge of Light", "tier": 3, "col": 1, "ranks": 2, "icon": "surge",
			"desc": "Your critical heals have a %d%% chance to make your next Flash Heal instant and free.", "per": [25, 50]},
		{"id": "healing_prayers", "name": "Healing Prayers", "tier": 3, "col": 2, "ranks": 2, "icon": "prayers",
			"desc": "Reduces the mana cost of Prayer of Healing and Prayer of Mending by %d%%.", "per": [10, 20]},
		{"id": "empowered_healing", "name": "Empowered Healing", "tier": 4, "col": 0, "ranks": 5, "icon": "empowered",
			"desc": "Heal gains an additional %d%% of your healing power, and Flash Heal half that.", "per": [8, 16, 24, 32, 40]},
		{"id": "serendipity", "name": "Serendipity", "tier": 4, "col": 2, "ranks": 3, "icon": "serendipity",
			"desc": "Each Flash Heal reduces the cast time of your next Heal or Prayer of Healing by %d%%, stacking 3 times.", "per": [4, 8, 12]},
		{"id": "lightwell", "name": "Lightwell", "tier": 5, "col": 0, "ranks": 1, "icon": "lightwell", "spell": true,
			"desc": "Creates a Lightwell for 20s: every 0.5s it heals the ally with the lowest health, waiting while everyone is at full health. 20 charges, 2 min cooldown."},
		{"id": "spirit_of_redemption", "name": "Spirit of Redemption", "tier": 5, "col": 2, "ranks": 1, "icon": "spirit",
			"desc": "When you die, you become a Spirit of Redemption for 10s: your spells are free, and you can't be harmed."},
		{"id": "circle_of_healing", "name": "Circle of Healing", "tier": 6, "col": 1, "ranks": 1, "icon": "coh", "spell": true,
			"desc": "Instantly heals the 5 most injured party members. 6s cooldown."},
	]},
}


static func find(id: String) -> Dictionary:
	for tree_id in TREES:
		for t in TREES[tree_id]["talents"]:
			if t["id"] == id:
				var out: Dictionary = t.duplicate()
				out["tree"] = tree_id
				return out
	return {}


## Value of a talent's per-rank number at a given rank (0 when not learned).
static func value(talents: Dictionary, id: String) -> float:
	var rank: int = talents.get(id, 0)
	if rank <= 0:
		return 0.0
	var t := find(id)
	if not t.has("per"):
		return 1.0
	return float(t["per"][rank - 1])


static func describe(t: Dictionary, rank: int) -> String:
	if not t.has("per"):
		return t["desc"]
	var r := clampi(rank, 1, t["ranks"])
	var v = t["per"][r - 1]
	if typeof(v) == TYPE_FLOAT and v != floor(v):
		return t["desc"] % str(v)
	if t["desc"].contains("%s"):
		return t["desc"] % str(v)
	return t["desc"] % int(v)


static func spent_in(talents: Dictionary, tree_id: String) -> int:
	var n := 0
	for t in TREES[tree_id]["talents"]:
		n += talents.get(t["id"], 0)
	return n


static func spent(talents: Dictionary) -> int:
	var n := 0
	for k in talents:
		n += talents[k]
	return n


static func can_learn(talents: Dictionary, id: String, level: int) -> bool:
	var t := find(id)
	if t.is_empty():
		return false
	if talents.get(id, 0) >= t["ranks"]:
		return false
	if spent(talents) >= Balance.talent_points_at(level):
		return false
	return spent_in(talents, t["tree"]) >= t["tier"] * POINTS_PER_TIER
