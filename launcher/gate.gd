extends Control
## The launcher's backdrop: Orgrimmar's front gate at dusk, seen from the Durotar road. Two spiked
## towers flank the great doors, the wall runs off behind the release notes, and torches flicker.

## Where the gate's middle stands, in pixels from the left.
var gate_x := 150.0
var _t := 0.0
var _motes: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 30:
		_motes.append([rng.randf(), rng.randf(), rng.randf_range(0.01, 0.035), rng.randf_range(1.0, 2.2), rng.randf() * TAU])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gradient(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _draw() -> void:
	var w := size.x
	var h := size.y
	var g := gate_x
	var horizon := h * 0.7
	# Dusk over Durotar
	_gradient(Rect2(0, 0, w, horizon), Color("2a0a06"), Color("d8692e"))
	draw_circle(Vector2(w * 0.78, h * 0.5), h * 0.11, Color("ff7a32"))
	draw_circle(Vector2(w * 0.78, h * 0.5), h * 0.16, Color(1, 0.45, 0.15, 0.16))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var ridge := PackedVector2Array([Vector2(0, horizon)])
	for i in 17:
		ridge.append(Vector2(w * i / 16.0, h * (0.5 + rng.randf() * 0.1)))
	ridge.append(Vector2(w, horizon))
	draw_colored_polygon(ridge, Color("6a2c1c"))
	# The city wall, its top spiked, running off to the right
	var wall_top := h * 0.36
	draw_rect(Rect2(0, wall_top, w, horizon - wall_top), Color("5a2c18"))
	for k in int(w / 18.0) + 1:
		var x := k * 18.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, wall_top), Vector2(x + 9, wall_top - 14), Vector2(x + 18, wall_top)]), Color("4a2414"))
		draw_line(Vector2(x + 9, wall_top - 2), Vector2(x + 11, wall_top - 20), Color("d8c8a8"), 2.0)
	for row in 4:
		draw_line(Vector2(0, wall_top + 24 + row * 22), Vector2(w, wall_top + 24 + row * 22), Color(0, 0, 0, 0.18), 2.0)
	# Durotar's red earth and the road to the gate
	_gradient(Rect2(0, horizon, w, h - horizon), Color("8a4424"), Color("3a1a0c"))
	draw_colored_polygon(PackedVector2Array([Vector2(g - 46, horizon), Vector2(g + 46, horizon), Vector2(g + 150, h), Vector2(g - 150, h)]), Color("a85a32"))
	# Towers on both sides of the gate, crowned with tusks
	for side in [-1.0, 1.0]:
		var tx: float = g + side * 120.0
		var tw := 70.0
		var top := h * 0.17
		draw_colored_polygon(PackedVector2Array([Vector2(tx - tw / 2, horizon), Vector2(tx + tw / 2, horizon), Vector2(tx + tw * 0.4, top),
			Vector2(tx - tw * 0.4, top)]), Color("6b3a1e"))
		draw_colored_polygon(PackedVector2Array([Vector2(tx - tw * 0.55, top + 8), Vector2(tx + tw * 0.55, top + 8), Vector2(tx, top - 34)]), Color("a7774a"))
		for k in 5:
			var off := (k - 2) / 2.0
			var base := Vector2(tx + off * tw * 0.4, top + 4)
			_tusk(base, base + Vector2(off * 26.0, -30.0 + absf(off) * 10.0), Vector2(off * 10.0, 0.0), 5.0)
		draw_rect(Rect2(tx - 7, top + 30, 14, 20), Color("1a0a05"))
		draw_rect(Rect2(tx - 5, top + 32, 10, 16), Color(1, 0.6, 0.2, 0.3 + 0.08 * sin(_t * 3.0 + side)))
		# A Horde banner down the tower's face
		var s := sin(_t * 1.4 + side) * 3.0
		var bt := top + 62.0
		draw_colored_polygon(PackedVector2Array([Vector2(tx - 15, bt), Vector2(tx + 15, bt), Vector2(tx + 15 + s, bt + 90), Vector2(tx + s, bt + 78),
			Vector2(tx - 15 + s, bt + 90)]), Color("9a1a12"))
		draw_circle(Vector2(tx + s * 0.4, bt + 30), 9.0, Color("1a0603"))
	# The gatehouse and its great doors
	var gw := 150.0
	var gtop := h * 0.24
	draw_rect(Rect2(g - gw / 2, gtop, gw, horizon - gtop), Color("5a2e18"))
	for k in 9:
		var x := g - gw / 2 + k * gw / 8.0
		draw_line(Vector2(x, gtop + 2), Vector2(x + (k - 4) * 1.5, gtop - 22), Color("eadcc0"), 3.0)
	var door := Rect2(g - 52, gtop + 34, 104, horizon - gtop - 34)
	draw_rect(door, Color("2e1a0e"))
	for k in 6:
		draw_line(Vector2(door.position.x + 4 + k * 19.0, door.position.y), Vector2(door.position.x + 4 + k * 19.0, door.end.y), Color("1e1008"), 3.0)
	for row in 4:
		var y := door.position.y + 16 + row * (door.size.y - 24) / 3.0
		draw_rect(Rect2(door.position.x, y - 3, door.size.x, 6), Color("3a3a3c"))
		for k in 6:
			draw_circle(Vector2(door.position.x + 9 + k * 17.0, y), 2.2, Color("8a8a8c"))
	draw_line(Vector2(g, door.position.y), Vector2(g, door.end.y), Color("140a04"), 3.0)
	# Torches beside the doors
	for side in [-1.0, 1.0]:
		var p := Vector2(g + side * 66.0, horizon - 40.0)
		draw_line(p, p + Vector2(0, 30), Color("3d2614"), 3.0)
		var f := 1.0 + 0.15 * sin(_t * 9.0 + side * 2.0)
		draw_circle(p - Vector2(0, 4), 5.0 * f, Color("ffb04a"))
		draw_circle(p - Vector2(0, 4), 16.0 * f, Color(1, 0.6, 0.2, 0.15))
	# Embers in the evening air
	for m in _motes:
		var y: float = fposmod(m[1] - _t * m[2], 1.0)
		var x: float = m[0] + sin(_t * 0.5 + m[4]) * 0.01
		draw_circle(Vector2(x * w, y * h), m[3], Color(1, 0.55, 0.25, (0.35 + 0.35 * sin(_t * 2.0 + m[4])) * 0.6))
	# Darken the edges so the text stands out
	_gradient(Rect2(0, 0, w, h * 0.15), Color(0, 0, 0, 0.4), Color(0, 0, 0, 0))
	_gradient(Rect2(0, h * 0.72, w, h * 0.28), Color(0, 0, 0, 0), Color(0, 0, 0, 0.55))


## A curved ivory tusk from `base` to `tip`, bowed by `bend`, tapering to the tip.
func _tusk(base: Vector2, tip: Vector2, bend: Vector2, width: float) -> void:
	var mid := (base + tip) / 2.0 + bend
	var pts := PackedVector2Array()
	for k in 9:
		var f := k / 8.0
		pts.append(base.lerp(mid, f).lerp(mid.lerp(tip, f), f))
	for layer in 2:
		for k in range(1, pts.size()):
			var wk := maxf(1.2, width * (1.0 - k / 8.0 * 0.65))
			draw_line(pts[k - 1], pts[k], Color("2a1408") if layer == 0 else Color("eadcc0"), wk + (2.0 if layer == 0 else 0.0), true)
