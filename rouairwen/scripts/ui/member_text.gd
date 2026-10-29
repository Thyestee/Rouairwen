class_name MemberText
## Shared BBCode for a guildmate's traits, affixes, utilities and talent effects.

const GOOD := "6ee06e"
const BAD := "ff6a5a"
const TRAIT := "ffd86b"


## "Ferocious (+3% critical strike chance)", one per line: traits in gold, affixes green or red.
static func traits_bb(m: Dictionary) -> String:
	var lines := []
	for tr in m.get("traits", []):
		lines.append("[color=#%s]%s[/color] [color=#c09f86](%s)[/color]" % [TRAIT, tr[0], SpecTalents.effects_text(tr[1])])
	for af in m.get("affixes", []):
		var good := SpecTalents.power_value(af[1]) >= 0.0
		lines.append("[color=#%s]%s[/color] [color=#c09f86](%s)[/color]" % [GOOD if good else BAD, af[0], SpecTalents.effects_text(af[1])])
	if m.has("grade_perk"):
		lines.append("[color=#%s]%s[/color] [color=#c09f86](grade B perk: %s)[/color]" % [Tiers.color_of(Tiers.B).to_html(false),
			m["grade_perk"][0], SpecTalents.effects_text(m["grade_perk"][1])])
	return "\n".join(lines)


## What a guildmate's grade gives them: its stats at the guild's level, then its unlocks.
static func grade_bb(m: Dictionary) -> String:
	var t: int = m["tier"]
	var lines := ["[color=#c09f86]Stats at level %d:[/color] %s" % [Game.level(),
		Tiers.stats_text(Game.grade_stats(m)) if t > 0 else "none yet (F)"]]
	for g in [Tiers.B, Tiers.A, Tiers.S]:
		var col := Tiers.color_of(g).to_html(false)
		var what := unlock_text(m, g)
		if t >= g:
			lines.append("[color=#%s]%s[/color]  %s" % [col, Tiers.name_of(g), what])
		else:
			lines.append("[color=#8a7262]%s  %s (not yet)[/color]" % [Tiers.name_of(g), what])
	return "\n".join(lines)


## "Slice and Dice (class)": what grade g unlocks for this guildmate.
static func unlock_text(m: Dictionary, g: int) -> String:
	match Tiers.unlock_at(g):
		"perk":
			return m["grade_perk"][0] + " (" + SpecTalents.effects_text(m["grade_perk"][1]) + ")" if m.has("grade_perk") \
				else "a random perk: critical strike or damage"
		"class":
			return "%s (class)" % SpecTalents.ABILITIES[SpecTalents.CLASS_SPELLS[m["class"]]]["name"]
		"race":
			return "%s (racial)" % SpecTalents.ABILITIES[SpecTalents.RACE_SPELLS[m["race"]]]["name"]
	return ""


static func utils_bb(spec_id: String) -> String:
	var ut := []
	for u in ClassData.SPECS[spec_id]["util"]:
		ut.append("[color=#ffd86b]%s[/color] — %s" % [ClassData.UTILS[u]["name"], ClassData.UTILS[u]["desc"]])
	return "\n".join(ut)


## Every effect a guildmate has from talents, traits and affixes, summed.
static func mods_bb(mods: Dictionary) -> String:
	var lines := []
	for k in SpecTalents.EFFECTS:
		if mods.has(k) and absf(mods[k]) > 0.001:
			var col := GOOD if mods[k] > 0.0 else BAD
			lines.append("[color=#%s]%s[/color]" % [col, SpecTalents.effect_text(k, mods[k])])
	# Ability improvements ("+24% Rend damage")
	for k in mods:
		if String(k).contains(".") and absf(mods[k]) > 0.001:
			lines.append("[color=#%s]%s[/color]" % [GOOD, SpecTalents.effect_text(k, mods[k])])
	return "\n".join(lines) if not lines.is_empty() else "[color=#8a7262]None yet.[/color]"
