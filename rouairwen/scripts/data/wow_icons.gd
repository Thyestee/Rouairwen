class_name WowIcons
## World of Warcraft icon names for spells, talents, buffs and consumables.
##
## The icons are Blizzard's art, so they are neither in the repository nor in exported builds:
## tools/fetch_icons.gd downloads them into assets/icons/ (git-ignored) for development, and shared
## builds download them on first launch into the player's user://icons (see IconDownloader).
## Anything missing falls back to the drawn SpellIcon glyphs.

const DIR := "res://assets/icons"
const USER_DIR := "user://icons"
const URL := "https://wow.zamimg.com/images/wow/icons/large/%s.jpg"

const SPELLS := {
	"smite": "spell_holy_holysmite", "shield": "spell_holy_powerwordshield", "renew": "spell_holy_renew",
	"dispel": "spell_holy_dispelmagic", "flash_heal": "spell_holy_flashheal", "prayer_of_healing": "spell_holy_prayerofhealing02",
	"penance": "spell_holy_penance", "prayer_of_mending": "spell_holy_prayerofmendingtga", "inner_focus": "spell_frost_windwalkon",
	"power_infusion": "spell_holy_powerinfusion", "pain_suppression": "spell_holy_painsupression",
	"lightwell": "spell_holy_summonlightwell", "circle_of_healing": "spell_holy_circleofrenewal",
}
## Lesser Heal, Heal and Greater Heal each have their own icon.
const HEAL_RANKS := [[1, "spell_holy_lesserheal"], [16, "spell_holy_heal"], [40, "spell_holy_greaterheal"]]

const TALENTS := {
	"twin_disciplines": "spell_holy_sealofvengeance", "improved_shield": "spell_holy_powerwordshield",
	"mental_agility": "ability_hibernation", "inner_focus": "spell_frost_windwalkon", "meditation": "spell_nature_sleep",
	"penance": "spell_holy_penance", "mental_strength": "spell_nature_enchantarmor", "reflective_shield": "spell_holy_powerwordshield",
	"borrowed_time": "spell_holy_borrowedtime", "grace": "spell_holy_hopeandgrace", "rapture": "spell_holy_rapture",
	"power_infusion": "spell_holy_powerinfusion", "divine_aegis": "spell_holy_devineaegis", "pain_suppression": "spell_holy_painsupression",
	"spiritual_healing": "spell_nature_moonglow", "improved_renew": "spell_holy_renew", "holy_specialization": "spell_holy_sealofsalvation",
	"divine_fury": "spell_holy_sealofwrath", "prayer_of_mending": "spell_holy_prayerofmendingtga", "inspiration": "inv_shield_06",
	"improved_healing": "spell_holy_heal02", "surge_of_light": "spell_holy_surgeoflight", "healing_prayers": "spell_holy_prayerofhealing02",
	"empowered_healing": "spell_holy_greaterheal", "serendipity": "spell_holy_serendipity", "lightwell": "spell_holy_summonlightwell",
	"spirit_of_redemption": "inv_enchant_essenceeternallarge", "circle_of_healing": "spell_holy_circleofrenewal",
}

## Buffs drawn on party frames, by aura id.
const AURAS := {
	"renew": "spell_holy_renew", "pws": "spell_holy_powerwordshield", "pom": "spell_holy_prayerofmendingtga",
	"grace": "spell_holy_hopeandgrace", "inspiration": "inv_shield_06", "aegis": "spell_holy_devineaegis",
	"power_infusion": "spell_holy_powerinfusion", "pain_suppression": "spell_holy_painsupression",
	"lightwell_renew": "spell_holy_summonlightwell", "shield_wall": "ability_warrior_shieldwall",
	"evasion": "spell_shadow_shadowward", "barkskin": "spell_nature_stoneclawtotem", "ice_block": "spell_frost_frost",
}

## Debuffs: known spell names first (matched as substrings; checked against Wowhead's Classic spell data), then the kind.
const DEBUFF_NAMES := [
	["Shadow Word: Pain", "spell_shadow_shadowwordpain"], ["Corruption", "spell_shadow_abominationexplosion"],
	["Immolate", "spell_fire_immolation"], ["Curse of Agony", "spell_shadow_curseofsargeras"],
	["Curse of Weakness", "spell_shadow_curseofmannoroth"], ["Curse of Tongues", "spell_shadow_curseoftounges"],
	["Curse of Doom", "spell_shadow_auraofdarkness"], ["Rend", "ability_gouge"], ["Mortal", "ability_warrior_savageblow"],
	["Sleep", "spell_nature_sleep"], ["Polymorph", "spell_nature_polymorph"], ["Psychic Scream", "spell_shadow_psychicscream"],
	["Living Bomb", "inv_enchant_essenceastralsmall"], ["Weakened Soul", "spell_holy_ashestoashes"],
]
const DEBUFF_KINDS := {
	"bleed": "ability_gouge", "poison": "spell_nature_corrosivebreath", "disease": "spell_shadow_plaguecloud",
	"curse": "spell_shadow_curseofsargeras", "magic_dot": "spell_shadow_shadowwordpain", "fear": "spell_shadow_possession",
	"hex": "spell_nature_polymorph", "mortal": "ability_warrior_savageblow", "bomb": "spell_fire_selfdestruct",
}

## Consumables, by rank name (see ShopData). Checked against Wowhead's Classic item data.
const CONSUMABLES := {
	"Minor Mana Potion": "inv_potion_70", "Lesser Mana Potion": "inv_potion_71", "Mana Potion": "inv_potion_72",
	"Greater Mana Potion": "inv_potion_73", "Superior Mana Potion": "inv_potion_74", "Major Mana Potion": "inv_potion_76",
	"Minor Healing Potion": "inv_potion_49", "Lesser Healing Potion": "inv_potion_50", "Healing Potion": "inv_potion_51",
	"Greater Healing Potion": "inv_potion_52", "Superior Healing Potion": "inv_potion_53", "Major Healing Potion": "inv_potion_54",
	"Elixir of Lion's Strength": "inv_potion_56", "Elixir of Lesser Agility": "inv_potion_92", "Elixir of Agility": "inv_potion_93",
	"Elixir of Greater Agility": "inv_potion_94", "Elixir of the Mongoose": "inv_potion_32", "Juju Power": "inv_misc_monsterscales_11",
	"Elixir of Minor Fortitude": "inv_potion_42", "Elixir of Fortitude": "inv_potion_43", "Elixir of Superior Defense": "inv_potion_66",
	"Spirit of Zanza": "inv_potion_30", "Flask of the Titans": "inv_potion_62",
	"Elixir of Wisdom": "inv_potion_06", "Elixir of Greater Intellect": "inv_potion_10", "Mageblood Potion": "inv_potion_45",
	"Flask of Distilled Wisdom": "inv_potion_97",
	"Herb Baked Egg": "inv_egg_03", "Crispy Bat Wing": "inv_misc_food_46", "Goldthorn Tea": "inv_drink_15",
	"Nightfin Soup": "inv_drink_17", "Runn Tum Tuber Surprise": "inv_misc_food_63",
}

static var _cache := {}


static func spell(id: String, level: int) -> String:
	if id == "heal":
		var out := ""
		for r in HEAL_RANKS:
			if level >= r[0]:
				out = r[1]
		return out
	return SPELLS.get(id, "")


static func talent(id: String) -> String:
	return TALENTS.get(id, "")


## A guildmate talent's icon (see TalentIcons).
static func guild_talent(class_id: String, id: String) -> String:
	return TalentIcons.TALENTS.get(class_id + "/" + id, "")


static func guild_ability(id: String) -> String:
	return TalentIcons.ABILITIES.get(id, "")


static func aura(id: String) -> String:
	return AURAS.get(id, "")


static func consumable(rank_name: String) -> String:
	return CONSUMABLES.get(rank_name, "")


## The icon for an aura: a buff by id, a guildmate ability's by its icon id, a debuff by name, then by kind.
static func for_aura(au: Dictionary) -> String:
	if AURAS.has(au["id"]):
		return AURAS[au["id"]]
	if TalentIcons.ABILITIES.has(au.get("icon", "")):
		return TalentIcons.ABILITIES[au["icon"]]
	var nm: String = au.get("name", "")
	for pair in DEBUFF_NAMES:
		if nm.contains(pair[0]):
			return pair[1]
	return DEBUFF_KINDS.get(au.get("kind", ""), "")


static func path(icon_name: String) -> String:
	return DIR.path_join(icon_name + ".jpg")


## The icon's texture, or null when it hasn't been downloaded.
static func texture(icon_name: String) -> Texture2D:
	if icon_name == "":
		return null
	if _cache.has(icon_name):
		return _cache[icon_name]
	var tex: Texture2D = null
	var p := path(icon_name)
	if ResourceLoader.exists(p):
		tex = load(p)
	else:
		for file in [p, user_path(icon_name)]:
			if FileAccess.file_exists(file):
				var img := Image.load_from_file(ProjectSettings.globalize_path(file))
				if img != null and not img.is_empty():
					tex = ImageTexture.create_from_image(img)
					break
	_cache[icon_name] = tex
	return tex


static func user_path(icon_name: String) -> String:
	return USER_DIR.path_join(icon_name + ".jpg")


## Icons neither in the project nor already downloaded to user://icons.
static func missing_names() -> Array:
	return all_names().filter(func(n): return not ResourceLoader.exists(path(n)) and not FileAccess.file_exists(path(n)) \
		and not FileAccess.file_exists(user_path(n)))


static func clear_cache() -> void:
	_cache.clear()


## Every icon the game can show, for the download tool.
static func all_names() -> Array:
	var out := []
	for d in [SPELLS, TALENTS, AURAS, CONSUMABLES, DEBUFF_KINDS, TalentIcons.ABILITIES, TalentIcons.TALENTS]:
		for k in d:
			if not (d[k] in out):
				out.append(d[k])
	for r in HEAL_RANKS + DEBUFF_NAMES:
		if not (r[1] in out):
			out.append(r[1])
	return out
