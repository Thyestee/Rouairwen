class_name EnemyFrame
extends Control
## An enemy nameplate: health, the spell it is casting and who it is attacking. Click to focus.

signal clicked(frame)

var unit
var engine: CombatEngine


func _init() -> void:
	custom_minimum_size = Vector2(230, 78)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Click to focus your guildmates' attacks (and Smite) on this enemy."


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
		accept_event()


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if unit == null:
		return
	var font := Style.bold_font()
	var r := Rect2(Vector2.ZERO, size)
	var alive: bool = unit.alive
	var gold := Color("ffd86b")
	draw_rect(r, Color(0.06, 0.02, 0.02, 0.88))
	var name_col := gold if unit.is_boss else (Color("ffb070") if unit.is_elite else Color("ffd0c0"))
	var nm: String = unit.name
	if unit.enraged:
		nm += " (Enraged)"
	draw_string_outline(font, Vector2(8, 18), nm, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 14, 4, Color.BLACK)
	draw_string(font, Vector2(8, 18), nm, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 14, name_col if alive else Color(0.5, 0.5, 0.5))
	var bar := Rect2(6, 24, size.x - 12, 18)
	draw_rect(bar, Color(0.15, 0.05, 0.05))
	if alive:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * unit.frac(), bar.size.y)), Color("b8231a"))
		var pct := "%d%%" % int(ceil(unit.frac() * 100.0))
		draw_string_outline(font, Vector2(bar.position.x, bar.end.y - 4), pct, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 12, 3, Color.BLACK)
		draw_string(font, Vector2(bar.position.x, bar.end.y - 4), pct, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 12, Color.WHITE)
	draw_rect(bar, Color.BLACK, false, 1.0)
	# Cast bar or target
	var cb := Rect2(6, 48, size.x - 12, 14)
	if alive and not unit.cast.is_empty():
		var c: Dictionary = unit.cast
		var p: float = 1.0 - c["remaining"] / maxf(c["total"], 0.01)
		draw_rect(cb, Color(0.12, 0.08, 0.02))
		draw_rect(Rect2(cb.position, Vector2(cb.size.x * p, cb.size.y)), Color("ff9a3c"))
		var txt: String = c["ability"]["name"]
		var tgt = c.get("target")
		if tgt != null and c["ability"]["kind"] in ["bolt", "hex", "charge", "mortal", "curse", "magic_dot"]:
			txt += " → " + tgt.name
		draw_string_outline(font, Vector2(cb.position.x + 4, cb.end.y - 2), txt, HORIZONTAL_ALIGNMENT_LEFT, cb.size.x - 8, 11, 3, Color.BLACK)
		draw_string(font, Vector2(cb.position.x + 4, cb.end.y - 2), txt, HORIZONTAL_ALIGNMENT_LEFT, cb.size.x - 8, 11, Color.WHITE)
	elif alive and unit.target != null:
		var t: String = "Attacking: " + unit.target.name
		draw_string(font, Vector2(cb.position.x, cb.end.y - 2), t, HORIZONTAL_ALIGNMENT_LEFT, cb.size.x, 11, Color(1, 1, 1, 0.6))
	# Berserk timer for bosses and elites
	if alive and unit.berserk > 0.0 and engine != null:
		var left: float = unit.berserk - engine.time
		var bt := "Berserk!" if left <= 0.0 else "Enrage %d:%02d" % [int(left) / 60, int(left) % 60]
		draw_string(font, Vector2(6, size.y - 3), bt, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 12, 11, Color(1, 0.4, 0.3) if left < 20.0 else Color(1, 1, 1, 0.5))
	var focused: bool = engine != null and engine.focus == unit
	var border := gold if focused else (Color("8a6a2a") if unit.is_boss else Color.BLACK)
	draw_rect(r, border, false, 2.5 if focused else 1.5)
	if focused:
		_skull(Vector2(size.x - 14, 12))
	if not alive:
		draw_rect(r, Color(0, 0, 0, 0.55))


func _skull(c: Vector2) -> void:
	draw_circle(c, 7, Color("f0f0f0"))
	draw_rect(Rect2(c.x - 4, c.y + 3, 8, 5), Color("f0f0f0"))
	draw_circle(c + Vector2(-2.5, -1), 2, Color.BLACK)
	draw_circle(c + Vector2(2.5, -1), 2, Color.BLACK)


## Damage from your spells, floating up from the health bar.
func pop(text: String, kind: String) -> void:
	UnitFrame.float_text(self, text, kind, Vector2(size.x * 0.5, 40))
