class_name Backdrop
extends Control
## Full-screen background: a dark red gradient with rising embers.

const MOTE_COUNT := 90

var _motes: Array[Dictionary] = []
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in MOTE_COUNT:
		_motes.append({
			"x": rng.randf(),
			"phase": rng.randf(),
			"speed": rng.randf_range(0.6, 1.4),
			"radius": rng.randf_range(1.0, 2.6),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var p := HordeStyle.PALETTE
	var corners := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	draw_polygon(corners, PackedColorArray([p.bg_top, p.bg_top, p.bg_bottom, p.bg_bottom]))

	for mote in _motes:
		var rise := fposmod(mote.phase + _time * 0.07 * mote.speed, 1.0)
		var sway := sin(_time * 0.8 + mote.phase * TAU) * 6.0
		var flicker := 0.5 + 0.5 * sin(_time * 9.0 + mote.phase * 40.0)
		var color: Color = p.mote
		color.a = sin(rise * PI) * (0.35 + 0.45 * flicker)
		var x: float = size.x * mote.x + sway
		draw_circle(Vector2(x, size.y * (1.0 - rise)), mote.radius, color, true, -1.0, true)
