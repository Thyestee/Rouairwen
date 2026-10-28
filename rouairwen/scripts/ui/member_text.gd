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
	return "\n".join(lines)


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
	return "\n".join(lines) if not lines.is_empty() else "[color=#8a7262]None yet.[/color]"
