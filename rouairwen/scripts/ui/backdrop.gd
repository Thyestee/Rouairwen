class_name Backdrop
extends Control
## Painted scenery: a place in Orgrimmar for the hub (the one its page is set in, see OrgrimmarMap),
## or a zone/dungeon for combat.
##
## The hub's page panel is see-through near its top, so each scene keeps its landmark high up and
## right of the map: buildings and banners rising into the upper middle of the screen.

const SCENE_NAMES := ["strength", "drag", "cleft", "honor", "legends", "spirits", "grommash", "war_table", "guild_hall"]
## Colour of the drifting motes in each place.
const MOTES := {"cleft": Color("b070ff"), "spirits": Color("7ff0d0"), "legends": Color("ffd86b"), "guild_hall": Color("ffe7a0"),
	"honor": Color("ffc070")}

var mode := "orgrimmar"
## The Orgrimmar scene painted in "orgrimmar" mode.
var scene := "strength"
## The guild hall's level: a bigger hall is better furnished.
var hall_level := 1
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


## Moves to another scene, fading in from dark.
func go_to(p_scene: String) -> void:
	if p_scene == scene:
		return
	scene = p_scene
	modulate = Color(0.25, 0.25, 0.25)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.4)


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
		match scene:
			"drag":
				_draw_drag()
			"cleft":
				_draw_cleft()
			"honor":
				_draw_honor()
			"legends":
				_draw_legends()
			"spirits":
				_draw_spirits()
			"grommash":
				_draw_grommash()
			"war_table":
				_draw_war_table()
			"guild_hall":
				_draw_guild_hall()
			_:
				_draw_orgrimmar()
	else:
		_draw_zone()
	# Drifting embers / motes
	var mote_col: Color = MOTES.get(scene, Color("ff8a3a")) if mode == "orgrimmar" else sky.lightened(0.6)
	for m in _motes:
		var y: float = fposmod(m[1] - _t * m[2], 1.0)
		var x: float = m[0] + sin(_t * 0.5 + m[4]) * 0.01
		var a := 0.35 + 0.35 * sin(_t * 2.0 + m[4])
		draw_circle(Vector2(x * size.x, y * size.y), m[3], Color(mote_col, a * 0.6))


# ---------------------------------------------------------------- shared pieces

## Canyon walls on both sides; `inset` pushes them toward the middle.
func _walls(color: Color, inset := 0.0) -> void:
	var w := size.x
	var h := size.y
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * (0.16 + inset), 0), Vector2(w * (0.2 + inset), h * 0.3),
		Vector2(w * (0.14 + inset), h * 0.55), Vector2(w * (0.22 + inset), h * 0.8), Vector2(0, h)]), color)
	draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w * (0.86 - inset), 0), Vector2(w * (0.8 - inset), h * 0.25),
		Vector2(w * (0.86 - inset), h * 0.5), Vector2(w * (0.78 - inset), h * 0.8), Vector2(w, h)]), color)


func _banner(bx: float, by: float, length: float, col: Color, phase := 0.0) -> void:
	var h := size.y
	draw_line(Vector2(bx, by), Vector2(bx, by - length), Color("3d2614"), 3.0)
	var wave := sin(_t * 2.0 + phase) * 3.0
	var cw := length * 0.32
	draw_colored_polygon(PackedVector2Array([Vector2(bx, by - length), Vector2(bx + cw + wave, by - length + h * 0.01),
		Vector2(bx + cw * 0.85 + wave, by - length * 0.42), Vector2(bx, by - length * 0.5)]), col)
	draw_circle(Vector2(bx + cw * 0.45 + wave * 0.5, by - length * 0.78), length * 0.06, Color("1a0603"))


func _hanging_banner(x: float, top: float, w: float, length: float, col: Color, emblem: Color) -> void:
	var s := sin(_t * 1.3 + x) * w * 0.06
	draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2, top), Vector2(x + w / 2, top), Vector2(x + w / 2 + s, top + length),
		Vector2(x + s, top + length * 0.88), Vector2(x - w / 2 + s, top + length)]), col)
	draw_line(Vector2(x - w * 0.62, top), Vector2(x + w * 0.62, top), Color("3d2614"), 4.0)
	draw_circle(Vector2(x + s * 0.4, top + length * 0.35), w * 0.22, emblem)
	draw_circle(Vector2(x + s * 0.4, top + length * 0.35), w * 0.12, col.darkened(0.3))


func _torch(p: Vector2, s: float, flame := Color("ffb04a")) -> void:
	draw_line(p, p - Vector2(0, s), Color("3d2614"), 3.0)
	var f := 1.0 + 0.15 * sin(_t * 9.0 + p.x * 0.1)
	draw_circle(p - Vector2(0, s * 1.15), s * 0.2 * f, flame)
	draw_circle(p - Vector2(0, s * 1.15), s * 0.5 * f, Color(flame, 0.15))


func _brazier(p: Vector2, s: float, flame := Color("ffa040")) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(-s, -s * 0.5), p + Vector2(s, -s * 0.5), p + Vector2(s * 0.5, 0),
		p + Vector2(-s * 0.5, 0)]), Color("2a1a10"))
	draw_line(p, p + Vector2(0, s * 1.4), Color("2a1a10"), 3.0)
	var f := 1.0 + 0.2 * sin(_t * 8.0 + p.x * 0.07)
	draw_circle(p + Vector2(0, -s * 0.9), s * 0.55 * f, flame)
	draw_circle(p + Vector2(0, -s * 1.3), s * 0.32 * f, flame.lightened(0.4))
	draw_circle(p + Vector2(0, -s * 0.9), s * 1.8 * f, Color(flame, 0.12))


## A curved ivory tusk from `base` to `tip`, bowed by `bend`, tapering to the tip.
func _tusk(base: Vector2, tip: Vector2, bend: Vector2, width: float) -> void:
	var mid := (base + tip) / 2.0 + bend
	var pts := PackedVector2Array()
	for k in 9:
		var f := k / 8.0
		pts.append(base.lerp(mid, f).lerp(mid.lerp(tip, f), f))
	for layer in 2:
		for k in range(1, pts.size()):
			var wk := maxf(1.5, width * (1.0 - k / 8.0 * 0.65))
			draw_line(pts[k - 1], pts[k], Color("2a1408") if layer == 0 else Color("eadcc0"), wk + (3.0 if layer == 0 else 0.0), true)


func _vignette() -> void:
	_gradient(Rect2(0, 0, size.x, size.y * 0.15), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0))
	_gradient(Rect2(0, size.y * 0.8, size.x, size.y * 0.2), Color(0, 0, 0, 0), Color(0, 0, 0, 0.5))


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


# ---------------------------------------------------------------- Valley of Strength (quests, title)

func _draw_orgrimmar() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_gradient(Rect2(0, 0, w, h * 0.7), Color("3a0e08"), Color("e0773a"))
	draw_circle(Vector2(w * 0.72, h * 0.42), h * 0.09, Color("ff6a2a"))
	draw_circle(Vector2(w * 0.72, h * 0.42), h * 0.13, Color(1, 0.4, 0.15, 0.18))
	_ridge(rng, h * 0.5, h * 0.12, Color("6a2c1c"), 20)
	_walls(Color("4a1c12"))
	_gradient(Rect2(0, h * 0.62, w, h * 0.38), Color("8a5a33"), Color("4a2a18"))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.44, h * 0.62), Vector2(w * 0.56, h * 0.62), Vector2(w * 0.7, h), Vector2(w * 0.3, h)]), Color("a87a4a"))
	# The bank
	_hut(Vector2(w * 0.5, h * 0.62), w * 0.2, h * 0.2, true)
	# Huts along the valley
	for x in [0.27, 0.36, 0.64, 0.74]:
		_hut(Vector2(w * x, h * 0.66 + rng.randf() * h * 0.03), w * 0.08, h * 0.1, false)
	# Quest board: a post with pinned notes
	var qb := Vector2(w * 0.83, h * 0.66)
	draw_line(qb, qb - Vector2(0, h * 0.14), Color("3d2614"), 4.0)
	draw_rect(Rect2(qb.x - w * 0.035, qb.y - h * 0.15, w * 0.07, h * 0.08), Color("6b4424"))
	for i in 4:
		draw_rect(Rect2(qb.x - w * 0.03 + (i % 2) * w * 0.032, qb.y - h * 0.145 + (i / 2) * h * 0.037, w * 0.026, h * 0.03), Color("e8d8b0"))
	draw_string(Style.bold_font(), qb + Vector2(-6, -h * 0.17), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(h * 0.05), Color("ffd24a"))
	for x in [0.31, 0.42, 0.58, 0.69]:
		_banner(w * x, h * 0.6, h * 0.16, Color("a3241a"), x * 9.0)
	for x in [0.4, 0.6]:
		_torch(Vector2(w * x, h * 0.66), h * 0.06)
	_vignette()


# ---------------------------------------------------------------- The Drag (supplies)

func _draw_drag() -> void:
	var w := size.x
	var h := size.y
	_gradient(Rect2(0, 0, w, h * 0.55), Color("240806"), Color("b8522a"))
	# Steep walls close in on the street
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.36, 0), Vector2(w * 0.32, h * 0.2), Vector2(w * 0.4, h * 0.42),
		Vector2(w * 0.3, h * 0.62), Vector2(0, h)]), Color("4a1c12"))
	draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w * 0.7, 0), Vector2(w * 0.74, h * 0.18), Vector2(w * 0.66, h * 0.4),
		Vector2(w * 0.74, h * 0.62), Vector2(w, h)]), Color("4a1c12"))
	_gradient(Rect2(0, h * 0.55, w, h * 0.45), Color("7a4a28"), Color("2e180c"))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.48, h * 0.55), Vector2(w * 0.56, h * 0.55), Vector2(w * 0.78, h), Vector2(w * 0.3, h)]), Color("9a6a3e"))
	# Merchant stalls with striped awnings on both sides, smaller further down the street
	for side in [-1, 1]:
		for i in 3:
			var depth: float = 1.0 - i * 0.28
			var cx: float = w * (0.52 + side * (0.1 + 0.12 * depth))
			var base: float = h * (0.58 + 0.12 * depth)
			var sw: float = w * 0.1 * depth
			var sh: float = h * 0.12 * depth
			draw_rect(Rect2(cx - sw / 2, base - sh, sw, sh), Color("5a3418"))
			var stripes := 5
			for k in stripes:
				var x0: float = cx - sw * 0.6 + sw * 1.2 * k / stripes
				var x1: float = cx - sw * 0.6 + sw * 1.2 * (k + 1) / stripes
				draw_colored_polygon(PackedVector2Array([Vector2(x0, base - sh), Vector2(x1, base - sh), Vector2(x1 + sw * 0.05, base - sh * 0.7),
					Vector2(x0 + sw * 0.05, base - sh * 0.7)]), Color("b8321e") if k % 2 == 0 else Color("e8d0a0"))
			draw_rect(Rect2(cx - sw * 0.4, base - sh * 0.3, sw * 0.8, sh * 0.3), Color("3a2010"))
			draw_circle(Vector2(cx - sw * 0.2, base - sh * 0.36), sh * 0.08, Color("6ab0ff"))
			draw_circle(Vector2(cx + sw * 0.15, base - sh * 0.36), sh * 0.08, Color("ff5a5a"))
	# Lanterns strung across the street
	for row in 2:
		var y0 := h * (0.2 + row * 0.13)
		var pts := PackedVector2Array()
		for k in 13:
			var f := k / 12.0
			pts.append(Vector2(lerpf(w * (0.36 + row * 0.03), w * (0.71 - row * 0.03), f), y0 + sin(f * PI) * h * 0.06))
		draw_polyline(pts, Color("2a1408"), 2.0)
		for k in range(1, 12, 2):
			var p := pts[k] + Vector2(0, 6)
			var fl := 0.85 + 0.15 * sin(_t * 5.0 + k + row)
			draw_circle(p, h * 0.012, Color("ffb24a"))
			draw_circle(p, h * 0.03 * fl, Color(1, 0.6, 0.2, 0.18))
	# Crates and barrels
	for c in [Vector2(0.33, 0.86), Vector2(0.7, 0.9), Vector2(0.38, 0.93)]:
		draw_rect(Rect2(w * c.x, h * c.y - h * 0.05, w * 0.04, h * 0.05), Color("6b4424"))
		draw_rect(Rect2(w * c.x, h * c.y - h * 0.05, w * 0.04, h * 0.05), Color("3d2614"), false, 2.0)
	_vignette()


# ---------------------------------------------------------------- Cleft of Shadow (dungeons)

func _draw_cleft() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	_gradient(Rect2(0, 0, w, h), Color("0a0612"), Color("2a1428"))
	# Cave ceiling with stalactites
	var roof := PackedVector2Array([Vector2(0, 0), Vector2(w, 0)])
	for i in 25:
		var x := w * (1.0 - i / 24.0)
		roof.append(Vector2(x, h * (0.08 + rng.randf() * 0.1)))
	draw_colored_polygon(roof, Color("1a0e18"))
	for i in 14:
		var x := rng.randf() * w
		var l := h * rng.randf_range(0.08, 0.22)
		draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.012, h * 0.1), Vector2(x + w * 0.012, h * 0.1), Vector2(x, h * 0.1 + l)]), Color("221424"))
	_walls(Color("160c16"), 0.04)
	_gradient(Rect2(0, h * 0.62, w, h * 0.38), Color("2a1a22"), Color("0c0608"))
	# Ragefire Chasm: a burning crack in the floor
	var c := Vector2(w * 0.58, h * 0.7)
	var pulse := 0.5 + 0.5 * sin(_t * 1.6)
	draw_set_transform(c, 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, w * 0.16, Color(1.0, 0.3, 0.05, 0.12 + 0.06 * pulse))
	draw_circle(Vector2.ZERO, w * 0.1, Color(1.0, 0.35, 0.08, 0.35))
	draw_circle(Vector2.ZERO, w * 0.06, Color("ff6a1a"))
	draw_circle(Vector2.ZERO, w * 0.03, Color("ffd24a"))
	draw_set_transform(Vector2.ZERO)
	# Its glow climbing the cavern
	_gradient(Rect2(w * 0.4, h * 0.25, w * 0.36, h * 0.45), Color(1, 0.3, 0.05, 0), Color(1, 0.3, 0.05, 0.12 + 0.05 * pulse))
	# Chains hanging from the ceiling
	for x in [0.4, 0.47, 0.7, 0.78]:
		var top := h * 0.14
		var chain_len := h * (0.18 + fposmod(x * 7.0, 0.12))
		for k in int(chain_len / 9.0):
			draw_arc(Vector2(w * x, top + k * 9.0), 3.0, 0.0, TAU, 8, Color("4a3a4a"), 1.5)
	# Fel braziers of the Cleft's warlocks
	for x in [0.36, 0.86]:
		_brazier(Vector2(w * x, h * 0.6), h * 0.03, Color("7aff5a"))
	_vignette()


# ---------------------------------------------------------------- Valley of Honor (recruitment)

func _draw_honor() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	_gradient(Rect2(0, 0, w, h * 0.65), Color("5a1e0c"), Color("f2a050"))
	_ridge(rng, h * 0.48, h * 0.1, Color("8a3c20"), 18)
	_walls(Color("5a2414"))
	# A waterfall down the right cliff into a pool
	var fx := w * 0.86
	_gradient(Rect2(fx - w * 0.02, h * 0.05, w * 0.04, h * 0.62), Color("8ac8e8"), Color("3a7aa8"))
	for k in 6:
		var y := fposmod(_t * 0.25 + k / 6.0, 1.0) * h * 0.6 + h * 0.06
		draw_line(Vector2(fx - w * 0.012, y), Vector2(fx - w * 0.012, y + h * 0.05), Color(1, 1, 1, 0.5), 2.0)
		draw_line(Vector2(fx + w * 0.01, y + h * 0.02), Vector2(fx + w * 0.01, y + h * 0.06), Color(1, 1, 1, 0.4), 2.0)
	_gradient(Rect2(0, h * 0.62, w, h * 0.38), Color("a8794a"), Color("4a2a16"))
	draw_set_transform(Vector2(fx - w * 0.03, h * 0.68), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, w * 0.07, Color("3a7aa8"))
	draw_set_transform(Vector2.ZERO)
	# The arena's fence
	var ac := Vector2(w * 0.5, h * 0.7)
	for k in 16:
		var a := TAU * k / 16.0
		var p := ac + Vector2(cos(a) * w * 0.14, sin(a) * h * 0.06)
		draw_line(p, p - Vector2(0, h * 0.04), Color("4a2a16"), 3.0)
	draw_set_transform(ac - Vector2(0, h * 0.03), 0.0, Vector2(1.0, 0.43))
	draw_arc(Vector2.ZERO, w * 0.14, 0.0, TAU, 40, Color("6b4424"), 3.0)
	draw_set_transform(Vector2.ZERO)
	# Training dummies
	for x in [0.34, 0.44, 0.56, 0.66]:
		var b := Vector2(w * x, h * 0.66)
		draw_line(b, b - Vector2(0, h * 0.1), Color("4a2a16"), 4.0)
		draw_line(b - Vector2(w * 0.022, h * 0.075), b - Vector2(-w * 0.022, h * 0.075), Color("4a2a16"), 3.0)
		draw_rect(Rect2(b.x - w * 0.014, b.y - h * 0.095, w * 0.028, h * 0.06), Color("c8a060"))
		draw_circle(b - Vector2(0, h * 0.11), h * 0.017, Color("c8a060"))
		draw_circle(b - Vector2(0, h * 0.065), h * 0.01, Color("b8321e"))
	# Weapon rack
	var r := Vector2(w * 0.28, h * 0.66)
	draw_line(r - Vector2(w * 0.03, h * 0.06), r + Vector2(w * 0.03, -h * 0.06), Color("3d2614"), 3.0)
	for k in 5:
		var x := r.x - w * 0.025 + k * w * 0.0125
		draw_line(Vector2(x, r.y), Vector2(x + 2, r.y - h * 0.16), Color("c0c0c0"), 2.0)
	# War banners
	for x in [0.38, 0.62, 0.74]:
		_banner(w * x, h * 0.62, h * 0.24, Color("b8231a"), x * 7.0)
	_vignette()


# ---------------------------------------------------------------- Hall of Legends (prestige)

func _draw_legends() -> void:
	var w := size.x
	var h := size.y
	_gradient(Rect2(0, 0, w, h), Color("140810"), Color("3a1a24"))
	# The far wall's arch, glowing gold
	draw_set_transform(Vector2(w * 0.6, h * 0.62), 0.0, Vector2(1.0, 1.4))
	draw_circle(Vector2.ZERO, h * 0.3, Color(1, 0.8, 0.4, 0.08))
	draw_circle(Vector2.ZERO, h * 0.22, Color(1, 0.8, 0.4, 0.08))
	draw_set_transform(Vector2.ZERO)
	# Floor with a carpet running to the trophy
	_gradient(Rect2(0, h * 0.64, w, h * 0.36), Color("2a1410"), Color("0e0604"))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.56, h * 0.64), Vector2(w * 0.64, h * 0.64), Vector2(w * 0.78, h), Vector2(w * 0.42, h)]), Color("6a1a22"))
	draw_line(Vector2(w * 0.56, h * 0.64), Vector2(w * 0.42, h), Color("d8b060"), 2.0)
	draw_line(Vector2(w * 0.64, h * 0.64), Vector2(w * 0.78, h), Color("d8b060"), 2.0)
	# Pillars with banners of the great guilds between them
	var cols := [0.3, 0.42, 0.78, 0.9]
	for i in cols.size():
		var x: float = w * cols[i]
		var pw := w * 0.035
		_gradient(Rect2(x - pw / 2, h * 0.08, pw, h * 0.6), Color("3a2a2a"), Color("1a1010"))
		draw_rect(Rect2(x - pw * 0.8, h * 0.08, pw * 1.6, h * 0.03), Color("4a3a30"))
		draw_rect(Rect2(x - pw * 0.8, h * 0.66, pw * 1.6, h * 0.025), Color("4a3a30"))
		draw_rect(Rect2(x - pw / 2, h * 0.2, pw, h * 0.012), Color("d8b060"))
	_hanging_banner(w * 0.36, h * 0.12, w * 0.05, h * 0.36, Color("6a2a8a"), Color("d8b060"))
	_hanging_banner(w * 0.84, h * 0.12, w * 0.05, h * 0.36, Color("1a3a6a"), Color("d8b060"))
	# The trophy: a crown on a pedestal, in light
	var p := Vector2(w * 0.6, h * 0.58)
	draw_rect(Rect2(p.x - w * 0.04, p.y, w * 0.08, h * 0.07), Color("3a2a2a"))
	draw_rect(Rect2(p.x - w * 0.05, p.y, w * 0.1, h * 0.015), Color("5a4a40"))
	var glow := 0.5 + 0.5 * sin(_t * 1.5)
	draw_circle(p - Vector2(0, h * 0.06), h * 0.09, Color(1, 0.85, 0.4, 0.1 + 0.08 * glow))
	var cw := w * 0.04
	draw_colored_polygon(PackedVector2Array([p + Vector2(-cw, 0), p + Vector2(-cw, -h * 0.07), p + Vector2(-cw * 0.5, -h * 0.035),
		p + Vector2(0, -h * 0.09), p + Vector2(cw * 0.5, -h * 0.035), p + Vector2(cw, -h * 0.07), p + Vector2(cw, 0)]), Color("ffd24a"))
	draw_circle(p + Vector2(0, -h * 0.035), h * 0.008, Color("d8a8ff"))
	for x in [0.5, 0.7]:
		_brazier(Vector2(w * x, h * 0.62), h * 0.025)
	_vignette()


# ---------------------------------------------------------------- Valley of Spirits (talents)

func _draw_spirits() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	_gradient(Rect2(0, 0, w, h * 0.66), Color("0c1424"), Color("3a6a74"))
	draw_circle(Vector2(w * 0.66, h * 0.2), h * 0.05, Color("e8f4ff"))
	draw_circle(Vector2(w * 0.66, h * 0.2), h * 0.09, Color(0.8, 0.95, 1.0, 0.1))
	_ridge(rng, h * 0.5, h * 0.1, Color("1a3038"), 18)
	_walls(Color("2a1c18"))
	_gradient(Rect2(0, h * 0.6, w, h * 0.4), Color("4a5a3a"), Color("141a10"))
	# The pond, shimmering
	var pc := Vector2(w * 0.6, h * 0.72)
	draw_set_transform(pc, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, w * 0.16, Color("1e4a62"))
	draw_circle(Vector2.ZERO, w * 0.12, Color("2a6a88"))
	draw_set_transform(Vector2.ZERO)
	for k in 5:
		var y := pc.y - h * 0.02 + k * h * 0.01
		var dx := sin(_t * 1.2 + k) * w * 0.01
		draw_line(Vector2(pc.x - w * 0.06 + dx, y), Vector2(pc.x + w * 0.05 + dx, y), Color(0.8, 0.95, 1.0, 0.25), 1.5)
	# Troll huts with conical thatch
	for x in [0.32, 0.44, 0.78, 0.9]:
		var b := Vector2(w * x, h * 0.64)
		var s := h * 0.1
		draw_rect(Rect2(b.x - s * 0.45, b.y - s * 0.5, s * 0.9, s * 0.5), Color("5a4028"))
		draw_colored_polygon(PackedVector2Array([b + Vector2(-s * 0.7, -s * 0.45), b + Vector2(s * 0.7, -s * 0.45), b + Vector2(0, -s * 1.5)]), Color("9a8048"))
		for k in 4:
			draw_line(b + Vector2(0, -s * 1.5), b + Vector2(-s * 0.6 + k * s * 0.4, -s * 0.45), Color("6a5430"), 1.5)
		draw_rect(Rect2(b.x - s * 0.1, b.y - s * 0.32, s * 0.2, s * 0.32), Color("1a1008"))
	# Totems with painted faces
	for x in [0.52, 0.7]:
		var b := Vector2(w * x, h * 0.66)
		var tw := w * 0.018
		var th := h * 0.26
		draw_rect(Rect2(b.x - tw / 2, b.y - th, tw, th), Color("6b4424"))
		var faces := [Color("2a8a8a"), Color("b8321e"), Color("e8c060")]
		for k in 3:
			var fy := b.y - th + k * th * 0.3 + th * 0.04
			draw_rect(Rect2(b.x - tw * 0.7, fy, tw * 1.4, th * 0.22), faces[k])
			draw_circle(Vector2(b.x - tw * 0.3, fy + th * 0.07), tw * 0.15, Color.BLACK)
			draw_circle(Vector2(b.x + tw * 0.3, fy + th * 0.07), tw * 0.15, Color.BLACK)
		draw_colored_polygon(PackedVector2Array([Vector2(b.x - tw * 1.6, b.y - th), Vector2(b.x + tw * 1.6, b.y - th), Vector2(b.x, b.y - th - h * 0.03)]), Color("e8c060"))
	_torch(Vector2(w * 0.38, h * 0.7), h * 0.07, Color("7ff0d0"))
	_vignette()


# ---------------------------------------------------------------- Grommash Hold (raids)

func _draw_grommash() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	_gradient(Rect2(0, 0, w, h * 0.66), Color("1e0404"), Color("a8301a"))
	_ridge(rng, h * 0.46, h * 0.08, Color("5a1a10"), 18)
	_walls(Color("3a1209"))
	_gradient(Rect2(0, h * 0.62, w, h * 0.38), Color("6a3a20"), Color("1e0e06"))
	# Stairs up to the hold
	for k in 5:
		var y := h * (0.66 + k * 0.035)
		var hw := w * (0.1 + k * 0.025)
		draw_rect(Rect2(w * 0.6 - hw, y, hw * 2, h * 0.035), Color("7a4a2a") if k % 2 == 0 else Color("6a3e22"))
	# The hold: a great hide hall crowned with tusks
	var c := Vector2(w * 0.6, h * 0.66)
	var hw := w * 0.2
	draw_rect(Rect2(c.x - hw, c.y - h * 0.2, hw * 2, h * 0.2), Color("5a3418"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-hw * 1.15, -h * 0.19), c + Vector2(hw * 1.15, -h * 0.19), c + Vector2(hw * 0.5, -h * 0.42),
		c + Vector2(-hw * 0.5, -h * 0.42)]), Color("a7774a"))
	draw_line(c + Vector2(-hw * 1.15, -h * 0.19), c + Vector2(hw * 1.15, -h * 0.19), Color("3d2614"), 4.0)
	# Tusks curving out from the roof, the outer ones lower and wider
	for k in 7:
		var off := (k - 3) / 3.0
		var base := Vector2(c.x + off * hw * 0.85, c.y - h * (0.42 - absf(off) * 0.2))
		var tip := base + Vector2(off * w * 0.08, -h * (0.2 - absf(off) * 0.06))
		_tusk(base, tip, Vector2(off * w * 0.06, 0.0), h * (0.014 - absf(off) * 0.004))
	# The doorway, firelit
	draw_rect(Rect2(c.x - w * 0.04, c.y - h * 0.13, w * 0.08, h * 0.13), Color("140804"))
	draw_rect(Rect2(c.x - w * 0.03, c.y - h * 0.11, w * 0.06, h * 0.11), Color(1, 0.55, 0.2, 0.25 + 0.05 * sin(_t * 3.0)))
	_hanging_banner(c.x - hw * 0.65, c.y - h * 0.18, w * 0.05, h * 0.16, Color("9a1a12"), Color("1a0603"))
	_hanging_banner(c.x + hw * 0.65, c.y - h * 0.18, w * 0.05, h * 0.16, Color("9a1a12"), Color("1a0603"))
	for x in [0.36, 0.84]:
		_brazier(Vector2(w * x, h * 0.64), h * 0.035)
	_vignette()


# ---------------------------------------------------------------- the War Table (missions)

func _draw_war_table() -> void:
	var w := size.x
	var h := size.y
	_gradient(Rect2(0, 0, w, h * 0.66), Color("1a0c06"), Color("4a2410"))
	# Wooden beams and hide walls
	for x in [0.3, 0.5, 0.7, 0.9]:
		draw_rect(Rect2(w * x - w * 0.012, 0, w * 0.024, h * 0.66), Color("2a1408"))
	draw_rect(Rect2(0, h * 0.06, w, h * 0.025), Color("2a1408"))
	for x in [0.4, 0.6, 0.8]:
		_hanging_banner(w * x, h * 0.09, w * 0.05, h * 0.26, Color("8a1a12"), Color("1a0603"))
	_gradient(Rect2(0, h * 0.64, w, h * 0.36), Color("3a2010"), Color("0e0604"))
	# The table, and a map of Kalimdor on it
	var top := h * 0.56
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.38, top), Vector2(w * 0.82, top), Vector2(w * 0.9, h * 0.72), Vector2(w * 0.3, h * 0.72)]), Color("5a3418"))
	draw_rect(Rect2(w * 0.3, h * 0.72, w * 0.6, h * 0.03), Color("3a200e"))
	for x in [0.33, 0.87]:
		draw_rect(Rect2(w * x - w * 0.01, h * 0.75, w * 0.02, h * 0.15), Color("3a200e"))
	var map := PackedVector2Array([Vector2(w * 0.43, top + h * 0.015), Vector2(w * 0.77, top + h * 0.015), Vector2(w * 0.83, h * 0.705),
		Vector2(w * 0.37, h * 0.705)])
	draw_colored_polygon(map, Color("c9a96a"))
	var route := PackedVector2Array([Vector2(w * 0.45, h * 0.69), Vector2(w * 0.52, h * 0.64), Vector2(w * 0.6, h * 0.66), Vector2(w * 0.7, h * 0.6)])
	draw_polyline(route, Color("9a1a12"), 2.0)
	for p in route:
		draw_circle(p, 3.0, Color("9a1a12"))
	for p in [Vector2(0.58, 0.6), Vector2(0.64, 0.61), Vector2(0.74, 0.67)]:
		draw_colored_polygon(PackedVector2Array([Vector2(w * p.x - 6, h * p.y + 4), Vector2(w * p.x + 6, h * p.y + 4), Vector2(w * p.x, h * p.y - 5)]), Color("6a4a2a"))
	for x in [0.24, 0.96]:
		_brazier(Vector2(w * x, h * 0.6), h * 0.035)
	_gradient(Rect2(0, 0, w, h), Color(1, 0.5, 0.2, 0.0), Color(1, 0.5, 0.2, 0.06))
	_vignette()


# ---------------------------------------------------------------- the guild hall (hall, roster, sheet)

func _draw_guild_hall() -> void:
	var w := size.x
	var h := size.y
	_gradient(Rect2(0, 0, w, h * 0.68), Color("120e1a"), Color("2e2434"))
	# Stone courses
	for row in 12:
		var y := h * 0.05 * row
		draw_line(Vector2(0, y), Vector2(w, y), Color(0, 0, 0, 0.25), 1.0)
		for k in 14:
			var x := w * (k / 14.0 + (0.035 if row % 2 == 0 else 0.0))
			draw_line(Vector2(x, y), Vector2(x, y + h * 0.05), Color(0, 0, 0, 0.18), 1.0)
	_gradient(Rect2(0, h * 0.66, w, h * 0.34), Color("2a1e18"), Color("0a0806"))
	# The guild's banner over the hearth
	var bw := w * 0.16
	GuildBanner.paint(self, Vector2(w * 0.6 - bw / 2.0, h * 0.13), bw, _t)
	# Hearth
	var hc := Vector2(w * 0.6, h * 0.66)
	draw_rect(Rect2(hc.x - w * 0.09, hc.y - h * 0.16, w * 0.18, h * 0.16), Color("3a3238"))
	draw_rect(Rect2(hc.x - w * 0.1, hc.y - h * 0.18, w * 0.2, h * 0.025), Color("4a4048"))
	draw_rect(Rect2(hc.x - w * 0.06, hc.y - h * 0.11, w * 0.12, h * 0.11), Color("0a0604"))
	var f := 1.0 + 0.12 * sin(_t * 7.0)
	draw_circle(hc - Vector2(0, h * 0.03), h * 0.035 * f, Color("ff8a2a"))
	draw_circle(hc - Vector2(0, h * 0.05), h * 0.022 * f, Color("ffd24a"))
	draw_circle(hc - Vector2(0, h * 0.04), h * 0.12, Color(1, 0.6, 0.2, 0.08))
	# A bigger hall is better furnished
	if hall_level >= 3:
		for x in [0.36, 0.84]:
			_hanging_banner(w * x, h * 0.12, w * 0.05, h * 0.3, Color("1a2a5a"), Color("d8b060"))
	if hall_level >= 5:
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.5, h * 0.7), Vector2(w * 0.7, h * 0.7), Vector2(w * 0.8, h), Vector2(w * 0.4, h)]), Color("1a2a5a"))
		draw_line(Vector2(w * 0.5, h * 0.7), Vector2(w * 0.4, h), Color("d8b060"), 2.0)
		draw_line(Vector2(w * 0.7, h * 0.7), Vector2(w * 0.8, h), Color("d8b060"), 2.0)
	if hall_level >= 7:
		var ch := Vector2(w * 0.6, h * 0.05)
		draw_line(Vector2(ch.x, 0), ch, Color("3a2a1a"), 2.0)
		draw_set_transform(ch, 0.0, Vector2(1.0, 0.25))
		draw_arc(Vector2.ZERO, w * 0.06, 0.0, TAU, 24, Color("d8b060"), 3.0)
		draw_set_transform(Vector2.ZERO)
		for k in 6:
			var p := ch + Vector2(cos(TAU * k / 6.0) * w * 0.06, sin(TAU * k / 6.0) * w * 0.015)
			draw_circle(p - Vector2(0, 5), 3.0 * (1.0 + 0.2 * sin(_t * 9.0 + k)), Color("ffd86b"))
	if hall_level >= 9:
		for x in [0.3, 0.9]:
			_brazier(Vector2(w * x, h * 0.64), h * 0.035, Color("ffe7a0"))
	for x in [0.44, 0.76]:
		_torch(Vector2(w * x, h * 0.5), h * 0.06)
	_vignette()


# ---------------------------------------------------------------- combat zones

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
