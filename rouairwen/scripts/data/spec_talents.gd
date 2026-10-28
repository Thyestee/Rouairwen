class_name SpecTalents
## Talent trees for every guildmate spec, plus recruit traits and affixes.
##
## Every talent, trait and affix is a set of effects ({key: value per rank}) that the combat engine
## understands, so nothing is decorative. Personal effects add up; party and enemy effects (auras,
## debuffs on the enemy) don't stack between guildmates: the strongest one in the party counts.

## Guildmates get one point per level from 10, up to 36; each tree holds about 40 ranks.
const START_LEVEL := 10
const MAX_POINTS := 36
const POINTS_PER_TIER := 5

## [label, description with %s for the value]
const EFFECTS := {
	"dps": ["Damage", "+%s%% damage"],
	"crit": ["Critical strike", "+%s%% critical strike chance"],
	"crit_dmg": ["Critical damage", "+%s%% critical strike damage"],
	"haste": ["Attack speed", "+%s%% attack speed"],
	"hp": ["Health", "+%s%% health"],
	"mit": ["Damage reduction", "-%s%% damage taken"],
	"dodge": ["Dodge", "+%s%% chance to dodge melee attacks"],
	"aggro": ["Threat", "+%s%% hold on enemies' attention"],
	"threat": ["Subtlety", "-%s%% chance to draw enemies' attention"],
	"boss": ["Boss slayer", "+%s%% damage against bosses"],
	"aoe": ["Area damage", "+%s%% damage while 3 or more enemies stand"],
	"execute": ["Execute", "+%s%% damage against enemies below 25%% health"],
	"leech": ["Leech", "Heals for %s%% of the damage dealt"],
	"extra_attack": ["Extra attacks", "%s%% chance on hit to strike again"],
	"opener": ["Opening burst", "+%s%% damage during the first 12 sec of a fight"],
	"interrupt": ["Interrupt", "%s%% chance to interrupt an enemy cast (8 sec cooldown)"],
	"cheat_death": ["Cheat Death", "%s%% chance to survive a killing blow at 10%% health, once per fight"],
	"last_stand": ["Last Stand", "Once per fight below 20%% health: heals %s%% of maximum health"],
	"ice_block": ["Ice Block", "Once per fight below 15%% health: immune to damage for %s sec"],
	"party_dps": ["Party damage", "Party: +%s%% damage"],
	"party_crit": ["Party critical", "Party: +%s%% critical strike chance"],
	"party_hp": ["Party health", "Party: +%s%% health"],
	"party_mit": ["Party protection", "Party: -%s%% damage taken"],
	"priest_regen": ["Mana for Thyeste", "Thyeste's mana regeneration +%s%%"],
	"priest_mana": ["Mana pool for Thyeste", "Thyeste's maximum mana +%s%%"],
	"enemy_dmg": ["Weaken enemies", "Enemies deal %s%% less damage"],
	"enemy_vuln": ["Expose enemies", "Enemies take %s%% more damage"],
	"anti_heal": ["Wound", "Enemy heals are reduced by %s%%"],
	"windfury_bonus": ["Windfury", "+%s%% Windfury Totem proc chance"],
	"healthstone_bonus": ["Healthstones", "Healthstones heal %s%% more"],
}
const GROUP_KEYS := ["party_dps", "party_crit", "party_hp", "party_mit", "priest_regen", "priest_mana",
	"enemy_dmg", "enemy_vuln", "anti_heal", "windfury_bonus", "healthstone_bonus"]

## How much one point of an effect is worth when estimating a guildmate's power (in % of power).
const WEIGHTS := {
	"dps": 1.0, "crit": 0.9, "crit_dmg": 0.11, "haste": 0.9, "hp": 0.4, "mit": 0.6, "dodge": 0.4, "aggro": 0.4,
	"threat": 0.05, "boss": 0.5, "aoe": 0.3, "execute": 0.2, "leech": 0.3, "extra_attack": 0.9, "opener": 0.2,
	"interrupt": 0.1, "cheat_death": 0.03, "last_stand": 0.12, "ice_block": 0.6, "party_dps": 2.5, "party_crit": 2.2,
	"party_hp": 1.0, "party_mit": 2.0, "priest_regen": 0.4, "priest_mana": 0.4, "enemy_dmg": 2.0, "enemy_vuln": 2.5,
	"anti_heal": 0.08, "windfury_bonus": 1.0, "healthstone_bonus": 0.05,
}

## [id, name, tier, column, ranks, {effect: value per rank}]
const TREES := {
	"warrior_arms": [
		["imp_heroic_strike", "Improved Heroic Strike", 0, 0, 3, {"dps": 1.5}],
		["deflection", "Deflection", 0, 1, 5, {"dodge": 1}],
		["tactical_mastery", "Tactical Mastery", 0, 2, 5, {"opener": 3}],
		["imp_rend", "Improved Rend", 1, 0, 3, {"boss": 2}],
		["anger_management", "Anger Management", 1, 2, 1, {"haste": 4}],
		["deep_wounds", "Deep Wounds", 2, 0, 3, {"crit_dmg": 8}],
		["two_handed_spec", "Two-Handed Weapon Specialization", 2, 1, 5, {"dps": 1}],
		["impale", "Impale", 3, 1, 2, {"crit_dmg": 10}],
		["axe_spec", "Axe Specialization", 4, 0, 5, {"crit": 1}],
		["sweeping_strikes", "Sweeping Strikes", 4, 2, 3, {"aoe": 6}],
		["imp_overpower", "Improved Overpower", 5, 0, 2, {"crit": 1.5}],
		["imp_slam", "Improved Slam", 5, 2, 3, {"haste": 1.5}],
		["mortal_strike", "Mortal Strike", 6, 1, 1, {"boss": 6, "anti_heal": 50}],
	],
	"warrior_fury": [
		["imp_demo_shout", "Improved Demoralizing Shout", 0, 0, 5, {"enemy_dmg": 0.8}],
		["cruelty", "Cruelty", 0, 1, 5, {"crit": 1}],
		["unbridled_wrath", "Unbridled Wrath", 1, 1, 5, {"extra_attack": 1}],
		["imp_cleave", "Improved Cleave", 1, 2, 3, {"aoe": 5}],
		["dual_wield_spec", "Dual Wield Specialization", 2, 0, 5, {"dps": 1}],
		["imp_execute", "Improved Execute", 2, 1, 2, {"execute": 10}],
		["enrage", "Enrage", 2, 2, 5, {"dps": 1}],
		["death_wish", "Death Wish", 3, 1, 1, {"opener": 20}],
		["imp_berserker_rage", "Improved Berserker Rage", 4, 0, 2, {"mit": 2}],
		["flurry", "Flurry", 4, 1, 5, {"haste": 2}],
		["imp_pummel", "Improved Pummel", 4, 2, 2, {"interrupt": 15}],
		["bloodthirst", "Bloodthirst", 6, 1, 1, {"dps": 5, "leech": 4}],
	],
	"warrior_protection": [
		["imp_bloodrage", "Improved Bloodrage", 0, 0, 2, {"aggro": 1.5}],
		["shield_spec", "Shield Specialization", 0, 1, 5, {"dodge": 1}],
		["anticipation", "Anticipation", 0, 2, 5, {"mit": 1}],
		["iron_will", "Iron Will", 1, 0, 3, {"mit": 1}],
		["toughness", "Toughness", 1, 2, 5, {"hp": 2}],
		["last_stand", "Last Stand", 2, 0, 1, {"last_stand": 30}],
		["imp_shield_block", "Improved Shield Block", 2, 1, 3, {"dodge": 1}],
		["imp_taunt", "Improved Taunt", 2, 2, 2, {"aggro": 2}],
		["defiance", "Defiance", 3, 1, 5, {"aggro": 1}],
		["imp_sunder", "Improved Sunder Armor", 3, 2, 3, {"enemy_vuln": 1}],
		["imp_shield_wall", "Improved Shield Wall", 4, 0, 2, {"mit": 1.5}],
		["one_handed_spec", "One-Handed Weapon Specialization", 4, 2, 5, {"dps": 4}],
		["concussion_blow", "Concussion Blow", 5, 1, 1, {"interrupt": 25}],
		["shield_slam", "Shield Slam", 6, 1, 1, {"dps": 10, "aggro": 3}],
	],
	"shaman_elemental": [
		["convection", "Convection", 0, 0, 5, {"dps": 0.6}],
		["concussion", "Concussion", 0, 2, 5, {"dps": 1}],
		["elemental_warding", "Elemental Warding", 1, 0, 3, {"mit": 1}],
		["call_of_flame", "Call of Flame", 1, 2, 3, {"aoe": 5}],
		["elemental_focus", "Elemental Focus", 2, 0, 1, {"haste": 5}],
		["reverberation", "Reverberation", 2, 2, 5, {"interrupt": 4}],
		["call_of_thunder", "Call of Thunder", 3, 1, 5, {"crit": 1}],
		["imp_fire_totems", "Improved Fire Totems", 3, 0, 2, {"aoe": 5}],
		["eye_of_the_storm", "Eye of the Storm", 4, 0, 3, {"mit": 1}],
		["elemental_devastation", "Elemental Devastation", 4, 2, 3, {"crit": 1}],
		["elemental_fury", "Elemental Fury", 5, 1, 1, {"crit_dmg": 25}],
		["lightning_mastery", "Lightning Mastery", 5, 2, 5, {"haste": 1.5}],
		["elemental_mastery", "Elemental Mastery", 6, 1, 1, {"opener": 20, "priest_regen": 10}],
	],
	"shaman_enhancement": [
		["guardian_totems", "Guardian Totems", 0, 0, 2, {"party_mit": 1}],
		["thundering_strikes", "Thundering Strikes", 0, 1, 5, {"crit": 1}],
		["enhancing_totems", "Enhancing Totems", 1, 0, 2, {"party_dps": 1}],
		["imp_lightning_shield", "Improved Lightning Shield", 1, 2, 3, {"dps": 1}],
		["two_handed_maces", "Two-Handed Axes and Maces", 2, 0, 1, {"dps": 3}],
		["anticipation", "Anticipation", 2, 2, 5, {"dodge": 1}],
		["flurry", "Flurry", 3, 1, 5, {"haste": 2}],
		["toughness", "Toughness", 3, 2, 5, {"hp": 2}],
		["imp_weapon_totems", "Improved Weapon Totems", 4, 0, 2, {"windfury_bonus": 1.5}],
		["elemental_weapons", "Elemental Weapons", 4, 2, 3, {"dps": 1.5}],
		["parry", "Parry", 5, 0, 1, {"dodge": 4}],
		["weapon_mastery", "Weapon Mastery", 5, 2, 5, {"dps": 1}],
		["stormstrike", "Stormstrike", 6, 1, 1, {"enemy_vuln": 4}],
	],
	"rogue_assassination": [
		["imp_eviscerate", "Improved Eviscerate", 0, 0, 3, {"dps": 1.5}],
		["malice", "Malice", 0, 1, 5, {"crit": 1}],
		["remorseless_attacks", "Remorseless Attacks", 0, 2, 2, {"aoe": 5}],
		["ruthlessness", "Ruthlessness", 1, 0, 3, {"dps": 1}],
		["murder", "Murder", 1, 1, 2, {"dps": 2}],
		["imp_slice_and_dice", "Improved Slice and Dice", 1, 2, 3, {"haste": 2}],
		["relentless_strikes", "Relentless Strikes", 2, 0, 1, {"haste": 3}],
		["lethality", "Lethality", 2, 1, 5, {"crit_dmg": 6}],
		["imp_poisons", "Improved Poisons", 3, 1, 5, {"boss": 1.5}],
		["vile_poisons", "Vile Poisons", 4, 0, 5, {"dps": 1}],
		["cold_blood", "Cold Blood", 4, 2, 1, {"opener": 15}],
		["seal_fate", "Seal Fate", 5, 1, 5, {"crit": 1}],
		["vigor", "Vigor", 6, 1, 1, {"haste": 4, "enemy_vuln": 2}],
	],
	"rogue_combat": [
		["imp_gouge", "Improved Gouge", 0, 0, 3, {"interrupt": 5}],
		["imp_sinister_strike", "Improved Sinister Strike", 0, 1, 2, {"dps": 2}],
		["lightning_reflexes", "Lightning Reflexes", 0, 2, 5, {"dodge": 1}],
		["imp_backstab", "Improved Backstab", 1, 0, 3, {"crit": 1}],
		["deflection", "Deflection", 1, 1, 5, {"dodge": 1}],
		["precision", "Precision", 1, 2, 5, {"dps": 1}],
		["endurance", "Endurance", 2, 0, 2, {"hp": 3}],
		["imp_kick", "Improved Kick", 2, 2, 2, {"interrupt": 15}],
		["dual_wield_spec", "Dual Wield Specialization", 3, 1, 5, {"dps": 1}],
		["blade_flurry", "Blade Flurry", 4, 0, 1, {"aoe": 15}],
		["sword_spec", "Sword Specialization", 4, 2, 5, {"extra_attack": 1}],
		["weapon_expertise", "Weapon Expertise", 5, 1, 2, {"haste": 2}],
		["aggression", "Aggression", 5, 2, 3, {"dps": 1}],
		["adrenaline_rush", "Adrenaline Rush", 6, 1, 1, {"opener": 25}],
	],
	"rogue_subtlety": [
		["master_of_deception", "Master of Deception", 0, 0, 5, {"threat": 4}],
		["opportunity", "Opportunity", 0, 1, 5, {"dps": 1}],
		["camouflage", "Camouflage", 0, 2, 5, {"opener": 2}],
		["initiative", "Initiative", 1, 0, 3, {"opener": 3}],
		["ghostly_strike", "Ghostly Strike", 1, 1, 1, {"dodge": 4}],
		["imp_ambush", "Improved Ambush", 1, 2, 3, {"crit": 1}],
		["setup", "Setup", 2, 0, 3, {"haste": 1.5}],
		["elusiveness", "Elusiveness", 2, 2, 2, {"mit": 2}],
		["serrated_blades", "Serrated Blades", 3, 1, 3, {"enemy_vuln": 0.7}],
		["dirty_deeds", "Dirty Deeds", 4, 0, 2, {"execute": 8}],
		["hemorrhage", "Hemorrhage", 4, 1, 1, {"enemy_vuln": 2}],
		["cheat_death", "Cheat Death", 5, 1, 3, {"cheat_death": 33}],
		["preparation", "Preparation", 5, 2, 1, {"opener": 10}],
		["premeditation", "Premeditation", 6, 1, 1, {"dps": 5}],
	],
	"hunter_beast_mastery": [
		["endurance_training", "Endurance Training", 0, 0, 5, {"hp": 1}],
		["imp_aspect_hawk", "Improved Aspect of the Hawk", 0, 1, 5, {"haste": 1}],
		["thick_hide", "Thick Hide", 0, 2, 3, {"mit": 1}],
		["unleashed_fury", "Unleashed Fury", 1, 0, 5, {"dps": 1}],
		["ferocity", "Ferocity", 1, 2, 5, {"crit": 1}],
		["imp_mend_pet", "Improved Mend Pet", 2, 0, 2, {"leech": 1.5}],
		["intimidation", "Intimidation", 2, 1, 1, {"interrupt": 20}],
		["bestial_discipline", "Bestial Discipline", 2, 2, 2, {"dps": 1.5}],
		["frenzy", "Frenzy", 3, 2, 5, {"haste": 1.5}],
		["bestial_wrath", "Bestial Wrath", 4, 1, 1, {"opener": 20}],
		["ferocious_inspiration", "Ferocious Inspiration", 5, 1, 3, {"party_dps": 1}],
		["the_beast_within", "The Beast Within", 6, 1, 1, {"dps": 6}],
	],
	"hunter_marksmanship": [
		["efficiency", "Efficiency", 0, 1, 5, {"haste": 1}],
		["lethal_shots", "Lethal Shots", 0, 2, 5, {"crit": 1}],
		["imp_hunters_mark", "Improved Hunter's Mark", 1, 0, 5, {"enemy_vuln": 0.6}],
		["aimed_shot", "Aimed Shot", 1, 1, 1, {"boss": 5}],
		["imp_scorpid_sting", "Improved Scorpid Sting", 2, 0, 3, {"enemy_dmg": 0.6}],
		["mortal_shots", "Mortal Shots", 2, 1, 5, {"crit_dmg": 6}],
		["scatter_shot", "Scatter Shot", 2, 2, 1, {"interrupt": 15}],
		["barrage", "Barrage", 3, 0, 3, {"aoe": 5}],
		["ranged_weapon_spec", "Ranged Weapon Specialization", 3, 2, 5, {"dps": 1}],
		["hawk_eye", "Hawk Eye", 4, 1, 3, {"dps": 1}],
		["trueshot_aura", "Improved Trueshot Aura", 6, 1, 1, {"party_dps": 3}],
	],
	"hunter_survival": [
		["monster_slaying", "Monster Slaying", 0, 0, 3, {"boss": 1}],
		["humanoid_slaying", "Humanoid Slaying", 0, 1, 3, {"dps": 1}],
		["deflection", "Deflection", 0, 2, 5, {"dodge": 1}],
		["entrapment", "Entrapment", 1, 0, 5, {"enemy_dmg": 0.5}],
		["savage_strikes", "Savage Strikes", 1, 1, 2, {"crit": 2}],
		["imp_wing_clip", "Improved Wing Clip", 1, 2, 3, {"mit": 1}],
		["survivalist", "Survivalist", 2, 0, 5, {"hp": 2}],
		["deterrence", "Deterrence", 2, 1, 1, {"dodge": 5}],
		["trap_mastery", "Trap Mastery", 2, 2, 2, {"aoe": 5}],
		["killer_instinct", "Killer Instinct", 3, 1, 3, {"crit": 1}],
		["counterattack", "Counterattack", 4, 0, 1, {"interrupt": 15}],
		["lightning_reflexes", "Lightning Reflexes", 4, 2, 5, {"dps": 1.5}],
		["wyvern_sting", "Wyvern Sting", 6, 1, 1, {"interrupt": 20, "dps": 3}],
	],
	"mage_arcane": [
		["arcane_subtlety", "Arcane Subtlety", 0, 0, 2, {"threat": 10}],
		["arcane_focus", "Arcane Focus", 0, 1, 5, {"dps": 0.6}],
		["imp_arcane_missiles", "Improved Arcane Missiles", 0, 2, 5, {"haste": 1}],
		["arcane_concentration", "Arcane Concentration", 1, 1, 5, {"dps": 1}],
		["imp_arcane_explosion", "Improved Arcane Explosion", 1, 2, 3, {"aoe": 5}],
		["magic_absorption", "Magic Absorption", 2, 0, 5, {"mit": 1}],
		["imp_counterspell", "Improved Counterspell", 2, 2, 2, {"interrupt": 15}],
		["arcane_mind", "Arcane Mind", 3, 1, 5, {"dps": 1}],
		["presence_of_mind", "Presence of Mind", 4, 0, 1, {"opener": 15}],
		["arcane_instability", "Arcane Instability", 4, 1, 3, {"crit": 1, "dps": 1}],
		["arcane_brilliance", "Arcane Brilliance", 5, 2, 1, {"priest_mana": 6}],
		["arcane_power", "Arcane Power", 6, 1, 1, {"opener": 30}],
	],
	"mage_fire": [
		["imp_fireball", "Improved Fireball", 0, 1, 5, {"haste": 1.5}],
		["impact", "Impact", 0, 2, 5, {"interrupt": 2}],
		["ignite", "Ignite", 1, 0, 5, {"crit_dmg": 8}],
		["flame_throwing", "Flame Throwing", 1, 2, 2, {"threat": 6}],
		["imp_flamestrike", "Improved Flamestrike", 2, 0, 3, {"aoe": 5}],
		["pyroblast", "Pyroblast", 2, 1, 1, {"opener": 10}],
		["burning_soul", "Burning Soul", 2, 2, 2, {"mit": 2}],
		["imp_scorch", "Improved Scorch", 3, 0, 3, {"enemy_vuln": 1}],
		["master_of_elements", "Master of Elements", 3, 2, 3, {"dps": 1}],
		["critical_mass", "Critical Mass", 4, 1, 3, {"crit": 2}],
		["blast_wave", "Blast Wave", 5, 0, 1, {"aoe": 10}],
		["fire_power", "Fire Power", 5, 2, 5, {"dps": 1.5}],
		["combustion", "Combustion", 6, 1, 1, {"opener": 30}],
	],
	"mage_frost": [
		["frost_warding", "Frost Warding", 0, 0, 2, {"mit": 1.5}],
		["imp_frostbolt", "Improved Frostbolt", 0, 1, 5, {"haste": 1.5}],
		["elemental_precision", "Elemental Precision", 0, 2, 3, {"dps": 1}],
		["ice_shards", "Ice Shards", 1, 0, 5, {"crit_dmg": 8}],
		["frostbite", "Frostbite", 1, 1, 3, {"enemy_dmg": 0.7}],
		["imp_frost_nova", "Improved Frost Nova", 1, 2, 2, {"mit": 1}],
		["permafrost", "Permafrost", 2, 0, 3, {"enemy_dmg": 0.5}],
		["piercing_ice", "Piercing Ice", 2, 1, 3, {"dps": 1.5}],
		["cold_snap", "Cold Snap", 2, 2, 1, {"opener": 10}],
		["imp_blizzard", "Improved Blizzard", 3, 0, 3, {"aoe": 5}],
		["arctic_reach", "Arctic Reach", 3, 2, 2, {"threat": 5}],
		["frost_channeling", "Frost Channeling", 4, 0, 3, {"dps": 1}],
		["shatter", "Shatter", 4, 1, 5, {"crit": 1.5}],
		["winters_chill", "Winter's Chill", 4, 2, 5, {"enemy_vuln": 0.4}],
		["ice_block", "Ice Block", 5, 1, 1, {"ice_block": 6}],
		["ice_barrier", "Ice Barrier", 6, 1, 1, {"mit": 6}],
	],
	"warlock_affliction": [
		["imp_curse_weakness", "Improved Curse of Weakness", 0, 0, 3, {"enemy_dmg": 0.7}],
		["suppression", "Suppression", 0, 1, 5, {"dps": 1}],
		["imp_corruption", "Improved Corruption", 0, 2, 5, {"haste": 1}],
		["imp_drain_life", "Improved Drain Life", 1, 0, 5, {"leech": 1}],
		["imp_curse_agony", "Improved Curse of Agony", 1, 1, 3, {"boss": 2}],
		["imp_life_tap", "Improved Life Tap", 1, 2, 2, {"hp": 2}],
		["grim_reach", "Grim Reach", 2, 0, 2, {"threat": 5}],
		["amplify_curse", "Amplify Curse", 2, 1, 1, {"enemy_dmg": 2}],
		["nightfall", "Nightfall", 2, 2, 2, {"crit": 2}],
		["siphon_life", "Siphon Life", 3, 1, 1, {"leech": 3, "dps": 2}],
		["shadow_mastery", "Shadow Mastery", 4, 1, 5, {"dps": 1.5}],
		["dark_pact", "Dark Pact", 5, 1, 1, {"priest_regen": 10}],
		["malediction", "Malediction", 6, 1, 1, {"enemy_vuln": 3}],
	],
	"warlock_demonology": [
		["imp_healthstone", "Improved Healthstone", 0, 0, 2, {"healthstone_bonus": 10}],
		["imp_imp", "Improved Imp", 0, 1, 3, {"party_hp": 1}],
		["demonic_embrace", "Demonic Embrace", 0, 2, 5, {"hp": 3}],
		["imp_voidwalker", "Improved Voidwalker", 1, 0, 3, {"mit": 1}],
		["fel_intellect", "Fel Intellect", 1, 1, 5, {"priest_mana": 1}],
		["imp_succubus", "Improved Succubus", 1, 2, 3, {"dps": 1}],
		["master_summoner", "Master Summoner", 2, 0, 2, {"opener": 5}],
		["unholy_power", "Unholy Power", 2, 2, 5, {"dps": 1.5}],
		["demonic_sacrifice", "Demonic Sacrifice", 3, 1, 1, {"dps": 8}],
		["imp_firestone", "Improved Firestone", 3, 2, 2, {"crit": 1}],
		["master_demonologist", "Master Demonologist", 4, 1, 5, {"enemy_dmg": 0.6}],
		["soul_link", "Soul Link", 5, 1, 1, {"mit": 5}],
		["imp_spellstone", "Improved Spellstone", 5, 2, 2, {"mit": 1}],
		["felguard", "Summon Felguard", 6, 1, 1, {"dps": 6, "interrupt": 10}],
	],
	"warlock_destruction": [
		["imp_shadow_bolt", "Improved Shadow Bolt", 0, 1, 5, {"enemy_vuln": 0.6}],
		["cataclysm", "Cataclysm", 0, 2, 5, {"dps": 0.6}],
		["imp_firebolt", "Improved Firebolt", 1, 0, 2, {"dps": 1}],
		["bane", "Bane", 1, 1, 5, {"haste": 1.5}],
		["aftermath", "Aftermath", 1, 2, 5, {"enemy_dmg": 0.4}],
		["intensity", "Intensity", 2, 0, 2, {"mit": 1}],
		["devastation", "Devastation", 2, 1, 5, {"crit": 1}],
		["shadowburn", "Shadowburn", 2, 2, 1, {"execute": 15}],
		["destructive_reach", "Destructive Reach", 3, 0, 2, {"threat": 5}],
		["imp_searing_pain", "Improved Searing Pain", 3, 2, 5, {"crit": 0.6}],
		["ruin", "Ruin", 4, 1, 1, {"crit_dmg": 25}],
		["emberstorm", "Emberstorm", 5, 1, 5, {"dps": 1.5}],
		["imp_immolate", "Improved Immolate", 5, 2, 5, {"boss": 1}],
		["conflagrate", "Conflagrate", 6, 1, 1, {"dps": 5}],
	],
	"druid_balance": [
		["imp_wrath", "Improved Wrath", 0, 0, 5, {"haste": 1}],
		["natures_grasp", "Nature's Grasp", 0, 1, 1, {"mit": 2}],
		["imp_moonfire", "Improved Moonfire", 1, 0, 2, {"crit": 2}],
		["natural_weapons", "Natural Weapons", 1, 1, 5, {"dps": 1}],
		["natural_shapeshifter", "Natural Shapeshifter", 1, 2, 3, {"threat": 4}],
		["omen_of_clarity", "Omen of Clarity", 2, 1, 1, {"dps": 3}],
		["natures_grace", "Nature's Grace", 3, 0, 1, {"haste": 3}],
		["vengeance", "Vengeance", 3, 1, 5, {"crit_dmg": 8}],
		["imp_starfire", "Improved Starfire", 3, 2, 5, {"haste": 1}],
		["moonglow", "Moonglow", 4, 0, 3, {"priest_regen": 2}],
		["moonfury", "Moonfury", 4, 1, 5, {"dps": 1.5}],
		["imp_faerie_fire", "Improved Faerie Fire", 4, 2, 3, {"enemy_vuln": 0.7}],
		["moonkin_form", "Moonkin Form", 6, 1, 1, {"party_crit": 3, "mit": 5}],
	],
	"druid_feral": [
		["ferocity", "Ferocity", 0, 0, 5, {"aggro": 0.6}],
		["feral_aggression", "Feral Aggression", 0, 1, 5, {"enemy_dmg": 0.8}],
		["thick_hide", "Thick Hide", 0, 2, 5, {"mit": 1.5}],
		["sharpened_claws", "Sharpened Claws", 1, 0, 3, {"crit": 2}],
		["feral_instinct", "Feral Instinct", 1, 1, 5, {"aggro": 0.6}],
		["feral_charge", "Feral Charge", 1, 2, 1, {"interrupt": 20}],
		["predatory_strikes", "Predatory Strikes", 2, 0, 3, {"dps": 2}],
		["primal_fury", "Primal Fury", 2, 1, 2, {"dps": 3}],
		["savage_fury", "Savage Fury", 2, 2, 2, {"dps": 2}],
		["faerie_fire_feral", "Faerie Fire (Feral)", 3, 1, 1, {"enemy_vuln": 2}],
		["heart_of_the_wild", "Heart of the Wild", 4, 1, 5, {"hp": 2}],
		["frenzied_regeneration", "Frenzied Regeneration", 5, 0, 1, {"last_stand": 30}],
		["survival_of_the_fittest", "Survival of the Fittest", 5, 2, 3, {"mit": 1}],
		["leader_of_the_pack", "Leader of the Pack", 6, 1, 1, {"party_crit": 3}],
	],
	"druid_cat": [
		["ferocity", "Ferocity", 0, 0, 5, {"dps": 1}],
		["feral_aggression", "Feral Aggression", 0, 1, 5, {"crit_dmg": 4}],
		["imp_shred", "Improved Shred", 1, 0, 2, {"dps": 1.5}],
		["sharpened_claws", "Sharpened Claws", 1, 1, 3, {"crit": 2}],
		["feral_instinct", "Feral Instinct", 1, 2, 5, {"threat": 4}],
		["blood_frenzy", "Blood Frenzy", 2, 0, 2, {"haste": 3}],
		["primal_fury", "Primal Fury", 2, 1, 2, {"dps": 2}],
		["predatory_strikes", "Predatory Strikes", 2, 2, 3, {"dps": 2}],
		["savage_fury", "Savage Fury", 3, 1, 2, {"dps": 3}],
		["faerie_fire_feral", "Faerie Fire (Feral)", 3, 2, 1, {"enemy_vuln": 2}],
		["omen_of_clarity", "Omen of Clarity", 4, 0, 1, {"haste": 4}],
		["heart_of_the_wild", "Heart of the Wild", 4, 1, 5, {"dps": 1}],
		["mangle", "Mangle", 5, 1, 1, {"enemy_vuln": 3}],
		["leader_of_the_pack", "Leader of the Pack", 6, 1, 1, {"party_crit": 3}],
	],
}

## Recruits arrive with 2 traits from their role's list (always good)...
const TRAITS := {
	"melee": [["Ferocious", {"crit": 3}], ["Relentless", {"haste": 4}], ["Brutal", {"crit_dmg": 12}], ["Executioner", {"execute": 15}],
		["Duelist", {"dodge": 4}], ["Bloodthirsty", {"leech": 2}], ["Opportunist", {"opener": 12}], ["Cleaver", {"aoe": 10}],
		["Giant Slayer", {"boss": 5}], ["Interrupter", {"interrupt": 15}]],
	"ranged": [["Deadeye", {"crit": 3}], ["Quickdraw", {"haste": 4}], ["Devastating", {"crit_dmg": 12}], ["Finisher", {"execute": 15}],
		["Elusive", {"threat": 15}], ["Siphoner", {"leech": 2}], ["Ambusher", {"opener": 12}], ["Barrage", {"aoe": 10}],
		["Giant Slayer", {"boss": 5}], ["Spellbreaker", {"interrupt": 15}]],
	"tank": [["Stalwart", {"mit": 4}], ["Hulking", {"hp": 6}], ["Taunting", {"aggro": 4}], ["Nimble", {"dodge": 4}],
		["Intimidating", {"enemy_dmg": 3}], ["Unyielding", {"last_stand": 20}], ["Sunderer", {"enemy_vuln": 2}],
		["Bulwark", {"party_mit": 2}], ["Interrupter", {"interrupt": 15}], ["Bloodthirsty", {"leech": 2}]],
}

## ...and up to 2 affixes, which can be good or bad.
const AFFIXES_GOOD := [["Sturdy", {"hp": 5}], ["Keen", {"crit": 2}], ["Swift", {"haste": 3}], ["Inspiring", {"party_dps": 1}],
	["Wise", {"priest_regen": 4}], ["Tough", {"mit": 3}], ["Focused", {"dps": 3}], ["Lucky", {"cheat_death": 25}]]
const AFFIXES_BAD := [["Frail", {"hp": -5}], ["Clumsy", {"crit": -2}], ["Sluggish", {"haste": -3}], ["Reckless", {"threat": -15}],
	["Timid", {"dps": -4}], ["Brittle", {"mit": -3}], ["Distracted", {"aggro": -4}], ["Cowardly", {"opener": -10}]]


static func points_at(level: int) -> int:
	return clampi(level - START_LEVEL + 1, 0, MAX_POINTS)


static func tree(spec_id: String) -> Array:
	return TREES.get(spec_id, [])


static func find(spec_id: String, id: String) -> Array:
	for t in tree(spec_id):
		if t[0] == id:
			return t
	return []


static func spent(talents: Dictionary) -> int:
	var n := 0
	for k in talents:
		n += talents[k]
	return n


static func can_learn(spec_id: String, talents: Dictionary, id: String, level: int) -> bool:
	var t := find(spec_id, id)
	if t.is_empty() or talents.get(id, 0) >= t[4]:
		return false
	if spent(talents) >= points_at(level):
		return false
	return spent(talents) >= t[2] * POINTS_PER_TIER


## Fills unspent points in tree order: every tier in turn, each talent to its maximum rank.
static func auto_build(spec_id: String, talents: Dictionary, level: int) -> Dictionary:
	var out := talents.duplicate()
	var progress := true
	while progress and spent(out) < points_at(level):
		progress = false
		for t in tree(spec_id):
			if can_learn(spec_id, out, t[0], level):
				out[t[0]] = out.get(t[0], 0) + 1
				progress = true
				break
	return out


static func number(v: float) -> String:
	return str(int(round(v))) if absf(v - roundf(v)) < 0.05 else "%.1f" % v


## "+5% health"; a negative value (bad affix) flips the template's sign: "-5% health".
static func effect_text(key: String, value: float) -> String:
	var txt: String = EFFECTS.get(key, [key, "%s " + key])[1]
	if txt.begins_with("+") or txt.begins_with("-"):
		var sign := txt.substr(0, 1)
		if value < 0.0:
			sign = "-" if sign == "+" else "+"
		return sign + (txt.substr(1) % number(absf(value)))
	return txt % number(value)


static func effects_text(effects: Dictionary) -> String:
	var parts := []
	for k in effects:
		parts.append(effect_text(k, effects[k]))
	return ", ".join(parts)


## Adds `effects` scaled by `times` into `into`.
static func add_effects(into: Dictionary, effects: Dictionary, times := 1.0) -> void:
	for k in effects:
		into[k] = into.get(k, 0.0) + effects[k] * times


## Power bonus (as a fraction) that a set of effects is worth.
static func power_value(mods: Dictionary) -> float:
	var v := 0.0
	for k in mods:
		v += mods[k] * WEIGHTS.get(k, 0.0)
	return v / 100.0
