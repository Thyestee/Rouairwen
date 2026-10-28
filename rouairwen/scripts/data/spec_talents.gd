class_name SpecTalents
## Guildmate talent trees (one per spec, laid out like WoW's), their abilities, traits and affixes.
##
## Each tree has 3 to 5 abilities that guildmates use on their own in fights: damage abilities on
## cooldown, interrupts, taunts, defensives and heals whenever needed. Other talents improve those
## abilities ("rend.dmg": +% Rend damage), raise stats ("str%": +% Strength), or add effects the
## combat engine understands. Party and enemy effects don't stack between guildmates: the strongest
## one in the party counts.

const START_LEVEL := 10
const MAX_POINTS := 36
const POINTS_PER_TIER := 5
const TIERS := 8

## [label, description with %s for the value]
const EFFECTS := {
	"str%": ["Strength", "+%s%% Strength"], "agi%": ["Agility", "+%s%% Agility"], "sta%": ["Stamina", "+%s%% Stamina"],
	"int%": ["Intellect", "+%s%% Intellect"], "spi%": ["Spirit", "+%s%% Spirit"],
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
	"party_dps": ["Party damage", "Party: +%s%% damage"],
	"party_crit": ["Party critical", "Party: +%s%% critical strike chance"],
	"party_hp": ["Party health", "Party: +%s%% health"],
	"party_mit": ["Party protection", "Party: -%s%% damage taken"],
	"priest_regen": ["Mana for Thyeste", "Thyeste's mana regeneration +%s%%"],
	"priest_mana": ["Mana pool for Thyeste", "Thyeste's maximum mana +%s%%"],
	"enemy_dmg": ["Weaken enemies", "Enemies deal %s%% less damage"],
	"enemy_vuln": ["Expose enemies", "Enemies take %s%% more damage"],
	"windfury_bonus": ["Windfury", "+%s%% Windfury Totem proc chance"],
	"healthstone_bonus": ["Healthstones", "Healthstones heal %s%% more"],
}
const GROUP_KEYS := ["party_dps", "party_crit", "party_hp", "party_mit", "priest_regen", "priest_mana",
	"enemy_dmg", "enemy_vuln", "windfury_bonus", "healthstone_bonus"]

## How much one point of an effect is worth when estimating a guildmate's power (in % of power).
const WEIGHTS := {
	"str%": 0.45, "agi%": 0.35, "sta%": 0.15, "int%": 0.1, "spi%": 0.0,
	"dps": 1.0, "crit": 0.9, "crit_dmg": 0.11, "haste": 0.9, "hp": 0.4, "mit": 0.6, "dodge": 0.4, "aggro": 0.4,
	"threat": 0.05, "boss": 0.5, "aoe": 0.3, "execute": 0.2, "leech": 0.3, "extra_attack": 0.9, "opener": 0.2,
	"interrupt": 0.1, "cheat_death": 0.03, "last_stand": 0.12, "party_dps": 2.5, "party_crit": 2.2,
	"party_hp": 1.0, "party_mit": 2.0, "priest_regen": 0.4, "priest_mana": 0.4, "enemy_dmg": 2.0, "enemy_vuln": 2.5,
	"windfury_bonus": 1.0, "healthstone_bonus": 0.05,
}

## Abilities guildmates use on their own. coef: damage as seconds of their normal damage.
## kinds: strike, dot, aoe, execute, burst, debuff, debuff_all, stun, stun_all, interrupt, taunt,
## defensive, self_heal, shield, feign. at: health (or enemy health for execute) that triggers it.
const ABILITIES := {
	# Warrior
	"rend": {"name": "Rend", "kind": "dot", "cd": 15.0, "coef": 3.0, "dur": 15.0},
	"overpower": {"name": "Overpower", "kind": "strike", "cd": 5.0, "coef": 1.0},
	"sweeping_strikes": {"name": "Sweeping Strikes", "kind": "burst", "cd": 30.0, "dur": 10.0, "aoe": 40.0},
	"mortal_strike": {"name": "Mortal Strike", "kind": "strike", "cd": 6.0, "coef": 1.6, "debuff": {"anti_heal": 50.0, "dur": 10.0}},
	"pummel": {"name": "Pummel", "kind": "interrupt", "cd": 10.0},
	"whirlwind": {"name": "Whirlwind", "kind": "aoe", "cd": 10.0, "coef": 1.2, "max": 4},
	"death_wish": {"name": "Death Wish", "kind": "burst", "cd": 180.0, "dur": 30.0, "pct": 20.0},
	"execute": {"name": "Execute", "kind": "execute", "cd": 4.0, "coef": 2.5, "at": 0.2},
	"bloodthirst": {"name": "Bloodthirst", "kind": "strike", "cd": 6.0, "coef": 1.5, "leech": 30.0},
	"taunt": {"name": "Taunt", "kind": "taunt", "cd": 10.0},
	"thunder_clap": {"name": "Thunder Clap", "kind": "aoe", "cd": 6.0, "coef": 0.6, "debuff": {"weaken": 8.0, "dur": 10.0}},
	"shield_wall": {"name": "Shield Wall", "kind": "defensive", "cd": 180.0, "dur": 10.0, "pct": 60.0, "at": 0.3},
	"last_stand": {"name": "Last Stand", "kind": "self_heal", "cd": 300.0, "pct": 30.0, "at": 0.2},
	"shield_slam": {"name": "Shield Slam", "kind": "strike", "cd": 6.0, "coef": 2.0},
	# Shaman
	"earth_shock": {"name": "Earth Shock", "kind": "interrupt", "cd": 6.0, "coef": 1.2},
	"flame_shock": {"name": "Flame Shock", "kind": "dot", "cd": 12.0, "coef": 2.4, "dur": 12.0},
	"chain_lightning": {"name": "Chain Lightning", "kind": "aoe", "cd": 6.0, "coef": 1.0, "max": 3},
	"elemental_mastery": {"name": "Elemental Mastery", "kind": "burst", "cd": 180.0, "dur": 8.0, "pct": 35.0},
	"stormstrike": {"name": "Stormstrike", "kind": "strike", "cd": 20.0, "coef": 1.8, "debuff": {"vuln": 8.0, "dur": 12.0}},
	"shamanistic_rage": {"name": "Shamanistic Rage", "kind": "defensive", "cd": 120.0, "dur": 15.0, "pct": 30.0, "at": 0.5},
	# Rogue
	"kick": {"name": "Kick", "kind": "interrupt", "cd": 10.0},
	"rupture": {"name": "Rupture", "kind": "dot", "cd": 16.0, "coef": 3.2, "dur": 16.0},
	"eviscerate": {"name": "Eviscerate", "kind": "strike", "cd": 7.0, "coef": 1.8},
	"cold_blood": {"name": "Cold Blood", "kind": "burst", "cd": 180.0, "dur": 6.0, "pct": 40.0},
	"sinister_strike": {"name": "Sinister Strike", "kind": "strike", "cd": 3.0, "coef": 0.6},
	"blade_flurry": {"name": "Blade Flurry", "kind": "burst", "cd": 120.0, "dur": 15.0, "aoe": 100.0, "haste": 20.0},
	"adrenaline_rush": {"name": "Adrenaline Rush", "kind": "burst", "cd": 300.0, "dur": 15.0, "haste": 50.0},
	"hemorrhage": {"name": "Hemorrhage", "kind": "strike", "cd": 4.0, "coef": 0.8, "debuff": {"vuln": 3.0, "dur": 15.0}},
	"kidney_shot": {"name": "Kidney Shot", "kind": "stun", "cd": 20.0, "dur": 4.0},
	"vanish": {"name": "Vanish", "kind": "feign", "cd": 60.0, "at": 0.6},
	# Hunter
	"serpent_sting": {"name": "Serpent Sting", "kind": "dot", "cd": 15.0, "coef": 2.6, "dur": 15.0},
	"arcane_shot": {"name": "Arcane Shot", "kind": "strike", "cd": 6.0, "coef": 1.1},
	"intimidation": {"name": "Intimidation", "kind": "stun", "cd": 60.0, "dur": 3.0},
	"bestial_wrath": {"name": "Bestial Wrath", "kind": "burst", "cd": 120.0, "dur": 18.0, "pct": 25.0},
	"aimed_shot": {"name": "Aimed Shot", "kind": "strike", "cd": 6.0, "coef": 2.0},
	"multi_shot": {"name": "Multi-Shot", "kind": "aoe", "cd": 10.0, "coef": 0.9, "max": 3},
	"rapid_fire": {"name": "Rapid Fire", "kind": "burst", "cd": 300.0, "dur": 15.0, "haste": 40.0},
	"scatter_shot": {"name": "Scatter Shot", "kind": "interrupt", "cd": 30.0},
	"explosive_trap": {"name": "Explosive Trap", "kind": "aoe", "cd": 30.0, "coef": 1.5},
	"wyvern_sting": {"name": "Wyvern Sting", "kind": "stun", "cd": 60.0, "dur": 6.0},
	"deterrence": {"name": "Deterrence", "kind": "defensive", "cd": 300.0, "dur": 10.0, "pct": 50.0, "at": 0.4},
	# Mage
	"counterspell": {"name": "Counterspell", "kind": "interrupt", "cd": 24.0},
	"arcane_missiles": {"name": "Arcane Missiles", "kind": "strike", "cd": 5.0, "coef": 1.2},
	"arcane_explosion": {"name": "Arcane Explosion", "kind": "aoe", "cd": 4.0, "coef": 0.5},
	"arcane_power": {"name": "Arcane Power", "kind": "burst", "cd": 180.0, "dur": 15.0, "pct": 30.0},
	"fire_blast": {"name": "Fire Blast", "kind": "strike", "cd": 8.0, "coef": 1.3},
	"pyroblast": {"name": "Pyroblast", "kind": "strike", "cd": 20.0, "coef": 4.0},
	"blast_wave": {"name": "Blast Wave", "kind": "aoe", "cd": 45.0, "coef": 1.8},
	"combustion": {"name": "Combustion", "kind": "burst", "cd": 180.0, "dur": 10.0, "crit": 30.0},
	"frost_nova": {"name": "Frost Nova", "kind": "stun_all", "cd": 25.0, "dur": 3.0},
	"cone_of_cold": {"name": "Cone of Cold", "kind": "aoe", "cd": 10.0, "coef": 0.9},
	"ice_block": {"name": "Ice Block", "kind": "defensive", "cd": 300.0, "dur": 6.0, "pct": 100.0, "at": 0.15},
	"ice_barrier": {"name": "Ice Barrier", "kind": "shield", "cd": 30.0, "pct": 15.0},
	# Warlock
	"corruption": {"name": "Corruption", "kind": "dot", "cd": 18.0, "coef": 3.0, "dur": 18.0},
	"curse_of_agony": {"name": "Curse of Agony", "kind": "dot", "cd": 24.0, "coef": 3.6, "dur": 24.0},
	"siphon_life": {"name": "Siphon Life", "kind": "dot", "cd": 30.0, "coef": 3.0, "dur": 30.0, "leech": 100.0},
	"curse_of_weakness": {"name": "Curse of Weakness", "kind": "debuff", "cd": 30.0, "dur": 30.0, "debuff": {"weaken": 6.0}},
	"spell_lock": {"name": "Spell Lock", "kind": "interrupt", "cd": 24.0},
	"immolate": {"name": "Immolate", "kind": "dot", "cd": 15.0, "coef": 2.6, "dur": 15.0},
	"death_coil": {"name": "Death Coil", "kind": "strike", "cd": 30.0, "coef": 3.0, "leech": 100.0},
	"curse_of_recklessness": {"name": "Curse of Recklessness", "kind": "debuff", "cd": 30.0, "dur": 30.0, "debuff": {"vuln": 4.0}},
	"conflagrate": {"name": "Conflagrate", "kind": "strike", "cd": 10.0, "coef": 1.8},
	"shadowburn": {"name": "Shadowburn", "kind": "execute", "cd": 15.0, "coef": 3.0, "at": 0.25},
	"rain_of_fire": {"name": "Rain of Fire", "kind": "aoe", "cd": 15.0, "coef": 1.6},
	"curse_of_elements": {"name": "Curse of the Elements", "kind": "debuff", "cd": 30.0, "dur": 30.0, "debuff": {"vuln": 6.0}},
	# Druid
	"moonfire": {"name": "Moonfire", "kind": "dot", "cd": 12.0, "coef": 2.2, "dur": 12.0},
	"insect_swarm": {"name": "Insect Swarm", "kind": "dot", "cd": 12.0, "coef": 1.8, "dur": 12.0, "debuff": {"weaken": 4.0}},
	"starfire": {"name": "Starfire", "kind": "strike", "cd": 8.0, "coef": 2.0},
	"hurricane": {"name": "Hurricane", "kind": "aoe", "cd": 30.0, "coef": 1.8},
	"faerie_fire": {"name": "Faerie Fire", "kind": "debuff", "cd": 40.0, "dur": 40.0, "debuff": {"vuln": 5.0}},
	"growl": {"name": "Growl", "kind": "taunt", "cd": 8.0},
	"maul": {"name": "Maul", "kind": "strike", "cd": 4.0, "coef": 0.7},
	"swipe": {"name": "Swipe", "kind": "aoe", "cd": 6.0, "coef": 0.6},
	"demoralizing_roar": {"name": "Demoralizing Roar", "kind": "debuff_all", "cd": 30.0, "dur": 30.0, "debuff": {"weaken": 8.0}},
	"frenzied_regeneration": {"name": "Frenzied Regeneration", "kind": "self_heal", "cd": 180.0, "pct": 30.0, "at": 0.35},
	"rake": {"name": "Rake", "kind": "dot", "cd": 9.0, "coef": 1.6, "dur": 9.0},
	"shred": {"name": "Shred", "kind": "strike", "cd": 4.0, "coef": 0.9},
	"ferocious_bite": {"name": "Ferocious Bite", "kind": "execute", "cd": 10.0, "coef": 2.2, "at": 0.35},
	"tigers_fury": {"name": "Tiger's Fury", "kind": "burst", "cd": 30.0, "dur": 6.0, "pct": 25.0},
}

## Order in which a guildmate considers their abilities (reactive ones first).
const PRIORITY := ["defensive", "self_heal", "shield", "feign", "taunt", "burst", "debuff", "debuff_all", "stun",
	"stun_all", "dot", "execute", "aoe", "strike"]
## Power an ability adds when estimating a guildmate's strength. Strikes and damage over time
## mostly move damage away from auto attacks (see damage_share), so they add little by themselves.
const ABILITY_VALUE := {"strike": 0.02, "dot": 0.02, "aoe": 0.05, "execute": 0.02, "burst": 0.04, "debuff": 0.05,
	"debuff_all": 0.05, "stun": 0.03, "stun_all": 0.03, "interrupt": 0.04, "taunt": 0.05, "defensive": 0.03,
	"self_heal": 0.03, "shield": 0.03, "feign": 0.02}
## How much of each kind's base damage counts in a guildmate's usual damage: executes only hit low
## targets and area abilities need a pack.
const SHARE := {"strike": 1.0, "dot": 1.0, "execute": 0.2, "aoe": 0.4}

## [id, name, tier, column, ranks, {effect: value per rank}, prerequisite talent id (optional)]
## {"ability": id} grants an ability; "<ability>.dmg"/".cd"/".dur"/".pct" improve it.
const TREES := {
	"warrior_arms": [
		["deflection", "Deflection", 0, 0, 5, {"dodge": 1}],
		["imp_heroic_strike", "Improved Heroic Strike", 0, 1, 3, {"dps": 1}],
		["rend", "Rend", 0, 2, 1, {"ability": "rend"}],
		["tactical_mastery", "Tactical Mastery", 1, 0, 5, {"opener": 3}],
		["strength_of_arms", "Strength of Arms", 1, 1, 5, {"str%": 2}],
		["imp_rend", "Improved Rend", 1, 2, 3, {"rend.dmg": 8}, "rend"],
		["anger_management", "Anger Management", 2, 0, 1, {"haste": 4}],
		["overpower", "Overpower", 2, 1, 1, {"ability": "overpower"}],
		["deep_wounds", "Deep Wounds", 2, 2, 3, {"crit_dmg": 6}],
		["imp_overpower", "Improved Overpower", 3, 1, 2, {"overpower.dmg": 10}, "overpower"],
		["two_handed_spec", "Two-Handed Weapon Specialization", 3, 2, 5, {"dps": 1}],
		["sweeping_strikes", "Sweeping Strikes", 4, 0, 1, {"ability": "sweeping_strikes"}],
		["impale", "Impale", 4, 1, 2, {"crit_dmg": 10}],
		["poleaxe_spec", "Poleaxe Specialization", 4, 2, 5, {"crit": 1}],
		["imp_sweeping_strikes", "Improved Sweeping Strikes", 5, 0, 2, {"sweeping_strikes.dur": 3}, "sweeping_strikes"],
		["blood_frenzy", "Blood Frenzy", 5, 2, 2, {"enemy_vuln": 2}],
		["mortal_strike", "Mortal Strike", 6, 1, 1, {"ability": "mortal_strike"}],
		["imp_mortal_strike", "Improved Mortal Strike", 7, 1, 5, {"mortal_strike.dmg": 2, "mortal_strike.cd": -0.1}, "mortal_strike"],
	],
	"warrior_fury": [
		["imp_demo_shout", "Improved Demoralizing Shout", 0, 0, 5, {"enemy_dmg": 0.8}],
		["cruelty", "Cruelty", 0, 1, 5, {"crit": 1}],
		["pummel", "Pummel", 0, 2, 1, {"ability": "pummel"}],
		["commanding_presence", "Commanding Presence", 1, 0, 5, {"str%": 1, "party_dps": 0.4}],
		["unbridled_wrath", "Unbridled Wrath", 1, 1, 5, {"extra_attack": 1}],
		["imp_pummel", "Improved Pummel", 1, 2, 2, {"pummel.cd": -2}, "pummel"],
		["whirlwind", "Whirlwind", 2, 1, 1, {"ability": "whirlwind"}],
		["enrage", "Enrage", 2, 2, 5, {"dps": 1.2}],
		["dual_wield_spec", "Dual Wield Specialization", 3, 0, 5, {"dps": 1}],
		["imp_whirlwind", "Improved Whirlwind", 3, 1, 3, {"whirlwind.cd": -1, "whirlwind.dmg": 10}, "whirlwind"],
		["execute", "Execute", 3, 2, 1, {"ability": "execute"}],
		["death_wish", "Death Wish", 4, 1, 1, {"ability": "death_wish"}],
		["imp_execute", "Improved Execute", 4, 2, 2, {"execute.dmg": 20}, "execute"],
		["imp_berserker_rage", "Improved Berserker Rage", 5, 0, 2, {"mit": 2}],
		["flurry", "Flurry", 5, 1, 5, {"haste": 2}],
		["bloodthirst", "Bloodthirst", 6, 1, 1, {"ability": "bloodthirst"}],
		["rampage", "Rampage", 7, 1, 3, {"bloodthirst.dmg": 5, "str%": 1}, "bloodthirst"],
	],
	"warrior_protection": [
		["imp_bloodrage", "Improved Bloodrage", 0, 0, 2, {"aggro": 1.5}],
		["shield_spec", "Shield Specialization", 0, 1, 5, {"dodge": 1}],
		["taunt", "Taunt", 0, 2, 1, {"ability": "taunt"}],
		["anticipation", "Anticipation", 1, 0, 5, {"dodge": 1}],
		["toughness", "Toughness", 1, 1, 5, {"sta%": 2}],
		["imp_taunt", "Improved Taunt", 1, 2, 2, {"taunt.cd": -2}, "taunt"],
		["thunder_clap", "Thunder Clap", 2, 0, 1, {"ability": "thunder_clap"}],
		["iron_will", "Iron Will", 2, 1, 3, {"mit": 1}],
		["shield_wall", "Shield Wall", 2, 2, 1, {"ability": "shield_wall"}],
		["imp_thunder_clap", "Improved Thunder Clap", 3, 0, 3, {"thunder_clap.dmg": 20, "thunder_clap.pct": 2}, "thunder_clap"],
		["defiance", "Defiance", 3, 1, 5, {"aggro": 1}],
		["imp_shield_wall", "Improved Shield Wall", 3, 2, 2, {"shield_wall.dur": 3}, "shield_wall"],
		["last_stand", "Last Stand", 4, 0, 1, {"ability": "last_stand"}],
		["imp_sunder", "Improved Sunder Armor", 4, 1, 3, {"enemy_vuln": 1}],
		["one_handed_spec", "One-Handed Weapon Specialization", 4, 2, 5, {"dps": 4}],
		["vitality", "Vitality", 5, 1, 5, {"sta%": 1, "str%": 1}],
		["shield_slam", "Shield Slam", 6, 1, 1, {"ability": "shield_slam"}],
		["focused_rage", "Focused Rage", 7, 1, 3, {"shield_slam.dmg": 5, "aggro": 1}, "shield_slam"],
	],
	"shaman_elemental": [
		["convection", "Convection", 0, 0, 5, {"dps": 1}],
		["concussion", "Concussion", 0, 1, 5, {"dps": 1.4}],
		["earth_shock", "Earth Shock", 0, 2, 1, {"ability": "earth_shock"}],
		["flame_shock", "Flame Shock", 1, 0, 1, {"ability": "flame_shock"}],
		["elemental_warding", "Elemental Warding", 1, 1, 3, {"mit": 1}],
		["reverberation", "Reverberation", 1, 2, 5, {"earth_shock.cd": -0.4}, "earth_shock"],
		["imp_flame_shock", "Improved Flame Shock", 2, 0, 3, {"flame_shock.dmg": 8}, "flame_shock"],
		["ancestral_knowledge", "Ancestral Knowledge", 2, 1, 5, {"int%": 2}],
		["call_of_thunder", "Call of Thunder", 2, 2, 5, {"crit": 1}],
		["chain_lightning", "Chain Lightning", 3, 1, 1, {"ability": "chain_lightning"}],
		["call_of_flame", "Call of Flame", 3, 2, 3, {"aoe": 5}],
		["eye_of_the_storm", "Eye of the Storm", 4, 0, 3, {"mit": 1}],
		["imp_chain_lightning", "Improved Chain Lightning", 4, 1, 3, {"chain_lightning.dmg": 10}, "chain_lightning"],
		["elemental_fury", "Elemental Fury", 5, 1, 1, {"crit_dmg": 25}],
		["lightning_mastery", "Lightning Mastery", 5, 2, 5, {"haste": 2}],
		["elemental_mastery", "Elemental Mastery", 6, 1, 1, {"ability": "elemental_mastery"}],
		["totem_of_wrath", "Totem of Wrath", 7, 1, 1, {"party_crit": 3, "priest_regen": 8}, "elemental_mastery"],
	],
	"shaman_enhancement": [
		["guardian_totems", "Guardian Totems", 0, 0, 2, {"party_mit": 1}],
		["thundering_strikes", "Thundering Strikes", 0, 1, 5, {"crit": 1}],
		["earth_shock", "Earth Shock", 0, 2, 1, {"ability": "earth_shock"}],
		["enhancing_totems", "Enhancing Totems", 1, 0, 2, {"party_dps": 1}],
		["ancestral_knowledge", "Ancestral Knowledge", 1, 1, 5, {"str%": 2}],
		["imp_earth_shock", "Improved Earth Shock", 1, 2, 2, {"earth_shock.cd": -1, "earth_shock.dmg": 15}, "earth_shock"],
		["anticipation", "Anticipation", 2, 0, 5, {"dodge": 1}],
		["flurry", "Flurry", 2, 1, 5, {"haste": 2}],
		["flame_shock", "Flame Shock", 2, 2, 1, {"ability": "flame_shock"}],
		["toughness", "Toughness", 3, 0, 5, {"sta%": 2}],
		["imp_weapon_totems", "Improved Weapon Totems", 3, 1, 2, {"windfury_bonus": 1.5}],
		["elemental_weapons", "Elemental Weapons", 3, 2, 3, {"flame_shock.dmg": 5, "dps": 1}, "flame_shock"],
		["shamanistic_rage", "Shamanistic Rage", 4, 0, 1, {"ability": "shamanistic_rage"}],
		["weapon_mastery", "Weapon Mastery", 4, 1, 5, {"dps": 1}],
		["unleashed_rage", "Unleashed Rage", 5, 1, 5, {"party_dps": 0.4, "agi%": 1}],
		["stormstrike", "Stormstrike", 6, 1, 1, {"ability": "stormstrike"}],
		["imp_stormstrike", "Improved Stormstrike", 7, 1, 2, {"stormstrike.cd": -3}, "stormstrike"],
	],
	"rogue_assassination": [
		["kick", "Kick", 0, 0, 1, {"ability": "kick"}],
		["malice", "Malice", 0, 1, 5, {"crit": 1}],
		["eviscerate", "Eviscerate", 0, 2, 1, {"ability": "eviscerate"}],
		["imp_kick", "Improved Kick", 1, 0, 2, {"kick.cd": -2}, "kick"],
		["ruthlessness", "Ruthlessness", 1, 1, 3, {"dps": 1}],
		["imp_eviscerate", "Improved Eviscerate", 1, 2, 3, {"eviscerate.dmg": 5}, "eviscerate"],
		["lethality", "Lethality", 2, 0, 5, {"crit_dmg": 4}],
		["murder", "Murder", 2, 1, 2, {"dps": 2}],
		["rupture", "Rupture", 2, 2, 1, {"ability": "rupture"}],
		["relentless_strikes", "Relentless Strikes", 3, 1, 1, {"haste": 3}],
		["imp_rupture", "Improved Rupture", 3, 2, 3, {"rupture.dmg": 7}, "rupture"],
		["imp_poisons", "Improved Poisons", 4, 1, 5, {"boss": 1.5}],
		["cold_blood", "Cold Blood", 4, 2, 1, {"ability": "cold_blood"}],
		["vile_poisons", "Vile Poisons", 5, 1, 5, {"dps": 1}],
		["seal_fate", "Seal Fate", 5, 2, 5, {"crit": 0.6}, "cold_blood"],
		["vigor", "Vigor", 6, 1, 1, {"agi%": 3}],
		["master_poisoner", "Master Poisoner", 7, 1, 2, {"enemy_vuln": 1.5}, "vigor"],
	],
	"rogue_combat": [
		["kick", "Kick", 0, 0, 1, {"ability": "kick"}],
		["sinister_strike", "Sinister Strike", 0, 1, 1, {"ability": "sinister_strike"}],
		["lightning_reflexes", "Lightning Reflexes", 0, 2, 5, {"dodge": 1}],
		["imp_kick", "Improved Kick", 1, 0, 2, {"kick.cd": -2}, "kick"],
		["imp_sinister_strike", "Improved Sinister Strike", 1, 1, 2, {"sinister_strike.dmg": 10}, "sinister_strike"],
		["precision", "Precision", 1, 2, 5, {"dps": 0.6}],
		["endurance", "Endurance", 2, 0, 2, {"sta%": 3}],
		["deflection", "Deflection", 2, 1, 5, {"dodge": 1}],
		["dual_wield_spec", "Dual Wield Specialization", 2, 2, 5, {"dps": 1}],
		["blade_flurry", "Blade Flurry", 3, 0, 1, {"ability": "blade_flurry"}],
		["sword_spec", "Sword Specialization", 3, 2, 5, {"extra_attack": 1}],
		["imp_blade_flurry", "Improved Blade Flurry", 4, 0, 2, {"blade_flurry.dur": 3}, "blade_flurry"],
		["weapon_expertise", "Weapon Expertise", 4, 1, 2, {"agi%": 2}],
		["aggression", "Aggression", 4, 2, 3, {"sinister_strike.dmg": 5, "dps": 0.5}],
		["vitality", "Vitality", 5, 1, 2, {"sta%": 2, "agi%": 1}],
		["adrenaline_rush", "Adrenaline Rush", 6, 1, 1, {"ability": "adrenaline_rush"}],
		["combat_potency", "Combat Potency", 7, 1, 3, {"adrenaline_rush.dur": 2, "haste": 1}, "adrenaline_rush"],
	],
	"rogue_subtlety": [
		["kick", "Kick", 0, 0, 1, {"ability": "kick"}],
		["master_of_deception", "Master of Deception", 0, 1, 5, {"threat": 4}],
		["opportunity", "Opportunity", 0, 2, 5, {"dps": 1}],
		["imp_kick", "Improved Kick", 1, 0, 2, {"kick.cd": -2}, "kick"],
		["camouflage", "Camouflage", 1, 1, 5, {"opener": 2}],
		["initiative", "Initiative", 1, 2, 3, {"opener": 3}],
		["vanish", "Vanish", 2, 0, 1, {"ability": "vanish"}],
		["hemorrhage", "Hemorrhage", 2, 1, 1, {"ability": "hemorrhage"}],
		["elusiveness", "Elusiveness", 2, 2, 2, {"mit": 2}],
		["imp_vanish", "Improved Vanish", 3, 0, 2, {"vanish.cd": -10}, "vanish"],
		["serrated_blades", "Serrated Blades", 3, 1, 3, {"hemorrhage.pct": 1}, "hemorrhage"],
		["setup", "Setup", 3, 2, 3, {"haste": 1.5}],
		["kidney_shot", "Kidney Shot", 4, 1, 1, {"ability": "kidney_shot"}],
		["dirty_deeds", "Dirty Deeds", 4, 2, 2, {"execute": 8}],
		["sinister_calling", "Sinister Calling", 5, 0, 5, {"agi%": 3}],
		["cheat_death", "Cheat Death", 5, 2, 3, {"cheat_death": 33}],
		["premeditation", "Premeditation", 6, 1, 1, {"dps": 5, "opener": 10}],
		["imp_kidney_shot", "Improved Kidney Shot", 5, 1, 3, {"kidney_shot.dur": 0.5, "kidney_shot.cd": -1}, "kidney_shot"],
	],
	"hunter_beast_mastery": [
		["serpent_sting", "Serpent Sting", 0, 0, 1, {"ability": "serpent_sting"}],
		["imp_aspect_hawk", "Improved Aspect of the Hawk", 0, 1, 5, {"haste": 1}],
		["endurance_training", "Endurance Training", 0, 2, 5, {"sta%": 1}],
		["imp_serpent_sting", "Improved Serpent Sting", 1, 0, 5, {"serpent_sting.dmg": 4}, "serpent_sting"],
		["thick_hide", "Thick Hide", 1, 1, 3, {"mit": 1}],
		["unleashed_fury", "Unleashed Fury", 1, 2, 5, {"dps": 0.8}],
		["arcane_shot", "Arcane Shot", 2, 0, 1, {"ability": "arcane_shot"}],
		["ferocity", "Ferocity", 2, 1, 5, {"crit": 0.8}],
		["bestial_discipline", "Bestial Discipline", 2, 2, 2, {"dps": 1.5}],
		["imp_arcane_shot", "Improved Arcane Shot", 3, 0, 3, {"arcane_shot.cd": -0.3}, "arcane_shot"],
		["intimidation", "Intimidation", 3, 1, 1, {"ability": "intimidation"}],
		["frenzy", "Frenzy", 3, 2, 5, {"haste": 1.5}],
		["animal_handler", "Animal Handler", 4, 1, 2, {"intimidation.cd": -10}, "intimidation"],
		["bestial_wrath", "Bestial Wrath", 5, 1, 1, {"ability": "bestial_wrath"}],
		["ferocious_inspiration", "Ferocious Inspiration", 5, 2, 3, {"party_dps": 1}],
		["serpents_swiftness", "Serpent's Swiftness", 6, 2, 5, {"haste": 1}],
		["the_beast_within", "The Beast Within", 7, 1, 1, {"bestial_wrath.pct": 5, "bestial_wrath.dur": 2}, "bestial_wrath"],
	],
	"hunter_marksmanship": [
		["serpent_sting", "Serpent Sting", 0, 0, 1, {"ability": "serpent_sting"}],
		["efficiency", "Efficiency", 0, 1, 5, {"haste": 1}],
		["lethal_shots", "Lethal Shots", 0, 2, 5, {"crit": 1}],
		["imp_serpent_sting", "Improved Serpent Sting", 1, 0, 3, {"serpent_sting.dmg": 6}, "serpent_sting"],
		["aimed_shot", "Aimed Shot", 1, 1, 1, {"ability": "aimed_shot"}],
		["imp_hunters_mark", "Improved Hunter's Mark", 1, 2, 5, {"enemy_vuln": 0.6}],
		["multi_shot", "Multi-Shot", 2, 0, 1, {"ability": "multi_shot"}],
		["mortal_shots", "Mortal Shots", 4, 2, 5, {"crit_dmg": 6}],
		["scatter_shot", "Scatter Shot", 2, 2, 1, {"ability": "scatter_shot"}],
		["barrage", "Barrage", 3, 0, 3, {"multi_shot.dmg": 10}, "multi_shot"],
		["careful_aim", "Careful Aim", 3, 1, 3, {"agi%": 2}],
		["ranged_weapon_spec", "Ranged Weapon Specialization", 3, 2, 5, {"dps": 1}],
		["rapid_fire", "Rapid Fire", 4, 1, 1, {"ability": "rapid_fire"}],
		["imp_aimed_shot", "Improved Aimed Shot", 2, 1, 3, {"aimed_shot.dmg": 5}, "aimed_shot"],
		["rapid_killing", "Rapid Killing", 5, 1, 2, {"rapid_fire.cd": -60}, "rapid_fire"],
		["master_marksman", "Master Marksman", 5, 2, 5, {"crit": 1}],
		["trueshot_aura", "Trueshot Aura", 6, 1, 1, {"party_dps": 3}],
		["silencing_shot", "Silencing Shot", 7, 2, 1, {"scatter_shot.cd": -15}],
	],
	"hunter_survival": [
		["serpent_sting", "Serpent Sting", 0, 0, 1, {"ability": "serpent_sting"}],
		["monster_slaying", "Monster Slaying", 0, 1, 3, {"boss": 1}],
		["deflection", "Deflection", 0, 2, 5, {"dodge": 1}],
		["explosive_trap", "Explosive Trap", 1, 0, 1, {"ability": "explosive_trap"}],
		["savage_strikes", "Savage Strikes", 1, 1, 2, {"crit": 3}],
		["survivalist", "Survivalist", 1, 2, 5, {"sta%": 2}],
		["trap_mastery", "Trap Mastery", 2, 0, 2, {"explosive_trap.cd": -5, "explosive_trap.dmg": 10}, "explosive_trap"],
		["entrapment", "Entrapment", 2, 1, 5, {"enemy_dmg": 0.5}],
		["deterrence", "Deterrence", 2, 2, 1, {"ability": "deterrence"}],
		["killer_instinct", "Killer Instinct", 3, 1, 3, {"crit": 1.5}],
		["imp_deterrence", "Improved Deterrence", 3, 2, 2, {"deterrence.cd": -60}, "deterrence"],
		["lightning_reflexes", "Lightning Reflexes", 4, 1, 5, {"agi%": 4}],
		["wyvern_sting", "Wyvern Sting", 5, 1, 1, {"ability": "wyvern_sting"}],
		["expose_weakness", "Expose Weakness", 5, 2, 3, {"enemy_vuln": 1}],
		["thrill_of_the_hunt", "Thrill of the Hunt", 6, 2, 3, {"dps": 2.5}],
		["readiness", "Readiness", 7, 1, 1, {"wyvern_sting.cd": -20, "explosive_trap.cd": -5}, "wyvern_sting"],
	],
	"mage_arcane": [
		["arcane_subtlety", "Arcane Subtlety", 0, 0, 2, {"threat": 10}],
		["arcane_focus", "Arcane Focus", 0, 1, 5, {"dps": 1}],
		["arcane_missiles", "Arcane Missiles", 0, 2, 1, {"ability": "arcane_missiles"}],
		["counterspell", "Counterspell", 1, 0, 1, {"ability": "counterspell"}],
		["arcane_concentration", "Arcane Concentration", 1, 1, 5, {"dps": 1.4}],
		["imp_arcane_missiles", "Improved Arcane Missiles", 1, 2, 5, {"arcane_missiles.dmg": 3}, "arcane_missiles"],
		["imp_counterspell", "Improved Counterspell", 2, 0, 2, {"counterspell.cd": -4}, "counterspell"],
		["arcane_explosion", "Arcane Explosion", 2, 1, 1, {"ability": "arcane_explosion"}],
		["magic_absorption", "Magic Absorption", 2, 2, 5, {"mit": 1}],
		["imp_arcane_explosion", "Improved Arcane Explosion", 3, 1, 3, {"arcane_explosion.dmg": 10}, "arcane_explosion"],
		["arcane_mind", "Arcane Mind", 3, 2, 5, {"int%": 2}],
		["arcane_instability", "Arcane Instability", 4, 1, 3, {"crit": 1, "dps": 1.5}],
		["arcane_brilliance", "Arcane Brilliance", 4, 2, 1, {"priest_mana": 6}],
		["arcane_potency", "Arcane Potency", 5, 1, 3, {"crit_dmg": 8}],
		["arcane_power", "Arcane Power", 6, 1, 1, {"ability": "arcane_power"}],
		["empowered_arcane_missiles", "Empowered Arcane Missiles", 7, 1, 3, {"arcane_missiles.dmg": 5, "arcane_power.dur": 1}, "arcane_power"],
	],
	"mage_fire": [
		["fire_blast", "Fire Blast", 0, 0, 1, {"ability": "fire_blast"}],
		["imp_fireball", "Improved Fireball", 0, 1, 5, {"haste": 1.5}],
		["impact", "Impact", 0, 2, 5, {"dps": 0.4}],
		["imp_fire_blast", "Improved Fire Blast", 1, 0, 3, {"fire_blast.cd": -0.5}, "fire_blast"],
		["ignite", "Ignite", 1, 1, 5, {"crit_dmg": 6}],
		["counterspell", "Counterspell", 1, 2, 1, {"ability": "counterspell"}],
		["flame_throwing", "Flame Throwing", 2, 0, 2, {"threat": 6}],
		["pyroblast", "Pyroblast", 2, 1, 1, {"ability": "pyroblast"}],
		["burning_soul", "Burning Soul", 2, 2, 2, {"mit": 2}],
		["imp_scorch", "Improved Scorch", 3, 0, 3, {"enemy_vuln": 1}],
		["imp_pyroblast", "Improved Pyroblast", 3, 1, 2, {"pyroblast.cd": -2}, "pyroblast"],
		["master_of_elements", "Master of Elements", 3, 2, 3, {"dps": 1}],
		["critical_mass", "Critical Mass", 4, 1, 3, {"crit": 1.5}],
		["blast_wave", "Blast Wave", 5, 0, 1, {"ability": "blast_wave"}],
		["fire_power", "Fire Power", 5, 2, 5, {"dps": 1}],
		["combustion", "Combustion", 6, 1, 1, {"ability": "combustion"}],
		["dragons_breath", "Dragon's Breath", 7, 0, 1, {"blast_wave.dmg": 30}, "blast_wave"],
	],
	"mage_frost": [
		["frost_warding", "Frost Warding", 0, 0, 2, {"mit": 1.5}],
		["imp_frostbolt", "Improved Frostbolt", 0, 1, 5, {"haste": 1.5}],
		["counterspell", "Counterspell", 0, 2, 1, {"ability": "counterspell"}],
		["ice_shards", "Ice Shards", 1, 0, 5, {"crit_dmg": 5}],
		["frost_nova", "Frost Nova", 1, 1, 1, {"ability": "frost_nova"}],
		["elemental_precision", "Elemental Precision", 1, 2, 3, {"dps": 1}],
		["piercing_ice", "Piercing Ice", 2, 0, 3, {"dps": 1.5}],
		["imp_frost_nova", "Improved Frost Nova", 2, 1, 2, {"frost_nova.cd": -4}, "frost_nova"],
		["cone_of_cold", "Cone of Cold", 2, 2, 1, {"ability": "cone_of_cold"}],
		["arctic_reach", "Arctic Reach", 3, 0, 2, {"threat": 5}],
		["shatter", "Shatter", 3, 1, 5, {"crit": 1}],
		["imp_cone_of_cold", "Improved Cone of Cold", 3, 2, 3, {"cone_of_cold.dmg": 8}, "cone_of_cold"],
		["frost_channeling", "Frost Channeling", 4, 0, 3, {"dps": 1}],
		["ice_block", "Ice Block", 4, 1, 1, {"ability": "ice_block"}],
		["winters_chill", "Winter's Chill", 4, 2, 5, {"enemy_vuln": 0.4}],
		["arctic_winds", "Arctic Winds", 5, 1, 5, {"dps": 0.6, "mit": 1}],
		["ice_barrier", "Ice Barrier", 6, 1, 1, {"ability": "ice_barrier"}],
		["imp_ice_barrier", "Improved Ice Barrier", 7, 1, 2, {"ice_barrier.pct": 3}, "ice_barrier"],
	],
	"warlock_affliction": [
		["corruption", "Corruption", 0, 0, 1, {"ability": "corruption"}],
		["suppression", "Suppression", 0, 1, 5, {"dps": 1}],
		["curse_of_weakness", "Curse of Weakness", 0, 2, 1, {"ability": "curse_of_weakness"}],
		["imp_corruption", "Improved Corruption", 1, 0, 5, {"corruption.dmg": 6}, "corruption"],
		["imp_life_tap", "Improved Life Tap", 1, 1, 2, {"sta%": 2}],
		["imp_curse_of_weakness", "Improved Curse of Weakness", 1, 2, 3, {"curse_of_weakness.pct": 1}, "curse_of_weakness"],
		["imp_drain_life", "Improved Drain Life", 2, 0, 5, {"leech": 1}],
		["curse_of_agony", "Curse of Agony", 2, 1, 1, {"ability": "curse_of_agony"}],
		["grim_reach", "Grim Reach", 2, 2, 2, {"threat": 5}],
		["amplify_curse", "Amplify Curse", 3, 0, 1, {"curse_of_weakness.pct": 3}],
		["imp_curse_of_agony", "Improved Curse of Agony", 3, 1, 3, {"curse_of_agony.dmg": 10}, "curse_of_agony"],
		["nightfall", "Nightfall", 3, 2, 2, {"crit": 2}],
		["siphon_life", "Siphon Life", 4, 1, 1, {"ability": "siphon_life"}],
		["shadow_mastery", "Shadow Mastery", 5, 1, 5, {"dps": 1.5}],
		["dark_pact", "Dark Pact", 5, 2, 1, {"priest_regen": 10}],
		["contagion", "Contagion", 6, 1, 5, {"corruption.dmg": 3, "curse_of_agony.dmg": 3}],
		["unstable_affliction", "Unstable Affliction", 7, 1, 1, {"siphon_life.dmg": 30, "dps": 2}, "contagion"],
	],
	"warlock_demonology": [
		["imp_healthstone", "Improved Healthstone", 0, 0, 2, {"healthstone_bonus": 10}],
		["imp_imp", "Improved Imp", 0, 1, 3, {"party_hp": 1}],
		["demonic_embrace", "Demonic Embrace", 0, 2, 5, {"sta%": 3}],
		["immolate", "Immolate", 1, 0, 1, {"ability": "immolate"}],
		["imp_voidwalker", "Improved Voidwalker", 1, 1, 3, {"mit": 1}],
		["fel_intellect", "Fel Intellect", 1, 2, 5, {"int%": 1, "priest_mana": 1}],
		["imp_immolate", "Improved Immolate", 2, 0, 3, {"immolate.dmg": 8}, "immolate"],
		["spell_lock", "Spell Lock", 2, 1, 1, {"ability": "spell_lock"}],
		["unholy_power", "Unholy Power", 2, 2, 5, {"dps": 1.5}],
		["master_summoner", "Master Summoner", 3, 0, 2, {"opener": 5}],
		["fel_domination", "Fel Domination", 3, 1, 2, {"spell_lock.cd": -6}, "spell_lock"],
		["death_coil", "Death Coil", 3, 2, 1, {"ability": "death_coil"}],
		["curse_of_recklessness", "Curse of Recklessness", 4, 0, 1, {"ability": "curse_of_recklessness"}],
		["demonic_sacrifice", "Demonic Sacrifice", 4, 1, 1, {"dps": 6}],
		["master_demonologist", "Master Demonologist", 5, 1, 5, {"enemy_dmg": 0.6}],
		["soul_link", "Soul Link", 6, 1, 1, {"mit": 5}],
		["summon_felguard", "Summon Felguard", 7, 1, 1, {"dps": 4, "spell_lock.cd": -4}, "soul_link"],
	],
	"warlock_destruction": [
		["immolate", "Immolate", 0, 0, 1, {"ability": "immolate"}],
		["imp_shadow_bolt", "Improved Shadow Bolt", 0, 1, 5, {"enemy_vuln": 0.6}],
		["cataclysm", "Cataclysm", 0, 2, 5, {"dps": 0.6}],
		["imp_immolate", "Improved Immolate", 1, 0, 5, {"immolate.dmg": 5}, "immolate"],
		["bane", "Bane", 1, 1, 5, {"haste": 1.5}],
		["aftermath", "Aftermath", 1, 2, 5, {"enemy_dmg": 0.4}],
		["intensity", "Intensity", 2, 0, 2, {"mit": 1}],
		["devastation", "Devastation", 2, 1, 5, {"crit": 1}],
		["shadowburn", "Shadowburn", 2, 2, 1, {"ability": "shadowburn"}],
		["rain_of_fire", "Rain of Fire", 3, 0, 1, {"ability": "rain_of_fire"}],
		["imp_searing_pain", "Improved Searing Pain", 3, 1, 5, {"crit": 0.6}],
		["imp_shadowburn", "Improved Shadowburn", 3, 2, 2, {"shadowburn.cd": -3}, "shadowburn"],
		["ruin", "Ruin", 4, 1, 1, {"crit_dmg": 25}],
		["curse_of_elements", "Curse of the Elements", 4, 2, 1, {"ability": "curse_of_elements"}],
		["emberstorm", "Emberstorm", 5, 1, 5, {"dps": 1.5}],
		["conflagrate", "Conflagrate", 6, 1, 1, {"ability": "conflagrate"}],
		["backlash", "Backlash", 7, 1, 3, {"conflagrate.dmg": 6, "crit": 1}, "conflagrate"],
	],
	"druid_balance": [
		["moonfire", "Moonfire", 0, 0, 1, {"ability": "moonfire"}],
		["imp_wrath", "Improved Wrath", 0, 1, 5, {"haste": 1}],
		["natures_grasp", "Nature's Grasp", 0, 2, 1, {"mit": 2}],
		["imp_moonfire", "Improved Moonfire", 1, 0, 2, {"moonfire.dmg": 10}, "moonfire"],
		["natural_weapons", "Natural Weapons", 1, 1, 5, {"dps": 1}],
		["faerie_fire", "Faerie Fire", 1, 2, 1, {"ability": "faerie_fire"}],
		["natural_shapeshifter", "Natural Shapeshifter", 2, 0, 3, {"threat": 4}],
		["starfire", "Starfire", 2, 1, 1, {"ability": "starfire"}],
		["imp_faerie_fire", "Improved Faerie Fire", 2, 2, 3, {"faerie_fire.pct": 1}, "faerie_fire"],
		["imp_starfire", "Improved Starfire", 3, 1, 5, {"starfire.cd": -0.25}, "starfire"],
		["vengeance", "Vengeance", 3, 2, 5, {"crit_dmg": 8}],
		["insect_swarm", "Insect Swarm", 4, 0, 1, {"ability": "insect_swarm"}],
		["moonglow", "Moonglow", 4, 1, 3, {"priest_regen": 2}],
		["lunar_guidance", "Lunar Guidance", 4, 2, 3, {"int%": 2}],
		["hurricane", "Hurricane", 5, 1, 1, {"ability": "hurricane"}],
		["moonfury", "Moonfury", 5, 2, 5, {"dps": 1.5}],
		["moonkin_form", "Moonkin Form", 6, 1, 1, {"party_crit": 3, "mit": 5}],
		["force_of_nature", "Force of Nature", 7, 1, 1, {"hurricane.dmg": 25, "dps": 3}, "moonkin_form"],
	],
	"druid_feral": [
		["growl", "Growl", 0, 0, 1, {"ability": "growl"}],
		["ferocity", "Ferocity", 0, 1, 5, {"aggro": 0.6}],
		["thick_hide", "Thick Hide", 0, 2, 5, {"mit": 1.5}],
		["feral_instinct", "Feral Instinct", 1, 0, 5, {"aggro": 0.6, "growl.cd": -0.6}, "growl"],
		["maul", "Maul", 1, 1, 1, {"ability": "maul"}],
		["sharpened_claws", "Sharpened Claws", 1, 2, 3, {"crit": 2}],
		["demoralizing_roar", "Demoralizing Roar", 2, 0, 1, {"ability": "demoralizing_roar"}],
		["savage_fury", "Savage Fury", 2, 1, 2, {"maul.dmg": 12}, "maul"],
		["swipe", "Swipe", 2, 2, 1, {"ability": "swipe"}],
		["feral_aggression", "Feral Aggression", 3, 0, 5, {"demoralizing_roar.pct": 1}, "demoralizing_roar"],
		["predatory_strikes", "Predatory Strikes", 3, 1, 3, {"str%": 2}],
		["primal_fury", "Primal Fury", 3, 2, 2, {"swipe.dmg": 20}, "swipe"],
		["frenzied_regeneration", "Frenzied Regeneration", 4, 0, 1, {"ability": "frenzied_regeneration"}],
		["heart_of_the_wild", "Heart of the Wild", 4, 1, 5, {"sta%": 2}],
		["survival_of_the_fittest", "Survival of the Fittest", 5, 1, 3, {"mit": 1}],
		["leader_of_the_pack", "Leader of the Pack", 6, 1, 1, {"party_crit": 3}],
		["imp_leader_of_the_pack", "Improved Leader of the Pack", 7, 1, 2, {"leech": 1.5, "frenzied_regeneration.pct": 5}, "leader_of_the_pack"],
	],
	"druid_cat": [
		["rake", "Rake", 0, 0, 1, {"ability": "rake"}],
		["ferocity", "Ferocity", 0, 1, 5, {"dps": 0.6}],
		["feral_instinct", "Feral Instinct", 0, 2, 5, {"threat": 4}],
		["savage_fury", "Savage Fury", 1, 0, 2, {"rake.dmg": 12}, "rake"],
		["shred", "Shred", 1, 1, 1, {"ability": "shred"}],
		["sharpened_claws", "Sharpened Claws", 1, 2, 3, {"crit": 2}],
		["blood_frenzy", "Blood Frenzy", 2, 0, 2, {"haste": 3}],
		["imp_shred", "Improved Shred", 2, 1, 2, {"shred.dmg": 10}, "shred"],
		["predatory_strikes", "Predatory Strikes", 2, 2, 3, {"str%": 2}],
		["ferocious_bite", "Ferocious Bite", 3, 0, 1, {"ability": "ferocious_bite"}],
		["primal_fury", "Primal Fury", 3, 1, 2, {"dps": 1.5}],
		["faerie_fire_feral", "Faerie Fire (Feral)", 3, 2, 1, {"enemy_vuln": 2}],
		["feral_aggression", "Feral Aggression", 4, 0, 5, {"ferocious_bite.dmg": 6}, "ferocious_bite"],
		["heart_of_the_wild", "Heart of the Wild", 4, 1, 5, {"str%": 1}],
		["tigers_fury", "Tiger's Fury", 5, 1, 1, {"ability": "tigers_fury"}],
		["leader_of_the_pack", "Leader of the Pack", 6, 1, 1, {"party_crit": 3}],
		["mangle", "Mangle", 7, 1, 1, {"enemy_vuln": 3, "shred.dmg": 10}, "leader_of_the_pack"],
	],
}

## Recruits arrive with 2 traits from their role's list (always good)...
const TRAITS := {
	"melee": [["Ferocious", {"crit": 3}], ["Relentless", {"haste": 4}], ["Brutal", {"crit_dmg": 12}], ["Executioner", {"execute": 15}],
		["Duelist", {"dodge": 4}], ["Bloodthirsty", {"leech": 2}], ["Opportunist", {"opener": 12}], ["Cleaver", {"aoe": 10}],
		["Giant Slayer", {"boss": 5}], ["Interrupter", {"interrupt": 15}], ["Mighty", {"str%": 6}], ["Lithe", {"agi%": 6}]],
	"ranged": [["Deadeye", {"crit": 3}], ["Quickdraw", {"haste": 4}], ["Devastating", {"crit_dmg": 12}], ["Finisher", {"execute": 15}],
		["Elusive", {"threat": 15}], ["Siphoner", {"leech": 2}], ["Ambusher", {"opener": 12}], ["Barrage", {"aoe": 10}],
		["Giant Slayer", {"boss": 5}], ["Spellbreaker", {"interrupt": 15}]],
	"tank": [["Stalwart", {"mit": 4}], ["Hulking", {"sta%": 10}], ["Taunting", {"aggro": 4}], ["Nimble", {"dodge": 4}],
		["Intimidating", {"enemy_dmg": 3}], ["Unyielding", {"last_stand": 20}], ["Sunderer", {"enemy_vuln": 2}],
		["Bulwark", {"party_mit": 2}], ["Interrupter", {"interrupt": 15}], ["Bloodthirsty", {"leech": 2}]],
}

## ...and up to 2 affixes, which can be good or bad.
const AFFIXES_GOOD := [["Sturdy", {"sta%": 8}], ["Keen", {"crit": 2}], ["Swift", {"haste": 3}], ["Inspiring", {"party_dps": 1}],
	["Wise", {"priest_regen": 4}], ["Tough", {"mit": 3}], ["Focused", {"dps": 3}], ["Lucky", {"cheat_death": 25}]]
const AFFIXES_BAD := [["Frail", {"sta%": -8}], ["Clumsy", {"crit": -2}], ["Sluggish", {"haste": -3}], ["Reckless", {"threat": -15}],
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


static func req(t: Array) -> String:
	return t[6] if t.size() > 6 else ""


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
	var r := req(t)
	if r != "" and talents.get(r, 0) < find(spec_id, r)[4]:
		return false
	return spent(talents) >= t[2] * POINTS_PER_TIER


## Fills unspent points: abilities first whenever one is reachable, otherwise tree order.
static func auto_build(spec_id: String, talents: Dictionary, level: int) -> Dictionary:
	var out := {}
	for k in talents:
		if not find(spec_id, k).is_empty():
			out[k] = talents[k]
	var progress := true
	while progress and spent(out) < points_at(level):
		progress = false
		var pick := ""
		for t in tree(spec_id):
			if can_learn(spec_id, out, t[0], level):
				if t[5].has("ability"):
					pick = t[0]
					break
				if pick == "":
					pick = t[0]
		if pick != "":
			out[pick] = out.get(pick, 0) + 1
			progress = true
	return out


## The abilities a guildmate has from their talents, improved by their other talents, in priority order.
static func abilities_for(spec_id: String, talents: Dictionary, mods: Dictionary) -> Array:
	var out := []
	for t in tree(spec_id):
		if talents.get(t[0], 0) <= 0 or not t[5].has("ability"):
			continue
		var id: String = t[5]["ability"]
		var a: Dictionary = ABILITIES[id].duplicate(true)
		a["id"] = id
		a["cd"] = maxf(1.0, a["cd"] + mods.get(id + ".cd", 0.0))
		if a.has("coef"):
			a["coef"] *= 1.0 + mods.get(id + ".dmg", 0.0) / 100.0
		if a.has("dur"):
			a["dur"] += mods.get(id + ".dur", 0.0)
		if mods.has(id + ".pct"):
			if a.has("pct"):
				a["pct"] += mods[id + ".pct"]
			if a.has("debuff"):
				for k in ["vuln", "weaken"]:
					if a["debuff"].has(k):
						a["debuff"][k] += mods[id + ".pct"]
		out.append(a)
	out.sort_custom(func(x, y): return _priority(x) < _priority(y))
	return out


static func _priority(a: Dictionary) -> int:
	var i := PRIORITY.find(a["kind"])
	return i if i >= 0 else PRIORITY.size()


static func ability_value(abilities: Array) -> float:
	var v := 0.0
	for a in abilities:
		v += ABILITY_VALUE.get(a["kind"], 0.03)
	return v


## Damage per second (in seconds of the guildmate's damage) their abilities deal at base values.
## Auto attacks are scaled down by 1 / (1 + share) so a fresh ability moves damage rather than adding it;
## talents that improve the ability are pure gain.
static func damage_share(abilities: Array) -> float:
	var s := 0.0
	for a in abilities:
		var base: Dictionary = ABILITIES.get(a["id"], {})
		if base.has("coef"):
			s += base["coef"] / base["cd"] * SHARE.get(base["kind"], 0.0)
	return s


## What an ability does, in a sentence, with its numbers.
static func ability_text(a: Dictionary) -> String:
	var dmg := "%d%% of their damage per second" % int(round(a.get("coef", 0.0) * 100.0))
	var cd := " %s sec cooldown." % number(a["cd"])
	match a["kind"]:
		"strike":
			var s := "Strikes the target for %s." % dmg
			if a.has("leech"):
				s += " Heals them for %d%% of it." % int(a["leech"])
			if a.has("debuff"):
				s += " " + _debuff_text(a["debuff"])
			return s + cd + " Used on cooldown."
		"dot":
			var s := "Deals %s over %s sec." % [dmg, number(a["dur"])]
			if a.has("leech"):
				s += " Heals them for the damage dealt."
			if a.has("debuff"):
				s += " " + _debuff_text(a["debuff"])
			return s + cd + " Kept up on their target."
		"aoe":
			var s := "Hits up to %d enemies, each for %s." % [a.get("max", 6), dmg]
			if a.has("debuff"):
				s += " " + _debuff_text(a["debuff"])
			return s + cd + (" Used when 2 or more enemies stand, or to keep its effect up." if a.has("debuff") else " Used when 2 or more enemies stand.")
		"execute":
			return "Strikes a target below %d%% health for %s.%s" % [int(a["at"] * 100.0), dmg, cd]
		"burst":
			return "%s for %s sec.%s Used on cooldown." % [burst_effects(a), number(a["dur"]), cd]
		"debuff", "debuff_all":
			var who := "every enemy" if a["kind"] == "debuff_all" else "the target"
			return "Curses %s for %s sec: %s%s Kept up." % [who, number(a["dur"]), _debuff_text(a["debuff"]), cd]
		"stun":
			return "Stuns an enemy for %s sec (bosses are immune).%s" % [number(a["dur"]), cd]
		"stun_all":
			return "Freezes every enemy in place for %s sec (bosses are immune).%s Used when 2 or more stand." % [number(a["dur"]), cd]
		"interrupt":
			var s := "Interrupts an enemy spell as it begins."
			if a.has("coef"):
				s += " Also hits for %s." % dmg
			return s + cd
		"taunt":
			return "Forces an enemy attacking someone else to attack them instead.%s" % cd
		"defensive":
			var red := "takes no damage" if a["pct"] >= 100.0 else "takes %d%% less damage" % int(a["pct"])
			return "Below %d%% health: %s for %s sec.%s" % [int(a["at"] * 100.0), red, number(a["dur"]), cd]
		"self_heal":
			return "Below %d%% health: heals %d%% of their health.%s" % [int(a["at"] * 100.0), int(a["pct"]), cd]
		"shield":
			return "Shields themselves for %d%% of their health.%s Kept up." % [int(a["pct"]), cd]
		"feign":
			return "Below %d%% health while attacked: drops every enemy's attention.%s" % [int(a["at"] * 100.0), cd]
	return ""


## "+20% damage, +50% attack speed": what a burst ability gives while it lasts.
static func burst_effects(a: Dictionary) -> String:
	var parts := []
	if a.has("pct"):
		parts.append("+%d%% damage" % int(a["pct"]))
	if a.has("haste"):
		parts.append("+%d%% attack speed" % int(a["haste"]))
	if a.has("crit"):
		parts.append("+%d%% critical strike chance" % int(a["crit"]))
	if a.has("aoe"):
		parts.append("+%d%% damage while 2 or more enemies stand" % int(a["aoe"]))
	return ", ".join(parts)


static func _debuff_text(d: Dictionary) -> String:
	if d.has("vuln"):
		return "Enemies affected take %s%% more damage." % number(d["vuln"])
	if d.has("weaken"):
		return "Enemies affected deal %s%% less damage." % number(d["weaken"])
	if d.has("anti_heal"):
		return "Healing on the target is reduced by %d%%." % int(d["anti_heal"])
	return ""


static func number(v: float) -> String:
	return str(int(round(v))) if absf(v - roundf(v)) < 0.05 else "%.1f" % v


## "+5% Strength", "-1 sec Taunt cooldown"; a negative value (bad affix) flips the template's sign.
static func effect_text(key: String, value: float) -> String:
	if key.contains("."):
		var ab: String = ABILITIES.get(key.get_slice(".", 0), {}).get("name", key.get_slice(".", 0))
		match key.get_slice(".", 1):
			"dmg":
				return "+%s%% %s damage" % [number(value), ab]
			"cd":
				return "%s sec %s cooldown" % [("-" if value < 0.0 else "+") + number(absf(value)), ab]
			"dur":
				return "+%s sec %s duration" % [number(value), ab]
			"pct":
				return "+%s%% %s effect" % [number(value), ab]
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
		if k == "ability":
			parts.append("Grants the %s ability" % ABILITIES[effects[k]]["name"])
		else:
			parts.append(effect_text(k, effects[k]))
	return ", ".join(parts)


## Adds `effects` scaled by `times` into `into` (the "ability" grant isn't a number and is skipped).
static func add_effects(into: Dictionary, effects: Dictionary, times := 1.0) -> void:
	for k in effects:
		if k == "ability":
			continue
		into[k] = into.get(k, 0.0) + effects[k] * times


## Power bonus (as a fraction) that a set of effects is worth.
static func power_value(mods: Dictionary) -> float:
	var v := 0.0
	for k in mods:
		var key := String(k)
		if key.contains("."):
			v += _ability_mod_value(key, mods[k])
		else:
			v += mods[k] * WEIGHTS.get(key, 0.0)
	return v / 100.0


## Rough worth of an ability improvement: a few % of damage for the ability's share of it.
static func _ability_mod_value(key: String, value: float) -> float:
	var a: Dictionary = ABILITIES.get(key.get_slice(".", 0), {})
	if a.is_empty():
		return 0.0
	match key.get_slice(".", 1):
		"dmg":
			return value * 0.12
		"cd":
			return -value / a["cd"] * 100.0 * 0.12
		"dur":
			return value / a.get("dur", 10.0) * 100.0 * 0.1
		"pct":
			return value * 0.6
	return 0.0
