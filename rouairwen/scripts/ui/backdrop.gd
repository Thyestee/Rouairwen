class_name Backdrop
extends Control
## Painted scenery: the Valley of Strength in Orgrimmar, or a zone/dungeon for combat.

var mode := "orgrimmar"
var sky := Color("5a1a10")
var ground := Color("8a5a33")
var seed_value := 1
var _t := 0.0
var _motes: Array = []


func _init(p_mode := "orgrimmar", p_sky := Color("5a1a10"), p_ground := Color("8a5a33"), p_seed := 1) -> void:
	mode = p_mode
	sky = p_sky
	ground = p_ground
	seed_value = p_seed
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	for i in 40:
		_motes.append([rng.randf(), rng.randf(), rng.randf_range(0.01, 0.04), rng.randf_range(1.0, 2.5), rng.randf() * TAU])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gradient(rect: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _ridge(rng: RandomNumberGenerator, base_y: float, amp: float, color: Color, steps := 16) -> void:
	var w := size.x
	var pts := PackedVector2Array([Vector2(0, size.y)])
	for i in steps + 1:
		var x := w * i / steps
		pts.append(Vector2(x, base_y - rng.randf() * amp))
	pts.append(Vector2(w, size.y))
	draw_colored_polygon(pts, color)


func _draw() -> void:
	if size.x <= 0:
		return
	if mode == "orgrimmar":
		_draw_orgrimmar()
	else:
		_draw_zone()
	# Drifting embers / motes
	var mote_col := Color("ff8a3a") if mode == "orgrimmar" else sky.lightened(0.6)
	for m in _motes:
		var y: float = fposmod(m[1] - _t * m[2], 1.0)
		var x: float = m[0] + sin(_t * 0.5 + m[4]) * 0.01
		var a := 0.35 + 0.35 * sin(_t * 2.0 + m[4])
		draw_circle(Vector2(x * size.x, y * size.y), m[3], Color(mote_col, a * 0.6))


func _draw_orgrimmar() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_gradient(Rect2(0, 0, w, h * 0.7), Color("3a0e08"), Color("e0773a"))
	draw_circle(Vector2(w * 0.72, h * 0.42), h * 0.09, Color("ff6a2a"))
	draw_circle(Vector2(w * 0.72, h * 0.42), h * 0.13, Color(1, 0.4, 0.15, 0.18))
	_ridge(rng, h * 0.5, h * 0.12, Color("6a2c1c"), 20)
	# Canyon walls on both sides
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.16, 0), Vector2(w * 0.2, h * 0.3), Vector2(w * 0.14, h * 0.55),
		Vector2(w * 0.22, h * 0.8), Vector2(0, h)]), Color("4a1c12"))
	draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w * 0.86, 0), Vector2(w * 0.8, h * 0.25), Vector2(w * 0.86, h * 0.5),
		Vector2(w * 0.78, h * 0.8), Vector2(w, h)]), Color("4a1c12"))
	_gradient(Rect2(0, h * 0.62, w, h * 0.38), Color("8a5a33"), Color("4a2a18"))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.44, h * 0.62), Vector2(w * 0.56, h * 0.62), Vector2(w * 0.7, h), Vector2(w * 0.3, h)]), Color("a87a4a"))
	# Grommash Hold
	_hut(Vector2(w * 0.5, h * 0.62), w * 0.2, h * 0.2, true)
	# Huts along the valley
	for x in [0.27, 0.36, 0.64, 0.74]:
		_hut(Vector2(w * x, h * 0.66 + rng.randf() * h * 0.03), w * 0.08, h * 0.1, false)
	# Banners
	for x in [0.31, 0.42, 0.58, 0.69]:
		var bx: float = w * x
		var by := h * 0.6
		draw_line(Vector2(bx, by), Vector2(bx, by - h * 0.16), Color("3d2614"), 3.0)
		var wave := sin(_t * 2.0 + x * 9.0) * 3.0
		draw_colored_polygon(PackedVector2Array([Vector2(bx, by - h * 0.16), Vector2(bx + w * 0.025 + wave, by - h * 0.15),
			Vector2(bx + w * 0.022 + wave, by - h * 0.09), Vector2(bx, by - h * 0.1)]), Color("a3241a"))
		draw_circle(Vector2(bx + w * 0.012 + wave * 0.5, by - h * 0.127), h * 0.009, Color("1a0603"))
	# Torches
	for x in [0.4, 0.6]:
		var p := Vector2(w * x, h * 0.66)
		draw_line(p, p - Vector2(0, h * 0.06), Color("3d2614"), 3.0)
		var f := 1.0 + 0.15 * sin(_t * 9.0 + x * 20.0)
		draw_circle(p - Vector2(0, h * 0.07), h * 0.012 * f, Color("ffb04a"))
		draw_circle(p - Vector2(0, h * 0.07), h * 0.03 * f, Color(1, 0.6, 0.2, 0.15))
	# Vignette
	_gradient(Rect2(0, 0, w, h * 0.15), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0))
	_gradient(Rect2(0, h * 0.8, w, h * 0.2), Color(0, 0, 0, 0), Color(0, 0, 0, 0.5))


func _hut(base: Vector2, w: float, h: float, big: bool) -> void:
	var hide := Color("a7774a")
	var dark := Color("6b4424")
	draw_rect(Rect2(base.x - w / 2, base.y - h * 0.5, w, h * 0.5), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - w * 0.62, base.y - h * 0.45), Vector2(base.x + w * 0.62, base.y - h * 0.45),
		Vector2(base.x + w * 0.2, base.y - h), Vector2(base.x - w * 0.2, base.y - h)]), hide)
	draw_line(Vector2(base.x - w * 0.62, base.y - h * 0.45), Vector2(base.x + w * 0.62, base.y - h * 0.45), Color("3d2614"), 3.0)
	# Bone spikes
	var n := 6 if big else 3
	for i in n:
		var x := base.x - w * 0.5 + w * (i + 0.5) / n
		var tip := Vector2(x + (i - n / 2.0) * w * 0.02, base.y - h * (1.15 if big else 1.1))
		draw_line(Vector2(x, base.y - h * 0.9), tip, Color("eadcc0"), 3.0 if big else 2.0)
	draw_rect(Rect2(base.x - w * 0.08, base.y - h * 0.32, w * 0.16, h * 0.32), Color("1a0a05"))
	draw_rect(Rect2(base.x - w * 0.06, base.y - h * 0.3, w * 0.12, h * 0.3), Color(1, 0.6, 0.2, 0.25 + 0.05 * sin(_t * 3.0)))


func _draw_zone() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_gradient(Rect2(0, 0, w, h * 0.62), sky.darkened(0.55), sky.lightened(0.15))
	_ridge(rng, h * 0.5, h * 0.12, sky.darkened(0.35).lerp(ground, 0.3), 14)
	_ridge(rng, h * 0.58, h * 0.08, ground.darkened(0.35), 18)
	_gradient(Rect2(0, h * 0.6, w, h * 0.4), ground, ground.darkened(0.6))
	for i in 9:
		var x := rng.randf() * w
		var y := h * 0.6 + rng.randf() * h * 0.08
		var s := rng.randf_range(0.6, 1.4) * h * 0.06
		if rng.randf() < 0.6:
			draw_line(Vector2(x, y), Vector2(x, y - s), ground.darkened(0.7), 4.0)
			draw_circle(Vector2(x, y - s * 1.2), s * 0.6, ground.darkened(0.45).lerp(Color("2f4a1c"), 0.4))
		else:
			draw_circle(Vector2(x, y), s * 0.5, ground.darkened(0.3))
	_gradient(Rect2(0, 0, w, h), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.55))
