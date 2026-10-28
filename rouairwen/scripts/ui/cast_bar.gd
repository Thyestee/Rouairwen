class_name CastBar
## The bar drawn on top of a party frame or enemy nameplate, for everything the unit does: the spell
## Thyeste or an enemy is casting, the ability just used (it flashes full for a moment), and otherwise
## the next attack filling up: a caster guildmate's bolt, a hunter's Auto Shot, a melee swing.

const H := 15.0
## How long an instant ability's name stays on the bar.
const FLASH := 0.9
const CAST := Color("ffb52a")
const CHANNEL := Color("6ee06e")
const ENEMY_CAST := Color("ff7a2a")
const FLASHED := Color("ffe38a")


## Draws the bar into `rect` of a canvas item (nothing when the unit is dead or doing nothing).
static func draw(ci: CanvasItem, rect: Rect2, unit, engine: CombatEngine) -> void:
	if unit == null or engine == null or not unit.alive or unit.cc():
		return
	var frac := 0.0
	var text := ""
	var col := Color.WHITE
	var dim := false
	if unit.is_priest:
		if engine.casting.is_empty():
			return
		var c: Dictionary = engine.casting
		var channel: bool = c.get("channel", false)
		frac = c["remaining"] / c["total"] if channel else 1.0 - c["remaining"] / c["total"]
		text = Spells.display_name(c["id"], engine.level)
		col = CHANNEL if channel else CAST
	elif unit.is_enemy and not unit.cast.is_empty():
		var c: Dictionary = unit.cast
		frac = 1.0 - c["remaining"] / maxf(c["total"], 0.01)
		text = c["ability"]["name"]
		var tgt = c.get("target")
		if tgt != null and c["ability"]["kind"] in ["bolt", "hex", "charge", "mortal", "curse", "magic_dot"]:
			text += " → " + tgt.name
		col = ENEMY_CAST
	elif engine.time - unit.action_at < FLASH and unit.action_name != "":
		frac = 1.0
		text = unit.action_name
		col = Color(FLASHED, 1.0 - 0.5 * (engine.time - unit.action_at) / FLASH)
	elif unit.is_enemy:
		if unit.target == null or unit.swing <= 0.0:
			return
		frac = 1.0 - unit.swing_timer / maxf(unit.swing_total(), 0.01)
		text = "Attack → " + unit.target.name
		col = Color("c0392b")
		dim = true
	else:
		if engine.alive_enemies().is_empty():
			return
		frac = 1.0 - unit.attack_timer / maxf(unit.attack_total, 0.01)
		var auto: bool = CombatEngine.AUTO_ATTACK.has(unit.spec_id)
		text = CombatEngine.auto_attack(unit.spec_id) if auto else "Auto Attack"
		col = ClassData.color(unit.class_id).darkened(0.25) if auto else Color("9a8a7a")
		dim = true
	var font := Style.bold_font()
	ci.draw_rect(rect, Color(0.02, 0.01, 0.01, 0.8 if dim else 0.92))
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(frac, 0.0, 1.0), rect.size.y)), Color(col, col.a * (0.55 if dim else 1.0)))
	ci.draw_rect(rect, Color(0, 0, 0, 0.9) if dim else Color("d8b060"), false, 1.0)
	var y := rect.end.y - 3.5
	ci.draw_string_outline(font, Vector2(rect.position.x + 4, y), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8, 11, 3, Color.BLACK)
	ci.draw_string(font, Vector2(rect.position.x + 4, y), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8, 11, Color(1, 1, 1, 0.75 if dim else 1.0))
