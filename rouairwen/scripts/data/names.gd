class_name Names
## Random Horde character names, by race.

const SYLLABLES := {
	"orc": {"start": ["Gor", "Thra", "Dur", "Mok", "Kar", "Zug", "Grom", "Naz", "Rok", "Drak", "Ur", "Gash", "Krag", "Mog", "Brak", "Tor", "Grim", "Shak", "Varg", "Ogg"],
		"end": ["nak", "gar", "rok", "thar", "mash", "gul", "tusk", "dan", "zul", "grim", "kash", "rag", "mok", "gath", "ruk", "osh"]},
	"troll": {"start": ["Zul", "Jin", "Vol", "Raj", "Zen", "Tal", "Kim", "Mak", "Sen", "Jan", "Ula", "Zal", "Hex", "Vul", "Rok", "Ten"],
		"end": ["'jin", "jin", "'zan", "zek", "rah", "jah", "'tal", "ka", "zul", "wah", "mon", "'ji", "dra", "teki"]},
	"tauren": {"start": ["Tah", "Hamu", "Ohan", "Kodo", "Bai", "Mahk", "Tura", "Ahn", "Haw", "Eya", "Muu", "Kae", "Shon", "Nara"],
		"end": ["ka", "tah", "ne", "wu", "ma", "oth", "an", "ra", "kai", "uun", "o"],
		"surname_a": ["Storm", "Rage", "Thunder", "Blood", "Dust", "Grim", "Mist", "Wild", "Earth", "Sky", "Plains", "River"],
		"surname_b": ["hoof", "totem", "horn", "mane", "runner", "walker", "strider", "hide", "tusk", "wind"]},
	"undead": {"start": ["Mor", "Gre", "Lil", "Ves", "Ash", "Cor", "Mal", "Sev", "Bel", "Dra", "Ner", "Eli", "Quin", "Rav", "Thal", "Sil"],
		"end": ["timer", "gor", "ith", "ane", "ley", "vin", "ric", "ena", "dric", "mund", "aire", "wyn", "eth", "orn", "ia"]},
}

const TAKEN_HINT := ["Nightdude", "Raynkoy"]


static func make(race: String, rng: RandomNumberGenerator) -> String:
	var s: Dictionary = SYLLABLES.get(race, SYLLABLES["orc"])
	var first: String = s["start"][rng.randi() % s["start"].size()] + s["end"][rng.randi() % s["end"].size()]
	return first.capitalize() if not first.contains("'") else first


static func race_for(class_id: String, rng: RandomNumberGenerator) -> String:
	var races: Array = ClassData.CLASSES.get(class_id, {}).get("races", ["orc"])
	return races[rng.randi() % races.size()]
