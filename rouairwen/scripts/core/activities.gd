class_name Activities
## Builds activities: procedurally generated quests, dungeon runs and raid runs.
##
## An activity is a plain Dictionary (saved as JSON):
## {type, title, text, place, level, diff, party_size, fights: [...], rewards, sky, ground}.

const QUEST_KINDS := {
	"easy": {"label": "Easy", "diff": 0.8, "reward": 0.75},
	"normal": {"label": "Normal", "diff": 1.0, "reward": 1.0},
	"hard": {"label": "Hard", "diff": 1.18, "reward": 1.25},
	"elite": {"label": "Elite", "diff": 1.4, "reward": 1.6},
}

## Gear pieces a quest hands out: [min, max, base chance of a rare].
const QUEST_ITEMS := {"easy": [1, 2, 0.05], "normal": [1, 2, 0.08], "hard": [1, 3, 0.2], "elite": [2, 3, 0.45]}

## Every activity guarantees one gear piece for a random role, handed out on completion.
const ROLE_PIECES := {"healing": "healer", "spell": "caster", "physical": "melee", "tank": "tank"}
const ROLE_COLORS := {"healing": "6ee06e", "spell": "69ccf0", "physical": "ffb070", "tank": "8ab0ff"}


static func random_role(rng: RandomNumberGenerator) -> String:
	return Items.PROFILES[rng.randi() % Items.PROFILES.size()]


## "Guaranteed: 1 caster piece" for an activity (empty for activities from older saves).
static func guarantee_bb(act: Dictionary) -> String:
	var role: String = act.get("guaranteed", "")
	if role == "":
		return ""
	return "[color=#c09f86]Guaranteed:[/color] [color=#%s]1 %s piece[/color]" % [ROLE_COLORS[role], ROLE_PIECES[role]]

const TEMPLATES := [
	{"kind": "cull", "titles": ["Culling the {plural}", "Thinning the {plural}", "{plural} on the Road"],
		"text": "{giver} at {hub} wants the {plural} near {sub} culled before they overrun the roads. \"The Horde does not cower, and neither will you.\""},
	{"kind": "collect", "titles": ["{part}s for {giver}", "A Collection of {part}s", "{giver}'s Request"],
		"text": "Collect {count} {part}s from the {plural} of {sub}. {giver} has a use for them, and asks no questions."},
	{"kind": "defend", "titles": ["Hold {sub}", "The Line at {sub}", "Stand Fast"],
		"text": "Waves of {plural} are pressing on {sub}. {giver} needs the Lumens to hold the line until reinforcements arrive."},
	{"kind": "investigate", "titles": ["Trouble at {sub}", "Into {sub}", "Strange Signs"],
		"text": "Scouts report strange activity at {sub}. Find out what the {plural} are up to, and report back to {giver} at {hub}."},
	{"kind": "wanted", "titles": ["Wanted: {named}", "The Head of {named}", "Bounty: {named}"], "named": true,
		"text": "A bounty has been posted at {hub}: {named} has been sighted near {sub}, guarded by {plural}. {giver} wants proof of the deed."},
	{"kind": "slay", "titles": ["{named} Must Die", "End of {named}", "The Fall of {named}"], "named": true,
		"text": "{named} has terrorized {sub} for too long. Cut through the {plural} and put an end to it, for {giver} and the Horde."},
]


## A procedural quest near the player's level. An easy quest is a level below, with weaker enemies
## (difficulty `easy_diff`), so the board always has something safe to take.
static func make_quest(player_level: int, rng: RandomNumberGenerator, easy := false, easy_diff := 0.8) -> Dictionary:
	var target := maxi(1, player_level - 1) if easy else player_level
	var zones := Zones.for_level(target)
	var z: Dictionary = zones[rng.randi() % zones.size()]
	var ql := clampi(target + (0 if easy else rng.randi_range(-1, 1)), z["min"], z["max"])
	ql = clampi(ql, 1, mini(player_level, Balance.MAX_LEVEL) if easy else Balance.MAX_LEVEL)
	var roll := rng.randf()
	var kind := "normal" if roll < 0.55 else ("hard" if roll < 0.87 else "elite")
	if player_level < 3 and kind == "elite":
		kind = "hard"
	if easy:
		kind = "easy"
	var k: Dictionary = QUEST_KINDS[kind].duplicate()
	if easy:
		k["diff"] = easy_diff

	var fams: Array = z["families"]
	var fam: Array = fams[rng.randi() % fams.size()]
	var fam2: Array = fams[rng.randi() % fams.size()]
	var named_list: Array = z["elites"]
	var named: Array = named_list[rng.randi() % named_list.size()]
	var tpl_pool := TEMPLATES.filter(func(t): return t.get("named", false) == (kind == "elite"))
	if kind == "hard" and rng.randf() < 0.4:
		tpl_pool = TEMPLATES.filter(func(t): return t.get("named", false))
	var tpl: Dictionary = tpl_pool[rng.randi() % tpl_pool.size()]
	var is_named: bool = tpl.get("named", false)

	var n_fights := rng.randi_range(1, 3)
	if kind == "easy":
		n_fights = rng.randi_range(1, 2)
	elif kind != "normal":
		n_fights = rng.randi_range(2, 3)
	var fights := []
	for i in n_fights:
		var last := i == n_fights - 1
		if last and is_named:
			var adds := []
			for j in rng.randi_range(0, 2 if ql > 4 else 1):
				adds.append([fam[0], fam[3]])
			fights.append({"type": "elite", "boss": {"name": named[0], "abilities": named[1]}, "mobs": adds,
				"label": named[0]})
			continue
		var count := rng.randi_range(2, 3) if ql >= 4 else rng.randi_range(1, 2)
		var mobs := []
		for j in count:
			var f: Array = fam if (j == 0 or rng.randf() < 0.7) else fam2
			mobs.append([f[0], f[3]])
		fights.append({"type": "pack", "mobs": mobs, "label": fam[1]})

	var sub: Array = z["subzones"]
	var words := {
		"plural": fam[1], "part": fam[2], "named": named[0], "giver": z["givers"][rng.randi() % z["givers"].size()],
		"hub": z["hub"], "sub": sub[rng.randi() % sub.size()], "count": str(rng.randi_range(6, 12)),
	}
	var titles: Array = tpl["titles"]
	var title: String = String(titles[rng.randi() % titles.size()]).format(words, "{_}")
	var text: String = String(tpl["text"]).format(words, "{_}")

	var reward_mult: float = k["reward"]
	var gold := Balance.income(ql) * (1.5 + n_fights) * reward_mult * Balance.LOOT_RATE
	var items: Array = QUEST_ITEMS[kind]
	return {
		"type": "quest", "kind": kind, "title": title, "text": text, "place": z["name"], "zone": z["id"],
		"giver": words["giver"], "level": ql, "diff": k["diff"], "kind_label": k["label"], "party_size": 3,
		"fights": fights, "sky": z["sky"].to_html(false), "ground": z["ground"].to_html(false),
		"guaranteed": random_role(rng),
		"rewards": {
			"xp": int(Balance.xp_per_fight(ql) * (0.8 + 0.25 * n_fights) * reward_mult),
			"gold_min": int(gold * 0.6), "gold_max": int(gold * 1.6),
			"items_min": items[0] * Balance.LOOT_RATE, "items_max": items[1] * Balance.LOOT_RATE,
			"ilvl_min": ql, "ilvl_max": mini(ql + 2, Balance.MAX_LEVEL + 2),
			"rare_chance": items[2] + 0.004 * ql,
			"epic_chance": maxf(0.0, 0.02 + 0.002 * (ql - 30)) if kind == "elite" and ql >= 30 else 0.0,
		},
	}


## Rolls a quest's rewards when it is turned in: gold in its range, and gear pieces whose item level
## and quality follow the quest level. The first piece is the guaranteed role piece; the others lean
## towards what the party wears (`profiles`). `maker` builds an item from (ilvl, quality, profile).
## `boost` (the testing option) multiplies the number of pieces.
static func roll_rewards(rw: Dictionary, guaranteed: String, profiles: Array, rng: RandomNumberGenerator, maker: Callable, boost := 1) -> Dictionary:
	var items := []
	for i in rng.randi_range(rw["items_min"], rw["items_max"]) * boost:
		var q := "uncommon"
		var r := rng.randf()
		if r < rw["epic_chance"]:
			q = "epic"
		elif r < rw["epic_chance"] + rw["rare_chance"]:
			q = "rare"
		var profile: String = profiles[rng.randi() % profiles.size()] if not profiles.is_empty() else ""
		if i == 0 and guaranteed != "":
			profile = guaranteed
		var it: Dictionary = maker.call(rng.randi_range(rw["ilvl_min"], rw["ilvl_max"]), q, profile)
		if i == 0 and guaranteed != "":
			it["guaranteed"] = true
		items.append(it)
	return {"gold": rng.randi_range(rw["gold_min"], rw["gold_max"]), "items": items}


static func make_dungeon(d: Dictionary, player_level: int, rng: RandomNumberGenerator) -> Dictionary:
	var cl := clampi(player_level, d["min"], d["max"])
	var bosses: Array = d["bosses"]
	var finals := bosses.filter(func(b): return b.get("final", false))
	var others := bosses.filter(func(b): return not b.get("final", false))
	var picked := []
	if others.size() <= 3:
		picked = others.duplicate()
	else:
		var idx := range(others.size())
		idx.shuffle()
		idx = idx.slice(0, 3)
		idx.sort()
		for i in idx:
			picked.append(others[i])
	picked.append_array(finals)
	var fights := []
	var trash: Array = d["trash"]
	for i in picked.size():
		if i == 0 or rng.randf() < 0.6:
			var mobs := []
			for j in rng.randi_range(2, 4):
				mobs.append(trash[rng.randi() % trash.size()])
			fights.append({"type": "pack", "mobs": mobs, "label": "%s pack" % mobs[0][0]})
		var b: Dictionary = picked[i]
		var adds := []
		if rng.randf() < 0.25 and not b.get("final", false):
			adds.append(trash[rng.randi() % trash.size()])
		fights.append({"type": "boss", "boss": b, "mobs": adds, "label": b["name"], "final": b.get("final", false)})
	return {
		"type": "dungeon", "id": d["id"], "title": d["name"], "place": d["name"], "guaranteed": random_role(rng),
		"text": "A five-player expedition into %s. Bosses drop named rare loot." % d["name"],
		"level": cl, "diff": d["diff"], "kind_label": "Dungeon", "party_size": 5, "fights": fights,
		"sky": d["sky"].to_html(false), "ground": d["ground"].to_html(false), "rewards": {"xp": 0, "gold": 0, "items": []},
	}


## A raid run covers every boss not yet killed in the current raid lockout.
static func make_raid(r: Dictionary, killed: Array, rng: RandomNumberGenerator) -> Dictionary:
	var fights := []
	var bosses: Array = r["bosses"]
	for i in bosses.size():
		if i in killed:
			continue
		var b: Dictionary = bosses[i]
		fights.append({"type": "raid_boss", "boss": b, "mobs": [], "label": b["name"], "final": b.get("final", false), "boss_index": i})
	return {
		"type": "raid", "id": r["id"], "title": r["name"], "place": r["name"], "guaranteed": random_role(rng),
		"text": "A ten-player raid. Progress is saved after each boss.",
		"level": Balance.MAX_LEVEL, "diff": r["diff"], "kind_label": "Raid", "party_size": 10, "fights": fights,
		"sky": r["sky"].to_html(false), "ground": r["ground"].to_html(false), "rewards": {"xp": 0, "gold": 0, "items": []},
	}
