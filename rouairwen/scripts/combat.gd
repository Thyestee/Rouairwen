class_name Combat
## The turn-based fight at the end of a quest: the party of three against the quest's foes.
##
## Each round, every living party member acts in turn (a spell from their kit, or their basic attack),
## then every living foe acts. Damage and healing over time tick at the end of the round.
## The party wins when every foe is down. It loses if all three fall, or if the foes are still
## standing after MAX_ROUNDS.
##
## Party members choose their action by priority: heal anyone badly hurt (healers and anyone with
## a heal), taunt if they're a tank and nobody holds the foes, keep their buffs up, then deal as much
## damage as they can. Foes attack whoever taunted them, otherwise usually the tank.

const MAX_ROUNDS := 25
const FAVOURED_BONUS := 1.2  # members of a favoured spec fight with this much more health and potency
const CRIT_MULT := 1.5
const HEAL_THRESHOLD := 0.7  # heal allies below this share of their health
const TANK_AGGRO := 0.75  # chance a foe goes for a living tank when nobody taunts
const EXECUTE_THRESHOLD := 0.25
const EXECUTE_MULT := 2.5

## Foe strength per quest level, before the quest's difficulty and each foe's share.
## Sized so an at-level party of average C-tier members usually wins in about 8 rounds.
const FOE_HP := 760.0
const FOE_HP_GROWTH := 0.167
const FOE_ATTACK := 90.0
const FOE_ATTACK_GROWTH := 0.11
const FOE_ARMOR := 0.08  # share of damage foes shrug off (bosses a little more)

## How strong foe abilities are, relative to a normal attack.
const ABILITY_AOE := 0.7
const ABILITY_HEAVY := 2.2
const ABILITY_HEAL := 0.15  # share of max health
const ENRAGE_AT := 0.3
const ENRAGE_MULT := 1.5


## Fights it out. With `record`, the result holds a turn-by-turn log for replays:
## {"victory": bool, "rounds": int, "units": [{"name", "side", "max_hp", "class_id"}],
##  "log": [{"text": String, "hp": [health of every unit after this step]}]}
## `bonus` is extra health and potency for the whole party (the guild's Training Grounds).
static func simulate(party: Array, quest: Dictionary, favoured: Array, record := true, bonus := 0.0) -> Dictionary:
	var units := []
	for fighter in party:
		units.append(_party_unit(fighter, Fighters.spec_key(fighter) in favoured, bonus))
	for foe in quest.foes:
		units.append(_foe_unit(foe, quest))
	var state := {
		"units": units, "log": [], "record": record, "round": 0,
		"buff": 0.0, "buff_turns": 0, "weaken": 1.0, "weaken_turns": 0, "taunter": null, "taunt_turns": 0,
	}
	_log(state, "The party engages %s." % _foe_names(units))

	var victory := false
	while state.round < MAX_ROUNDS and not victory and not _side_down(state, "party"):
		state.round += 1
		_log(state, "Round %d" % state.round)
		for unit in units:
			if unit.side == "party" and unit.hp > 0.0:
				_party_act(unit, state)
				if _side_down(state, "foe"):
					victory = true
					break
		if victory:
			break
		for unit in units:
			if unit.side == "foe" and unit.hp > 0.0 and not _side_down(state, "party"):
				_foe_act(unit, state)
		_end_of_round(state)
		victory = _side_down(state, "foe")

	if victory:
		_log(state, "Victory! The foes are defeated.")
	elif _side_down(state, "party"):
		_log(state, "Defeat. The whole party has fallen.")
	else:
		_log(state, "Defeat. The foes outlasted the party.")

	var summary := []
	for unit in units:
		summary.append({"name": unit.name, "side": unit.side, "max_hp": roundi(unit.max_hp), "class_id": unit.get("class_id", "")})
	return {"victory": victory, "rounds": state.round, "units": summary, "log": state.log}


## Share of `runs` simulated fights the party wins, to show the odds before sending them.
static func estimate(party: Array, quest: Dictionary, favoured: Array, runs := 60, bonus := 0.0) -> float:
	var wins := 0
	for i in runs:
		if simulate(party, quest, favoured, false, bonus).victory:
			wins += 1
	return float(wins) / runs


## Foe stats for a quest, as shown on the quest board.
static func foe_stats(foe: Dictionary, quest: Dictionary) -> Dictionary:
	var level: float = quest.level
	var scale: float = quest.difficulty * foe.share
	return {
		"hp": FOE_HP * (1.0 + FOE_HP_GROWTH * (level - 1.0)) * scale,
		"attack": FOE_ATTACK * (1.0 + FOE_ATTACK_GROWTH * (level - 1.0)) * scale,
	}


# --- Setup ---

static func _party_unit(fighter: Dictionary, favoured: bool, guild_bonus: float) -> Dictionary:
	var profile := Fighters.combat_profile(fighter)
	var bonus := (FAVOURED_BONUS if favoured else 1.0) * (1.0 + guild_bonus)
	var spells := []
	for spell in Spells.kit_of(fighter):
		spells.append({"spell": spell, "cd": 0})
	return {
		"name": fighter.name, "side": "party", "class_id": fighter.class_id, "role": Fighters.spec_of(fighter).role,
		"max_hp": profile.hp * bonus, "hp": profile.hp * bonus, "potency": profile.potency * bonus,
		"crit": profile.crit, "dodge": profile.dodge, "dr": profile.dr,
		"spells": spells, "basic": Spells.basic_attack(fighter.class_id),
		"shield": 0.0, "empower": 0.0, "empower_turns": 0, "defend": 1.0, "defend_turns": 0,
		"stun": 0, "dots": [], "hots": [],
	}


static func _foe_unit(foe: Dictionary, quest: Dictionary) -> Dictionary:
	var stats := foe_stats(foe, quest)
	var boss: bool = foe.get("boss", false)
	return {
		"name": foe.name, "side": "foe", "max_hp": stats.hp, "hp": stats.hp, "attack": stats.attack,
		"dr": FOE_ARMOR + (0.05 if boss else 0.0), "dodge": 0.0, "ability": foe.get("ability", {}),
		"enraged": false, "shield": 0.0, "defend": 1.0, "stun": 0, "dots": [], "hots": [],
	}


# --- Party turns ---

static func _party_act(unit: Dictionary, state: Dictionary) -> void:
	var spell := _choose(unit, state)
	_cast(unit, spell, state)
	for entry in unit.spells:
		if is_same(entry.spell, spell):
			entry.cd = spell.cd + 1  # counts down at the end of this turn too
		if entry.cd > 0:
			entry.cd -= 1


static func _choose(unit: Dictionary, state: Dictionary) -> Dictionary:
	var ready := []
	for entry in unit.spells:
		if entry.cd == 0:
			ready.append(entry.spell)
	var allies := _living(state, "party")
	var foes := _living(state, "foe")

	# 1. Heal whoever is badly hurt
	var hurt := allies.filter(func(ally: Dictionary) -> bool: return ally.hp / ally.max_hp < HEAL_THRESHOLD)
	if not hurt.is_empty():
		var lowest := _lowest(allies)
		var best := {}
		for spell in ready:
			if spell.kind != "heal":
				continue
			if spell.target == "self" and unit.hp / unit.max_hp >= HEAL_THRESHOLD:
				continue
			if spell.target == "allies" and hurt.size() >= 2:
				return spell
			if spell.has("shield") and lowest.shield > 0.0:
				continue
			if best.is_empty() or _heal_value(spell) > _heal_value(best):
				best = spell
		if not best.is_empty():
			return best

	# 2. Tanks (or anyone with a taunt, when there's no tank) grab the foes' attention
	if state.taunt_turns <= 0 and (unit.role == "Tank" or not _has_living_tank(state)):
		for spell in ready:
			if spell.has("taunt"):
				return spell

	# 3. Keep buffs and defences up
	for spell in ready:
		if spell.kind == "support" and not spell.has("taunt") and _support_useful(unit, spell, state):
			return spell

	# 4. Deal as much damage as possible
	var target := _lowest(foes)
	var best_attack: Dictionary = unit.basic
	var best_value := _attack_value(unit.basic, foes, target)
	for spell in ready:
		if spell.kind != "attack":
			continue
		var value := _attack_value(spell, foes, target)
		if value > best_value:
			best_attack = spell
			best_value = value
	return best_attack


static func _heal_value(spell: Dictionary) -> float:
	var value: float = spell.get("mult", 0.0) + spell.get("shield", 0.0) * 0.9
	if spell.has("hot"):
		value += spell.hot[0] * spell.hot[1] * 0.7
	return value


static func _attack_value(spell: Dictionary, foes: Array, target: Dictionary) -> float:
	var value: float = spell.get("mult", 0.0)
	if spell.get("execute", false) and target.hp / target.max_hp < EXECUTE_THRESHOLD:
		value *= EXECUTE_MULT
	if spell.has("dot"):
		value += spell.dot[0] * spell.dot[1] * 0.8
	if spell.has("stun") and target.stun == 0:
		value += 0.6
	if spell.has("weaken"):
		value += 0.3
	if spell.target == "foes":
		value *= foes.size()
	return value


static func _support_useful(unit: Dictionary, spell: Dictionary, state: Dictionary) -> bool:
	if spell.has("buff"):
		return state.buff_turns <= 0
	if spell.has("weaken"):
		return state.weaken_turns <= 0
	if spell.has("empower"):
		return unit.empower_turns <= 0
	if spell.has("shield"):
		return unit.shield <= 0.0
	if spell.has("defend"):
		# Worth it when the foes are hitting this unit, or it's in trouble.
		return unit.defend_turns <= 0 and (is_same(state.taunter, unit) or unit.role == "Tank" or unit.hp / unit.max_hp < 0.5)
	return false


static func _cast(unit: Dictionary, spell: Dictionary, state: Dictionary) -> void:
	var targets := []
	match spell.target:
		"foe":
			targets = [_lowest(_living(state, "foe"))]
		"foes":
			targets = _living(state, "foe")
		"ally":
			targets = [_lowest(_living(state, "party"))]
		"allies":
			targets = _living(state, "party")
		"self":
			targets = [unit]

	var notes := []
	var total := 0.0
	var crits := 0
	var mult: float = spell.get("mult", 0.0)
	for target in targets:
		if mult > 0.0:
			var amount := 0.0
			if spell.kind == "attack":
				var bonus := EXECUTE_MULT if spell.get("execute", false) and target.hp / target.max_hp < EXECUTE_THRESHOLD else 1.0
				amount = _roll(unit, mult * bonus, state)
				if amount < 0.0:
					crits += 1
					amount = -amount
				amount = _damage(target, amount)
			else:
				amount = _roll(unit, mult, state, false)
				if amount < 0.0:
					crits += 1
					amount = -amount
				amount = _heal(target, amount)
			total += amount
		if spell.has("dot"):
			target.dots.append({"amount": spell.dot[0] * unit.potency * _damage_mult(unit, state), "turns": int(spell.dot[1]), "name": spell.name})
		if spell.has("hot"):
			target.hots.append({"amount": spell.hot[0] * unit.potency, "turns": int(spell.hot[1]), "name": spell.name})
		if spell.has("stun") and target.side == "foe":
			target.stun = maxi(target.stun, spell.stun)
		if spell.has("shield"):
			target.shield += spell.shield * unit.potency

	if spell.has("drain") and total > 0.0:
		_heal(unit, total * spell.drain)
	if spell.has("taunt"):
		state.taunter = unit
		state.taunt_turns = spell.taunt
		notes.append("the foes turn on %s" % unit.name)
	if spell.has("buff"):
		state.buff = spell.buff[0]
		state.buff_turns = spell.buff[1]
		notes.append("party deals +%d%% damage" % roundi(spell.buff[0] * 100.0))
	if spell.has("weaken"):
		state.weaken = spell.weaken[0]
		state.weaken_turns = spell.weaken[1]
		if mult <= 0.0:
			notes.append("the foes are weakened")
	if spell.has("empower"):
		unit.empower = spell.empower[0]
		unit.empower_turns = spell.empower[1]
		notes.append("+%d%% damage" % roundi(spell.empower[0] * 100.0))
	if spell.has("defend"):
		unit.defend = spell.defend[0]
		unit.defend_turns = spell.defend[1]
		notes.append("bracing for blows")
	if spell.has("stun") and targets.size() > 0 and targets[0].side == "foe":
		notes.append("stunned")
	if spell.has("shield"):
		notes.append("shielded")

	_log(state, _describe_cast(unit, spell, targets, total, crits, notes))


## Rolls an amount from the caster's potency. Negative means it was a critical hit (the caller flips it).
static func _roll(unit: Dictionary, mult: float, state: Dictionary, is_damage := true) -> float:
	var amount: float = mult * unit.potency * randf_range(0.9, 1.1)
	if is_damage:
		amount *= _damage_mult(unit, state)
	if randf() < unit.crit:
		return -amount * CRIT_MULT
	return amount


static func _damage_mult(unit: Dictionary, state: Dictionary) -> float:
	return (1.0 + state.buff) * (1.0 + unit.empower)


# --- Foe turns ---

static func _foe_act(foe: Dictionary, state: Dictionary) -> void:
	if foe.stun > 0:
		foe.stun -= 1
		_log(state, "%s is stunned and can't act." % foe.name)
		return
	var ability: Dictionary = foe.ability
	var kind: String = ability.get("type", "")
	if kind == "enrage" and not foe.enraged and foe.hp / foe.max_hp < ENRAGE_AT:
		foe.enraged = true
		foe.attack *= ENRAGE_MULT
		_log(state, "%s uses %s and becomes enraged!" % [foe.name, ability.name])
		return
	var attack: float = foe.attack * state.weaken * randf_range(0.85, 1.15)

	if kind in ["aoe", "heavy", "heal"] and state.round % int(ability.every) == 0:
		match kind:
			"aoe":
				var hit := 0.0
				for target in _living(state, "party"):
					hit += _damage(target, attack * ABILITY_AOE)
				_log(state, "%s uses %s, hitting the whole party for %d." % [foe.name, ability.name, roundi(hit)])
			"heavy":
				var target := _foe_target(state)
				var hit := _damage(target, attack * ABILITY_HEAVY)
				_log(state, "%s uses %s on %s for %d!%s" % [foe.name, ability.name, target.name, roundi(hit), _fell(target)])
			"heal":
				var healed := _heal(foe, foe.max_hp * ABILITY_HEAL)
				_log(state, "%s uses %s and recovers %d." % [foe.name, ability.name, roundi(healed)])
		return

	var target := _foe_target(state)
	if randf() < target.dodge:
		_log(state, "%s attacks %s, who dodges." % [foe.name, target.name])
		return
	var hit := _damage(target, attack)
	_log(state, "%s hits %s for %d.%s" % [foe.name, target.name, roundi(hit), _fell(target)])


## Whoever taunted, otherwise usually a living tank, otherwise anyone.
static func _foe_target(state: Dictionary) -> Dictionary:
	var allies := _living(state, "party")
	if state.taunt_turns > 0 and state.taunter != null and state.taunter.hp > 0.0:
		return state.taunter
	var tanks := allies.filter(func(ally: Dictionary) -> bool: return ally.role == "Tank")
	if not tanks.is_empty() and randf() < TANK_AGGRO:
		return tanks.pick_random()
	return allies.pick_random()


# --- Shared ---

## Applies damage after armor, defences and shields. Returns what actually landed.
static func _damage(target: Dictionary, amount: float) -> float:
	amount *= (1.0 - target.dr) * target.defend
	if target.shield > 0.0:
		var absorbed := minf(target.shield, amount)
		target.shield -= absorbed
		amount -= absorbed
	var dealt := minf(amount, target.hp)
	target.hp -= dealt
	return dealt


static func _heal(target: Dictionary, amount: float) -> float:
	var healed := minf(amount, target.max_hp - target.hp)
	target.hp += healed
	return healed


static func _end_of_round(state: Dictionary) -> void:
	for unit in state.units:
		if unit.hp <= 0.0:
			continue
		var dot_damage := 0.0
		for dot in unit.dots:
			dot_damage += _damage(unit, dot.amount)
			dot.turns -= 1
		unit.dots = unit.dots.filter(func(dot: Dictionary) -> bool: return dot.turns > 0)
		var hot_healing := 0.0
		for hot in unit.hots:
			hot_healing += _heal(unit, hot.amount)
			hot.turns -= 1
		unit.hots = unit.hots.filter(func(hot: Dictionary) -> bool: return hot.turns > 0)
		if dot_damage >= 1.0:
			_log(state, "%s suffers %d from lingering effects.%s" % [unit.name, roundi(dot_damage), _fell(unit)])
		if hot_healing >= 1.0:
			_log(state, "%s recovers %d over time." % [unit.name, roundi(hot_healing)])
		if unit.side == "party":
			unit.empower_turns -= 1
			if unit.empower_turns <= 0:
				unit.empower = 0.0
			unit.defend_turns -= 1
			if unit.defend_turns <= 0:
				unit.defend = 1.0
	state.buff_turns -= 1
	if state.buff_turns <= 0:
		state.buff = 0.0
	state.weaken_turns -= 1
	if state.weaken_turns <= 0:
		state.weaken = 1.0
	state.taunt_turns -= 1


static func _living(state: Dictionary, side: String) -> Array:
	return state.units.filter(func(unit: Dictionary) -> bool: return unit.side == side and unit.hp > 0.0)


static func _side_down(state: Dictionary, side: String) -> bool:
	return _living(state, side).is_empty()


static func _has_living_tank(state: Dictionary) -> bool:
	return _living(state, "party").any(func(unit: Dictionary) -> bool: return unit.role == "Tank")


static func _lowest(units: Array) -> Dictionary:
	var lowest: Dictionary = units[0]
	for unit in units:
		if unit.hp / unit.max_hp < lowest.hp / lowest.max_hp:
			lowest = unit
	return lowest


static func _fell(unit: Dictionary) -> String:
	return " %s falls!" % unit.name if unit.hp <= 0.0 else ""


static func _foe_names(units: Array) -> String:
	var names := []
	for unit in units:
		if unit.side == "foe":
			names.append(unit.name)
	return ", ".join(PackedStringArray(names))


static func _describe_cast(unit: Dictionary, spell: Dictionary, targets: Array, total: float, crits: int, notes: Array) -> String:
	var text := "%s casts %s" % [unit.name, spell.name]
	if is_same(spell, unit.basic):
		text = "%s uses %s" % [unit.name, spell.name]
	if total >= 1.0:
		var verb := "hitting" if spell.kind == "attack" else "healing"
		var who: String = targets[0].name if targets.size() == 1 else "%d targets" % targets.size()
		text += ", %s %s for %d" % [verb, who, roundi(total)]
		if crits > 0:
			text += " (critical)"
	elif targets.size() == 1 and targets[0] != unit and spell.kind != "support":
		text += " on %s" % targets[0].name
	if not notes.is_empty():
		text += ": " + ", ".join(PackedStringArray(notes))
	text += "."
	for target in targets:
		if target.side == "foe":
			text += _fell(target)
	return text


static func _log(state: Dictionary, text: String) -> void:
	if not state.record:
		return
	var hp := []
	for unit in state.units:
		hp.append(roundi(unit.hp))
	state.log.append({"text": text, "hp": hp})
