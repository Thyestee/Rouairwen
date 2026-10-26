class_name Settlement
extends Control
## The Horde settlement, drawn in code: red sky with vultures, smoke and the odd goblin zeppelin,
## jagged peaks, boars roaming in the distance, the gold mine and its cart, pig farms, the great hall
## (which grows with each upgrade), the inn, the hunter's lodge, the war mill, the tannery, the Lumens
## guild banner, the forest and its lumber pile, a campfire, and the peons.
## Peons follow their real trips from Game: miners vanish into the mine, lumberjacks chop at the forest
## edge, skinners head off-screen into the wilds to hunt, leatherworkers scrape hides at the tannery;
## then they carry their load home, where the delivered amount pops up. Idle peons sit by the campfire.
## Building upgrades show on the buildings (bigger pens, trophies, salt barrels, training dummies...).
## Hovering a building highlights it; clicking it opens its menu. A button above the mine and one
## above the forest open that job's gear menu.

signal gear_menu_requested(job: String)
signal building_selected(id: String)

const GOLD := Color("f5c542")
const GOLD_LIGHT := Color("fff1a8")
const SHADOW := Color("1e140d")
const FLAME := Color("ff9a3c")
const FLAME_CORE := Color("ffe08a")
const BOOTS_COLOR := Color("2e1c10")
const PELT := Color("9a6440")
const LEATHER := Color("c58b4f")
const BOAR := Color("4a3328")
const STEEL := Color("b8b4ac")
const SMOKE := Color(0.25, 0.22, 0.2)
const SALT := Color("e8e2d4")
const HIGHLIGHT := Color("ffd86b")
## Colour of each job's load and of its delivery popups.
const LOAD_COLORS := {"gold": GOLD, "lumber": Color("e0b07a"), "skins": Color("d09a70"), "leather": Color("eab878")}
const MAX_WORKERS_SHOWN_PER_JOB := 12
const MAX_IDLE_SHOWN := 6
const POPUP_SECONDS := 1.2
const MAX_POPUPS := 24
## Depth runs from the horizon (0) to the ground line (1); x positions are shares of the width.
const FARM_ROW := 0.12
const FARM_SLOTS := [0.36, 0.64, 0.3, 0.7, 0.42, 0.58, 0.24, 0.76]
const INN_SLOT := Vector2(0.2, 0.22)
const LODGE_SLOT := Vector2(0.06, 0.2)
const MILL_SLOT := Vector2(0.7, 0.26)
const TANNERY_X := 0.695  # on the ground line, between the hall and the forest
const CAMPFIRE := Vector2(0.33, 10.5)  # x share of the width, units below the ground line
const GROUND_DETAILS := 90  # grass tufts and pebbles scattered on the ground
const SITE_BUTTON_TEXT := {"gold": "Mine upgrades", "lumber": "Forest upgrades"}
## Forest trees as [x share of width, depth below the ground line in units, scale], back to front.
const TREES := [
	[0.82, -3.0, 0.9], [0.93, -3.5, 1.0], [0.87, -1.0, 1.1], [0.98, -0.5, 0.95],
	[0.79, 1.5, 1.0], [0.91, 2.5, 1.15], [0.85, 5.0, 1.05], [0.97, 5.5, 1.1],
]
const NUGGETS := [Vector2(-8, -3), Vector2(7, -5), Vector2(-4, -8), Vector2(9, -2), Vector2(1, -9.5)]

var _p := HordeStyle.PALETTE
var _time := 0.0
var _popups: Array[Dictionary] = []  # delivery amounts rising above the hall: {"text", "job", "offset", "age"}
var _site_buttons := {}  # job -> the Button above its work site
var _hover := ""  # building under the mouse
var _selected := ""  # building whose menu is open
var _details: Array[Dictionary] = []  # {"x", "depth" (0 horizon .. 1 bottom edge), "size", "pebble"}

# Layout, recomputed on resize. Sizes are in units (_u) so the scene scales with the window.
var _u := 1.0
var _horizon := 0.0
var _ground := 0.0
var _mine := Vector2.ZERO
var _hall := Vector2.ZERO


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void: _hover = "")
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in GROUND_DETAILS:
		_details.append({"x": rng.randf(), "depth": rng.randf(), "size": rng.randf_range(0.6, 1.3), "pebble": rng.randf() < 0.35})
	for job in SITE_BUTTON_TEXT:
		var button := Button.new()
		button.text = SITE_BUTTON_TEXT[job]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(func() -> void: gear_menu_requested.emit(job))
		add_child(button)
		_site_buttons[job] = button
	for job in _site_buttons:  # buttons grow once the theme's font applies; keep them centred
		_site_buttons[job].resized.connect(_place_site_buttons)
	resized.connect(_layout)
	Game.delivered.connect(_on_delivered)
	_layout()


func _process(delta: float) -> void:
	_time += delta
	for popup in _popups:
		popup.age += delta
	while not _popups.is_empty() and _popups[0].age > POPUP_SECONDS:
		_popups.pop_front()
	# A site button glows while one of its upgrades is affordable.
	var glow := 0.5 + 0.5 * sin(_time * 4.0)
	for job in _site_buttons:
		var lit := glow if Game.can_upgrade_gear(job) else 0.0
		_site_buttons[job].modulate = Color.WHITE.lerp(Color(1.4, 1.25, 0.9), lit)
	queue_redraw()


## Shows which site's gear menu is open ("" for none).
func set_selected_job(job: String) -> void:
	for key in _site_buttons:
		_site_buttons[key].set_pressed_no_signal(key == job)


## Highlights the building whose menu is open ("" for none).
func set_selected_building(id: String) -> void:
	_selected = id


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion:
		_hover = _building_at(motion.position)
		mouse_default_cursor_shape = Control.CURSOR_ARROW if _hover == "" else Control.CURSOR_POINTING_HAND
		return
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var id := _building_at(click.position)
		if id != "":
			accept_event()
			building_selected.emit(id)


## Clickable area of every building that's standing, front ones first so they win overlaps.
func _building_rects() -> Dictionary:
	var u := _u
	var rects := {}
	if Game.has_building("tannery"):
		rects["tannery"] = Rect2(size.x * TANNERY_X - 4.5 * u, _ground - 6.5 * u, 9.5 * u, 7.0 * u)
	if Game.guild_founded:
		rects["guild"] = Rect2(_mine.x + 12.8 * u, _ground - 18.0 * u, 7.0 * u, 18.0 * u)
	var hall_half := (13.0 + Game.hall_tier * 3.5) * u
	rects["hall"] = Rect2(_hall.x - hall_half, _ground - (15.0 + Game.hall_tier * 3.5) * u, hall_half * 2.0, (15.0 + Game.hall_tier * 3.5) * u)
	if Game.has_building("mill"):
		var mill := Vector2(size.x * MILL_SLOT.x, _depth_y(MILL_SLOT.y))
		rects["mill"] = Rect2(mill.x - 5.5 * u, mill.y - 9.0 * u, 12.0 * u, 9.5 * u)
	if Game.inn_built:
		var inn := Vector2(size.x * INN_SLOT.x, _depth_y(INN_SLOT.y))
		rects["inn"] = Rect2(inn.x - 6.0 * u, inn.y - 10.0 * u, 14.0 * u, 10.5 * u)
	if Game.has_building("lodge"):
		var lodge := Vector2(size.x * LODGE_SLOT.x, _depth_y(LODGE_SLOT.y))
		rects["lodge"] = Rect2(lodge.x - 4.5 * u, lodge.y - 8.5 * u, 11.5 * u, 9.0 * u)
	if Game.farms > 0:
		var shown := mini(Game.farms, FARM_SLOTS.size())
		var left := 1.0
		var right := 0.0
		for i in shown:
			left = minf(left, FARM_SLOTS[i])
			right = maxf(right, FARM_SLOTS[i])
		var row := _depth_y(FARM_ROW)
		rects["farm"] = Rect2(size.x * left - 4.0 * u, row - 4.0 * u, size.x * (right - left) + 9.0 * u, 5.0 * u)
	return rects


func _building_at(point: Vector2) -> String:
	var rects := _building_rects()
	for id in rects:
		if rects[id].has_point(point):
			return id
	return ""


func _place_site_buttons() -> void:
	_place_above(_site_buttons.gold, _mine.x, _ground - 12.5 * _u)
	_place_above(_site_buttons.lumber, size.x * 0.885, _ground - 20.0 * _u)


func _place_above(button: Button, center_x: float, bottom: float) -> void:
	var x := clampf(center_x - button.size.x / 2.0, 4.0, size.x - button.size.x - 4.0)
	button.position = Vector2(x, bottom - button.size.y)


func _on_delivered(job: String, amount: float) -> void:
	if _popups.size() >= MAX_POPUPS:
		_popups.pop_front()
	_popups.append({"text": "+" + NumberFormat.short(amount), "job": job, "offset": randf_range(-1.5, 1.5), "age": 0.0})


func _layout() -> void:
	_u = minf(size.x / 100.0, size.y / 62.0)
	_horizon = size.y * 0.5
	_ground = size.y * 0.8
	_mine = Vector2(size.x * 0.15, _ground)
	_hall = Vector2(size.x * 0.5, _ground)
	_place_site_buttons()


func _draw() -> void:
	_draw_sky()
	_draw_peaks(_p.hills_far, 15.0, 6, 1.0)
	_draw_peaks(_p.hills_near, 8.0, 11, 7.0)
	_gradient_rect(Rect2(0, _horizon, size.x, size.y - _horizon), _p.ground_top, _p.ground_bottom)
	_draw_ground_details()
	_draw_path()
	var rects := _building_rects()
	_draw_highlight(rects)

	# Back to front: the far plain, the back row of buildings, then the ground line.
	_draw_boars()
	for i in mini(Game.farms, FARM_SLOTS.size()):
		var slot: float = FARM_SLOTS[i]
		_draw_pig_farm(Vector2(size.x * slot, _depth_y(FARM_ROW)), 0.6, i)
	if Game.has_building("lodge"):
		_draw_lodge(Vector2(size.x * LODGE_SLOT.x, _depth_y(LODGE_SLOT.y)))
	if Game.inn_built:
		_draw_inn(Vector2(size.x * INN_SLOT.x, _depth_y(INN_SLOT.y)))
	if Game.has_building("mill"):
		_draw_war_mill(Vector2(size.x * MILL_SLOT.x, _depth_y(MILL_SLOT.y)))
	_draw_mine()
	_draw_mine_cart()
	if Game.guild_founded:
		_draw_guild_banner(Vector2(_mine.x + 13.8 * _u, _ground - 0.5 * _u))
	_draw_smoke(_hall + Vector2(-3.0, -10.0 - Game.hall_tier * 2.0) * _u, 1.2, 0)
	_draw_great_hall(_hall, Game.hall_tier)
	if Game.has_building("tannery"):
		_draw_tannery(Vector2(size.x * TANNERY_X, _ground))
	_draw_lumber_pile()
	_draw_forest()
	_draw_campfire()
	_draw_workers()
	_draw_popups()
	_draw_building_label(rects)


func _depth_y(depth: float) -> float:
	return lerpf(_horizon, _ground, depth)


func _draw_sky() -> void:
	_gradient_rect(Rect2(0, 0, size.x, _horizon + 1.0), _p.sky_top, _p.sky_bottom)
	var sun: Color = _p.sun
	_draw_glow(Vector2(size.x * 0.3, _horizon - 3.0 * _u), 11.0 * _u, sun)
	for i in 30:  # embers drifting up
		var rise := fposmod(_time * (3.0 + i % 4) * _u + i * 37.0, _horizon)
		var x := fposmod(i * 71.3 + sin(_time + i) * 2.0 * _u, size.x)
		var alpha := 0.35 + 0.35 * sin(_time * 7.0 + i)
		draw_circle(Vector2(x, _horizon - rise), 0.3 * _u, Color(sun.lightened(0.4), alpha))
	_draw_zeppelin()
	_draw_vultures()


## Three vultures circling over the plain, flapping now and then.
func _draw_vultures() -> void:
	var color := Color(0.12, 0.05, 0.04, 0.85)
	for i in 3:
		var angle := _time * (0.25 + i * 0.05) + i * 2.1
		var center := Vector2(size.x * (0.58 + i * 0.07), size.y * (0.16 + i * 0.03))
		var bird := center + Vector2(cos(angle) * 9.0, sin(angle) * 3.0) * _u
		var flap := 0.4 + 0.5 * maxf(sin(_time * 6.0 + i * 1.7), 0.0)
		var span := (1.6 - i * 0.2) * _u
		draw_polyline(PackedVector2Array([bird + Vector2(-span, -flap * _u), bird, bird + Vector2(span, -flap * _u)]), color, 0.3 * _u, true)


## A goblin zeppelin drifting across the sky now and then, on its way between Orgrimmar and Undercity.
func _draw_zeppelin() -> void:
	var u := _u
	var span := size.x + 40.0 * u
	var x := fposmod(_time * 1.6 * u + size.x * 0.3, span * 1.6) - 20.0 * u  # off-screen for part of the loop
	if x > size.x + 20.0 * u:
		return
	var c := Vector2(x, size.y * 0.12 + sin(_time * 0.7) * 0.6 * u)
	var hull := Color("7a3a24")
	_draw_ellipse(c, Vector2(7.0, 2.4) * u, hull)
	for stripe: float in [-3.5, 0.0, 3.5]:
		draw_line(c + Vector2(stripe, -2.3) * u, c + Vector2(stripe, 2.3) * u, hull.darkened(0.35), 0.3 * u)
	_triangle(c + Vector2(-6.2, -0.5) * u, c + Vector2(-8.6, -2.6) * u, c + Vector2(-7.4, 0.0) * u, hull.darkened(0.2))
	_triangle(c + Vector2(-6.2, 0.5) * u, c + Vector2(-8.6, 2.6) * u, c + Vector2(-7.4, 0.0) * u, hull.darkened(0.2))
	var gondola := Rect2(c.x - 2.0 * u, c.y + 3.0 * u, 4.0 * u, 1.2 * u)
	for rope: float in [-1.8, 1.8]:
		draw_line(c + Vector2(rope, 2.0) * u, Vector2(c.x + rope * u, gondola.position.y), Color(0.15, 0.08, 0.05), 0.15 * u)
	draw_rect(gondola, _p.wood)
	var spin := absf(sin(_time * 25.0))
	draw_line(Vector2(gondola.position.x - 0.3 * u, gondola.get_center().y - spin * 0.8 * u),
		Vector2(gondola.position.x - 0.3 * u, gondola.get_center().y + spin * 0.8 * u), STEEL, 0.25 * u)


func _draw_glow(center: Vector2, radius: float, color: Color) -> void:
	for k in range(6, 0, -1):
		draw_circle(center, radius * (1.0 + k * 0.35), Color(color, 0.06), true, -1.0, true)
	draw_circle(center, radius, color, true, -1.0, true)


func _draw_peaks(color: Color, height: float, count: int, seed_offset: float) -> void:
	var points := PackedVector2Array([Vector2(0, _horizon + 1.0)])
	for i in count * 2 + 1:
		var noise := fposmod(sin((i + seed_offset) * 12.9898) * 43758.5453, 1.0)
		var peak := height * (0.6 + 0.4 * noise) if i % 2 == 0 else height * 0.25 * noise
		points.append(Vector2(size.x * i / (count * 2.0), _horizon - peak * _u))
	points.append(Vector2(size.x, _horizon + 1.0))
	draw_colored_polygon(points, color)


func _draw_mine() -> void:
	var c := _mine
	var w := 13.0 * _u
	var h := 11.0 * _u
	_shadow(c, w * 1.05)
	var mound := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		mound.append(c + Vector2(-cos(a) * w, -sin(a) * h * (1.0 + 0.07 * sin(i * 2.7))))
	draw_colored_polygon(mound, _p.rock)
	for rock: Vector2 in [Vector2(5, -4), Vector2(-6, -6), Vector2(2, -8)]:
		draw_circle(c + rock * _u, 2.2 * _u, _p.rock_dark, true, -1.0, true)

	for i in NUGGETS.size():
		var nugget: Vector2 = c + NUGGETS[i] * _u
		draw_circle(nugget, 0.9 * _u, GOLD, true, -1.0, true)
		var sparkle := 0.5 + 0.5 * sin(_time * 3.0 + i * 1.7)
		draw_circle(nugget + Vector2(-0.3, -0.3) * _u, 0.35 * _u, Color(GOLD_LIGHT, sparkle), true, -1.0, true)

	# Timbered entrance
	var door := Rect2(c.x - 3.0 * _u, c.y - 6.0 * _u, 6.0 * _u, 6.0 * _u)
	var wood: Color = _p.wood
	draw_rect(door, SHADOW)
	draw_line(door.position, Vector2(door.position.x, door.end.y), wood, 0.9 * _u)
	draw_line(Vector2(door.end.x, door.position.y), door.end, wood, 0.9 * _u)
	draw_line(door.position - Vector2(0.8 * _u, 0), Vector2(door.end.x + 0.8 * _u, door.position.y), wood, 1.1 * _u)
	for nugget: Vector2 in [Vector2(4.6, -0.7), Vector2(5.8, -0.7), Vector2(5.2, -1.6)]:
		draw_circle(c + nugget * _u, 0.75 * _u, GOLD, true, -1.0, true)


func _draw_forest() -> void:
	for tree in TREES:
		var x: float = size.x * tree[0]
		var y: float = _ground + tree[1] * _u
		_draw_tree(Vector2(x, y), tree[2])


func _draw_tree(base: Vector2, scale_factor: float) -> void:
	var s := _u * scale_factor
	_shadow(base, 4.0 * s)
	var trunk: Color = _p.trunk
	draw_rect(Rect2(base.x - 0.7 * s, base.y - 3.0 * s, 1.4 * s, 3.0 * s), trunk)
	draw_rect(Rect2(base.x + 0.15 * s, base.y - 3.0 * s, 0.55 * s, 3.0 * s), trunk.darkened(0.3))
	var dark: Color = _p.tree_dark
	var light: Color = _p.tree_light
	for layer in 3:
		var bottom := base.y - (2.5 + layer * 3.0) * s
		var half := (5.0 - layer * 1.2) * s
		var color := dark.lerp(light, layer / 2.0)
		_triangle(Vector2(base.x - half, bottom), Vector2(base.x + half, bottom), Vector2(base.x, bottom - 5.5 * s), color)
		# shaded right half, so the trees look round in the low sun
		_triangle(Vector2(base.x, bottom), Vector2(base.x + half, bottom), Vector2(base.x, bottom - 5.5 * s), color.darkened(0.18))


## A pig farm: a hide hut and a fenced pen with a mud puddle. Bigger Pens widen the pen and add pigs,
## who wander about.
func _draw_pig_farm(c: Vector2, scale_factor: float, index: int) -> void:
	var u := _u * scale_factor
	var pens := Game.get_upgrade_level("bigger_pens")
	var half := (5.0 + pens * 0.8) * u
	var pen := c + Vector2(2.0 * u + pens * 0.4 * u, 0)
	_draw_ellipse(pen, Vector2(half, 1.6 * u), _p.pen)
	_draw_ellipse(pen + Vector2(half * 0.4, 0.3 * u), Vector2(1.4 * u, 0.5 * u), Color(_p.pen).darkened(0.3))
	var pig: Color = _p.pig
	for k in 1 + pens:
		var wander := sin(_time * 0.6 + index * 1.3 + k * 2.2)
		var spot := pen + Vector2(-half * 0.6 + k * 1.8 * u + wander * 1.2 * u, -0.6 * u + (k % 2) * 0.5 * u)
		var facing := signf(cos(_time * 0.6 + index * 1.3 + k * 2.2))
		draw_circle(spot, 0.9 * u, pig, true, -1.0, true)
		draw_circle(spot + Vector2(facing * 1.0, -0.3) * u, 0.6 * u, pig, true, -1.0, true)
		draw_circle(spot + Vector2(facing * 1.45, -0.25) * u, 0.22 * u, pig.darkened(0.25), true, -1.0, true)
	for k in 8 + pens * 2:
		var x := pen.x - half + 0.4 * u + k * 1.3 * u
		if x > pen.x + half:
			break
		draw_line(Vector2(x, c.y + 0.6 * u), Vector2(x, c.y - 1.2 * u), _p.wood, 0.3 * u)
	draw_line(Vector2(pen.x - half, c.y - 0.6 * u), Vector2(pen.x + half, c.y - 0.6 * u), _p.wood, 0.25 * u)
	_draw_dome(c + Vector2(-4.5 * u, 0), 3.0 * u, 3.0 * u, _p.hide)
	_triangle(c + Vector2(-5.0, -2.8) * u, c + Vector2(-4.0, -2.8) * u, c + Vector2(-4.5, -4.6) * u, _p.bone)


## Two boars rooting about on the far plain, where the skinners go hunting.
func _draw_boars() -> void:
	var u := _u * 0.55
	for i in 2:
		var wander := sin(_time * 0.25 + i * 2.6)
		var facing := signf(cos(_time * 0.25 + i * 2.6))
		var c := Vector2(size.x * (0.07 + 0.06 * i) + wander * 3.0 * u, _depth_y(0.08 + 0.05 * i))
		_draw_ellipse(c + Vector2(0, -1.2 * u), Vector2(2.0 * u, 1.2 * u), BOAR)
		draw_circle(c + Vector2(facing * 2.0 * u, -1.0 * u), 0.9 * u, BOAR, true, -1.0, true)
		draw_line(c + Vector2(facing * 2.5, -0.8) * u, c + Vector2(facing * 3.1, -1.3) * u, _p.bone, 0.25 * u)
		for leg: float in [-1.2, -0.4, 0.5, 1.2]:
			draw_line(c + Vector2(leg, -0.4) * u, c + Vector2(leg, 0.3) * u, BOAR, 0.4 * u)


## The hunter's lodge: a hide tent with poles poking out, and a rack of pelts drying beside it.
## Trophy Hunting hangs skulls on the rack; the Smokehouse smokes.
func _draw_lodge(c: Vector2) -> void:
	var u := _u * 0.85
	_shadow(c + Vector2(1.0 * u, 0), 6.0 * u)
	if Game.get_upgrade_level("smokehouse") > 0:
		_draw_smoke(c + Vector2(-1.0, -8.5) * u, 0.7, 3)
	var tent_top := c + Vector2(-1.0, -7.5) * u
	for pole: float in [-0.8, 0.8]:
		draw_line(tent_top + Vector2(pole * 0.5, 0.6) * u, tent_top + Vector2(pole * 1.4, -1.6) * u, _p.wood, 0.3 * u)
	_triangle(c + Vector2(-5.0, 0) * u, c + Vector2(3.0, 0) * u, tent_top, _p.hide)
	_triangle(c + Vector2(-2.0, 0) * u, c + Vector2(0.0, 0) * u, c + Vector2(-1.0, -3.2) * u, SHADOW)
	draw_line(tent_top, c + Vector2(-3.4, -2.0) * u, _p.hide_dark, 0.25 * u)
	# Drying rack with two pelts
	var rack_top := c.y - 4.0 * u
	for post: float in [3.6, 7.2]:
		draw_line(Vector2(c.x + post * u, c.y), Vector2(c.x + post * u, rack_top), _p.wood, 0.35 * u)
	draw_line(Vector2(c.x + 3.4 * u, rack_top), Vector2(c.x + 7.4 * u, rack_top), _p.wood, 0.35 * u)
	for pelt: float in [4.5, 6.3]:
		_draw_ellipse(Vector2(c.x + pelt * u, rack_top + 1.4 * u), Vector2(0.8 * u, 1.3 * u), PELT)
	for k in Game.get_upgrade_level("trophy_hunting"):
		var skull := Vector2(c.x + (3.6 + k * 1.8) * u, rack_top - 0.7 * u)
		draw_circle(skull, 0.55 * u, _p.bone, true, -1.0, true)
		draw_line(skull + Vector2(-0.4, -0.3) * u, skull + Vector2(-1.0, -1.0) * u, _p.bone, 0.2 * u)
		draw_line(skull + Vector2(0.4, -0.3) * u, skull + Vector2(1.0, -1.0) * u, _p.bone, 0.2 * u)


## The tannery: a work shed with a slanted roof, a tanning vat, and a frame with a hide stretched on it.
## Tanning Racks hang more hides on the shed; Salt Curing stacks salt sacks by the vat.
func _draw_tannery(c: Vector2) -> void:
	var u := _u * 0.8
	_shadow(c, 6.0 * u)
	var shed := Rect2(c.x - 0.5 * u, c.y - 5.0 * u, 5.0 * u, 5.0 * u)
	draw_rect(shed, _p.wood)
	for k in range(1, 4):
		var x := shed.position.x + k * shed.size.x / 4.0
		draw_line(Vector2(x, shed.position.y), Vector2(x, shed.end.y), _p.hide_dark, 0.2 * u)
	draw_colored_polygon(PackedVector2Array([
		Vector2(shed.position.x - 0.8 * u, shed.position.y), Vector2(shed.end.x + 0.8 * u, shed.position.y + 1.2 * u),
		Vector2(shed.end.x + 0.8 * u, shed.position.y - 0.4 * u), Vector2(shed.position.x - 0.8 * u, shed.position.y - 2.2 * u),
	]), _p.hide)
	draw_rect(Rect2(shed.position.x + 1.8 * u, c.y - 3.0 * u, 1.6 * u, 3.0 * u), SHADOW)
	# Vat
	var vat := Rect2(shed.end.x + 0.3 * u, c.y - 2.0 * u, 2.2 * u, 2.0 * u)
	draw_rect(vat, _p.hide_dark)
	_draw_ellipse(Vector2(vat.get_center().x, vat.position.y), Vector2(1.1 * u, 0.4 * u), Color("5a3a1e"))
	# Stretching frame
	var left := c.x - 5.0 * u
	var right := c.x - 1.5 * u
	var top := c.y - 5.0 * u
	draw_line(Vector2(left, c.y), Vector2(left, top), _p.wood, 0.35 * u)
	draw_line(Vector2(right, c.y), Vector2(right, top), _p.wood, 0.35 * u)
	draw_line(Vector2(left, top + 0.4 * u), Vector2(right, top + 0.4 * u), _p.wood, 0.3 * u)
	draw_rect(Rect2(left + 0.4 * u, top + 0.9 * u, right - left - 0.8 * u, 3.0 * u), PELT)
	for k in Game.get_upgrade_level("tanning_racks"):
		var hide := Rect2(shed.position.x + 0.3 * u + k * 1.5 * u, shed.position.y + 0.6 * u, 1.2 * u, 1.8 * u)
		draw_rect(hide, LEATHER.darkened(0.1 * k))
	for k in Game.get_upgrade_level("salt_curing"):
		var sack := Vector2(vat.end.x + 0.9 * u, c.y - 0.6 * u - k * 1.0 * u)
		_draw_ellipse(sack, Vector2(0.8 * u, 0.55 * u), SALT)


## Log tavern with a hide roof, a smoking chimney and a hanging mug sign.
## Comfortable Beds light an attic window; the Recruitment Board stands by the door.
func _draw_inn(c: Vector2) -> void:
	var u := _u * 0.85
	var wood: Color = _p.wood
	var walls := Rect2(c.x - 5.0 * u, c.y - 5.0 * u, 10.0 * u, 5.0 * u)
	_shadow(c, 7.0 * u)

	var chimney := Rect2(c.x + 2.0 * u, c.y - 10.5 * u, 1.6 * u, 3.0 * u)
	draw_rect(chimney, _p.rock_dark)
	_draw_smoke(Vector2(chimney.get_center().x, chimney.position.y), 0.8, 1)

	draw_rect(walls, wood)
	for k in range(1, 4):
		var y := walls.position.y + k * walls.size.y / 4.0
		draw_line(Vector2(walls.position.x, y), Vector2(walls.end.x, y), _p.hide_dark, 0.2 * u)
	var roof_top := walls.position.y - 4.0 * u
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - 6.5 * u, walls.position.y), Vector2(c.x + 6.5 * u, walls.position.y),
		Vector2(c.x + 3.0 * u, roof_top), Vector2(c.x - 3.0 * u, roof_top),
	]), _p.hide)
	draw_line(Vector2(c.x - 3.0 * u, roof_top), Vector2(c.x + 3.0 * u, roof_top), _p.hide_dark, 0.4 * u)

	draw_rect(Rect2(c.x - 1.2 * u, c.y - 3.2 * u, 2.4 * u, 3.2 * u), SHADOW)
	for side: float in [-1.0, 1.0]:
		draw_rect(Rect2(c.x + side * 3.2 * u - 0.7 * u, c.y - 3.6 * u, 1.4 * u, 1.4 * u), _p.window_light)

	var arm_y := c.y - 4.2 * u
	draw_line(Vector2(walls.end.x, arm_y), Vector2(walls.end.x + 3.2 * u, arm_y), wood, 0.35 * u)
	var board := Rect2(walls.end.x + 1.0 * u, arm_y + 0.4 * u, 2.6 * u, 2.4 * u)
	draw_rect(board, _p.hide_dark)
	var mug := Rect2(board.position.x + 0.7 * u, board.position.y + 0.8 * u, 1.0 * u, 1.2 * u)
	draw_rect(mug, GOLD)
	draw_rect(Rect2(mug.position.x - 0.1 * u, mug.position.y - 0.35 * u, 1.2 * u, 0.4 * u), Color.WHITE)
	draw_line(Vector2(mug.end.x, mug.position.y + 0.3 * u), Vector2(mug.end.x + 0.4 * u, mug.position.y + 0.6 * u), GOLD, 0.25 * u)

	var beds := Game.get_upgrade_level("comfortable_beds")
	for k in beds:
		draw_rect(Rect2(c.x - 2.2 * u + k * 1.6 * u, roof_top + 1.2 * u, 1.0 * u, 1.0 * u), _p.window_light)
	if Game.get_upgrade_level("recruitment_board") > 0:
		var post := Vector2(walls.position.x - 1.6 * u, c.y)
		draw_line(post, post - Vector2(0, 3.4 * u), wood, 0.3 * u)
		var notices := Rect2(post.x - 1.4 * u, post.y - 3.6 * u, 2.8 * u, 2.0 * u)
		draw_rect(notices, _p.hide_dark)
		for k in Game.get_upgrade_level("recruitment_board"):
			draw_rect(Rect2(notices.position.x + 0.3 * u + k * 0.8 * u, notices.position.y + 0.3 * u, 0.6 * u, 0.9 * u), SALT)


## The Lumens banner: a violet standard with a pulsing golden sun. Training Grounds add straw dummies,
## the Quartermaster supply crates and the War Chest a chest of gold at its foot.
func _draw_guild_banner(base: Vector2) -> void:
	var u := _u
	var light: Color = _p.guild_light
	var top := base - Vector2(0, 17.0 * u)
	_shadow(base + Vector2(2.5 * u, 0), 3.5 * u)
	for k in mini(Game.get_upgrade_level("training_grounds"), 3):
		var dummy := base + Vector2(2.2 + k * 1.7, 0.2) * u
		draw_line(dummy, dummy - Vector2(0, 2.6 * u), _p.wood, 0.25 * u)
		draw_line(dummy - Vector2(0.9, 1.9) * u, dummy - Vector2(-0.9, 1.9) * u, _p.wood, 0.2 * u)
		_draw_ellipse(dummy - Vector2(0, 1.5 * u), Vector2(0.55, 0.8) * u, Color("c9a046"))
		draw_circle(dummy - Vector2(0, 2.7 * u), 0.45 * u, Color("c9a046"), true, -1.0, true)
	for k in Game.get_upgrade_level("quartermaster"):
		var crate := Rect2(base.x - 2.6 * u - k * 0.4 * u, base.y - (1.2 + k * 1.1) * u, 1.6 * u, 1.1 * u)
		draw_rect(crate, _p.wood)
		draw_rect(crate, _p.hide_dark, false, 0.15 * u)
	if Game.get_upgrade_level("war_chest") > 0:
		var chest := Rect2(base.x + 1.0 * u, base.y - 1.3 * u, 2.0 * u, 1.3 * u)
		draw_rect(chest, _p.wood)
		draw_rect(Rect2(chest.position.x, chest.position.y, chest.size.x, 0.35 * u), GOLD)
		draw_circle(chest.get_center(), 0.2 * u, GOLD, true, -1.0, true)
	draw_line(base, top, _p.wood, 0.5 * u)
	draw_circle(top, 0.6 * u, light, true, -1.0, true)

	var wave := sin(_time * 2.0) * 0.3 * u
	var cloth := Rect2(base.x + 0.25 * u, top.y + 0.8 * u, 5.0 * u, 7.5 * u)
	draw_colored_polygon(PackedVector2Array([
		cloth.position, Vector2(cloth.end.x, cloth.position.y + wave),
		Vector2(cloth.end.x, cloth.end.y + 1.2 * u + wave), Vector2(cloth.get_center().x, cloth.end.y + wave * 0.5),
		Vector2(cloth.position.x, cloth.end.y + 1.2 * u),
	]), _p.guild)

	var sun := cloth.get_center() + Vector2(0, -0.6 * u)
	var pulse := 0.5 + 0.5 * sin(_time * 2.5)
	for k in 4:
		draw_circle(sun, (1.4 + k * 0.45 + pulse * 0.3) * u, Color(light, 0.08), true, -1.0, true)
	for i in 8:
		var direction := Vector2.from_angle(TAU * i / 8.0 + _time * 0.3)
		draw_line(sun + direction * 1.1 * u, sun + direction * 1.9 * u, light, 0.25 * u, true)
	draw_circle(sun, 0.9 * u, light, true, -1.0, true)
	draw_circle(sun, 0.5 * u, _p.guild_core, true, -1.0, true)


## The great hall: a hide dome on wooden ribs with bone spikes and tusks, watchtowers from the
## Stronghold on. The Peon Barracks add a weapon rack, the Warchief's Vault a chest by the door.
func _draw_great_hall(base: Vector2, tier: int) -> void:
	var u := _u
	var w := (18.0 + tier * 3.0) * u
	var h := (9.0 + tier * 2.0) * u
	_shadow(base, w * 0.65)
	if tier >= 1:
		for side: float in [-1.0, 1.0]:
			_draw_watchtower(Vector2(base.x + side * (w / 2.0 + 1.0 * u), base.y), 4.5 * u, h + (3.0 + tier) * u, tier >= 2)

	# Bone spikes poking out of the roof; drawn first so the dome hides their roots.
	var spike_count := 3 + tier * 2
	for i in spike_count:
		var a := lerpf(PI * 0.25, PI * 0.75, float(i) / (spike_count - 1))
		var root := base + Vector2(-cos(a) * w / 2.0, -sin(a) * h) * 0.9
		var out := Vector2(-cos(a) * 2.0 / w, -sin(a) / h).normalized()
		var across := Vector2(-out.y, out.x) * 0.7 * u
		_triangle(root - across, root + across, root + out * (3.5 + tier) * u, _p.bone)

	_draw_dome(base, w / 2.0, h, _p.hide)
	var shade := PackedVector2Array([base])  # the sun sets on the left, so the right side is darker
	for i in range(10, 21):
		var a := PI * i / 20.0
		shade.append(base + Vector2(-cos(a) * w / 2.0, -sin(a) * h))
	draw_colored_polygon(shade, Color(SHADOW, 0.22))
	for k: float in [-0.6, -0.2, 0.2, 0.6]:
		var rib := PackedVector2Array()
		for j in 9:
			var t := PI / 2.0 * j / 8.0
			rib.append(Vector2(base.x + k * w / 2.0 * cos(t), base.y - h * sin(t)))
		draw_polyline(rib, _p.hide_dark, 0.5 * u, true)
	draw_rect(Rect2(base.x - w / 2.0, base.y - 1.2 * u, w, 1.2 * u), _p.wood)

	_draw_banner(Rect2(base.x - 1.5 * u, base.y - h + 1.5 * u, 3.0 * u, 3.0 * u))
	_draw_dome(base, 2.6 * u, 4.2 * u, SHADOW)
	for side: float in [-1.0, 1.0]:
		var root := Vector2(base.x + side * 3.6 * u, base.y)
		_draw_tusk(root, root + Vector2(side * 4.5, -1.0) * u, root + Vector2(side * 3.5, -6.0 - tier) * u, 1.4 * u)
		_draw_torch(Vector2(base.x + side * (w / 2.0 - 0.8 * u), base.y), side)

	var barracks := Game.get_upgrade_level("peon_barracks")
	if barracks > 0:  # a weapon rack with a spear per level
		var rack := Vector2(base.x - 7.5 * u, base.y)
		draw_line(rack + Vector2(-1.4, -2.2) * u, rack + Vector2(1.4, -2.2) * u, _p.wood, 0.3 * u)
		for k in barracks:
			var x := rack.x + (-0.9 + k * 0.9) * u
			draw_line(Vector2(x, rack.y), Vector2(x + 0.4 * u, rack.y - 4.0 * u), _p.wood, 0.2 * u)
			_triangle(Vector2(x + 0.25 * u, rack.y - 4.0 * u), Vector2(x + 0.65 * u, rack.y - 4.0 * u), Vector2(x + 0.5 * u, rack.y - 4.9 * u), STEEL)
	if Game.get_upgrade_level("warchiefs_vault") > 0:
		var chest := Rect2(base.x + 5.5 * u, base.y - 1.6 * u, 2.4 * u, 1.6 * u)
		draw_rect(chest, _p.wood.darkened(0.2))
		draw_rect(Rect2(chest.position.x, chest.position.y, chest.size.x, 0.4 * u), GOLD)
		for k in Game.get_upgrade_level("warchiefs_vault"):
			draw_circle(Vector2(chest.position.x + (0.5 + k * 0.7) * u, chest.position.y - 0.2 * u), 0.35 * u, GOLD_LIGHT, true, -1.0, true)


## The war mill: a log shed with a hide roof and a big circular saw that spins faster with the Sawpit,
## and a log pile that grows with Lumber Harvesting.
func _draw_war_mill(c: Vector2) -> void:
	var u := _u * 0.85
	_shadow(c, 7.0 * u)
	var wood: Color = _p.wood
	var logs := 2 + Game.get_upgrade_level("lumber_harvesting")
	for k in logs:  # log pile on the left, ends showing
		var row := floori(k / 3.0)
		var log_end := Vector2(c.x - 5.5 * u + (k % 3) * 1.3 * u + row * 0.65 * u, c.y - 0.6 * u - row * 1.1 * u)
		draw_circle(log_end, 0.6 * u, Color("e0b07a"), true, -1.0, true)
		draw_arc(log_end, 0.6 * u, 0.0, TAU, 12, wood.darkened(0.3), 0.15 * u, true)
	var shed := Rect2(c.x - 1.5 * u, c.y - 5.5 * u, 6.0 * u, 5.5 * u)
	draw_rect(shed, wood)
	for k in range(1, 5):
		var x := shed.position.x + k * shed.size.x / 5.0
		draw_line(Vector2(x, shed.position.y), Vector2(x, shed.end.y), _p.hide_dark, 0.2 * u)
	_triangle(Vector2(shed.position.x - 1.0 * u, shed.position.y), Vector2(shed.end.x + 1.0 * u, shed.position.y),
		Vector2(shed.get_center().x, shed.position.y - 3.5 * u), _p.hide)
	for spike: float in [-2.0, 0.0, 2.0]:
		var tip := Vector2(shed.get_center().x + spike * u, shed.position.y - 3.5 * u + absf(spike) * 0.9 * u)
		_triangle(tip + Vector2(-0.35, 0.6) * u, tip + Vector2(0.35, 0.6) * u, tip - Vector2(0, 1.4 * u), _p.bone)
	draw_rect(Rect2(shed.position.x + 0.8 * u, c.y - 3.2 * u, 2.0 * u, 3.2 * u), SHADOW)
	# The saw
	var hub := Vector2(shed.end.x + 1.6 * u, c.y - 2.2 * u)
	var spin := _time * (2.0 + 3.0 * Game.get_upgrade_level("sawpit"))
	draw_circle(hub, 1.8 * u, STEEL, true, -1.0, true)
	for k in 10:
		var direction := Vector2.from_angle(spin + TAU * k / 10.0)
		var across := direction.orthogonal()
		_triangle(hub + direction * 1.7 * u + across * 0.3 * u, hub + direction * 1.7 * u - across * 0.3 * u, hub + direction * 2.3 * u, STEEL)
	draw_circle(hub, 0.5 * u, wood.darkened(0.3), true, -1.0, true)
	draw_line(hub, hub + Vector2(0, 2.2 * u), wood.darkened(0.3), 0.4 * u)


## A cart of gold on short rails outside the mine.
func _draw_mine_cart() -> void:
	var u := _u
	var start := _mine + Vector2(3.5, 0.4) * u
	var rail: Color = Color(STEEL).darkened(0.35)
	draw_line(start, start + Vector2(9.0 * u, 0), rail, 0.25 * u)
	draw_line(start + Vector2(0, 0.8 * u), start + Vector2(9.0 * u, 0.8 * u), rail, 0.25 * u)
	for k in 6:
		draw_line(start + Vector2(k * 1.6 + 0.4, -0.2) * u, start + Vector2(k * 1.6 + 0.4, 1.0) * u, _p.wood, 0.3 * u)
	var cart := Rect2(start.x + 4.0 * u, start.y - 2.3 * u, 3.6 * u, 2.0 * u)
	_shadow(Vector2(cart.get_center().x, start.y + 0.4 * u), 2.2 * u)
	for gold: Vector2 in [Vector2(0.9, -0.1), Vector2(1.8, -0.4), Vector2(2.7, -0.1)]:
		draw_circle(cart.position + gold * u, 0.65 * u, GOLD, true, -1.0, true)
	draw_rect(cart, rail)
	draw_rect(cart, rail.darkened(0.4), false, 0.2 * u)
	for wheel: float in [0.7, 2.9]:
		draw_circle(Vector2(cart.position.x + wheel * u, cart.end.y + 0.1 * u), 0.5 * u, SHADOW, true, -1.0, true)


## Chopped logs stacked at the forest edge, and a few stumps among the trees.
func _draw_lumber_pile() -> void:
	var u := _u
	var pile := Vector2(size.x * 0.745, _ground + 0.2 * u)
	_shadow(pile, 3.0 * u)
	for k in 6:
		var row := 0 if k < 3 else (1 if k < 5 else 2)
		var first_in_row: int = [0, 3, 5][row]
		var col := k - first_in_row
		var log_end := pile + Vector2((col - 1.0 + row * 0.5) * 1.2, -0.6 - row * 1.0) * u
		draw_circle(log_end, 0.6 * u, Color("e0b07a"), true, -1.0, true)
		draw_arc(log_end, 0.6 * u, 0.0, TAU, 12, Color(_p.trunk), 0.15 * u, true)
	for stump: Vector2 in [Vector2(0.81, 6.5), Vector2(0.9, 7.5), Vector2(0.96, 6.8)]:
		var base := Vector2(size.x * stump.x, _ground + stump.y * u)
		draw_rect(Rect2(base.x - 0.7 * u, base.y - 0.9 * u, 1.4 * u, 0.9 * u), _p.trunk)
		_draw_ellipse(base - Vector2(0, 0.9 * u), Vector2(0.7, 0.3) * u, Color("c99a6a"))


## The campfire where idle peons sit, with flickering flames and a column of smoke.
func _draw_campfire() -> void:
	var u := _u
	var c := Vector2(size.x * CAMPFIRE.x, _ground + CAMPFIRE.y * u)
	_draw_glow(c - Vector2(0, 0.8 * u), 1.2 * u, Color(FLAME, 0.0))
	for k in 3:
		draw_circle(c - Vector2(0, 0.8 * u), (2.4 + k * 1.2) * u, Color(FLAME, 0.05), true, -1.0, true)
	for stone in 7:
		var spot := c + Vector2.from_angle(TAU * stone / 7.0) * Vector2(1.6, 0.6) * u
		draw_circle(spot, 0.35 * u, Color(_p.rock), true, -1.0, true)
	draw_line(c + Vector2(-1.2, 0.2) * u, c + Vector2(1.2, -0.4) * u, _p.trunk, 0.45 * u)
	draw_line(c + Vector2(-1.2, -0.4) * u, c + Vector2(1.2, 0.2) * u, _p.trunk, 0.45 * u)
	for k in 3:
		var flicker := sin(_time * (11.0 + k * 3.0) + k * 1.9)
		var tip := c + Vector2((k - 1.0) * 0.5 + flicker * 0.2, -2.0 - k % 2 * 0.6 - flicker * 0.3) * u
		_triangle(c + Vector2((k - 1.0) * 0.5 - 0.5, -0.2) * u, c + Vector2((k - 1.0) * 0.5 + 0.5, -0.2) * u, tip, FLAME)
	_triangle(c + Vector2(-0.4, -0.2) * u, c + Vector2(0.4, -0.2) * u, c + Vector2(sin(_time * 13.0) * 0.1, -1.3) * u, FLAME_CORE)
	_draw_smoke(c - Vector2(0, 2.5 * u), 0.6, 2)


## Puffs of smoke rising and fading from a chimney or a fire.
func _draw_smoke(origin: Vector2, scale_factor: float, seed_offset: int) -> void:
	var u := _u * scale_factor
	for k in 4:
		var rise := fposmod(_time * 0.35 + k / 4.0 + seed_offset * 0.13, 1.0)
		var puff := origin + Vector2(sin(_time * 0.8 + k + seed_offset) * 0.8 + rise * 2.5, -rise * 9.0) * u
		draw_circle(puff, (0.8 + rise * 1.8) * u, Color(SMOKE, 0.45 * (1.0 - rise)), true, -1.0, true)


## Grass tufts and pebbles scattered over the ground, denser and bigger towards the front.
func _draw_ground_details() -> void:
	var grass := Color(_p.tree_dark).lerp(_p.ground_top, 0.4)
	for detail in _details:
		var depth: float = detail.depth
		var spot := Vector2(size.x * detail.x, lerpf(_horizon + 4.0 * _u, size.y, depth))
		var s: float = detail.size * _u * (0.5 + depth * 0.7)
		if detail.pebble:
			_draw_ellipse(spot, Vector2(0.6, 0.35) * s, Color(_p.rock).darkened(0.15))
			_draw_ellipse(spot - Vector2(0.15, 0.1) * s, Vector2(0.3, 0.15) * s, Color(_p.rock).lightened(0.2))
		else:
			for blade: float in [-0.5, 0.0, 0.5]:
				draw_line(spot, spot + Vector2(blade * 0.6, -1.2 + absf(blade) * 0.4) * s, grass, 0.18 * s)


## The main path, with stones along its edges.
func _draw_path() -> void:
	var u := _u
	var y := _ground + 3.5 * u
	var path_color: Color = _p.path
	draw_line(Vector2(0, y), Vector2(size.x * 0.84, y), Color(path_color, 0.85), 5.0 * u)
	draw_line(Vector2(0, y + 0.8 * u), Vector2(size.x * 0.84, y + 0.8 * u), Color(path_color.darkened(0.15), 0.6), 0.6 * u)
	var x := 1.5 * u
	var k := 0
	while x < size.x * 0.84:
		for edge: float in [-2.7, 2.7]:
			var wobble := sin(k * 3.7 + edge) * 0.3 * u
			_draw_ellipse(Vector2(x + wobble, y + edge * u), Vector2(0.55, 0.3) * u, Color(_p.rock).darkened(0.1))
		x += 3.2 * u
		k += 1


## A soft dark ellipse under something standing on the ground.
func _shadow(base: Vector2, radius: float) -> void:
	_draw_ellipse(base + Vector2(0, 0.2 * _u), Vector2(radius, radius * 0.22), Color(0, 0, 0, 0.22))


## A golden glow under the hovered building and the one whose menu is open.
func _draw_highlight(rects: Dictionary) -> void:
	for id in [_selected, _hover]:
		if id == "" or not rects.has(id):
			continue
		var rect: Rect2 = rects[id]
		var strength := 0.35 if id == _selected else 0.22
		for k in 3:
			_draw_ellipse(Vector2(rect.get_center().x, rect.end.y), Vector2(rect.size.x * (0.55 + k * 0.08), (1.4 + k * 0.5) * _u),
				Color(HIGHLIGHT, strength / (k + 1)))


## The hovered building's name above it.
func _draw_building_label(rects: Dictionary) -> void:
	if _hover == "" or not rects.has(_hover):
		return
	var rect: Rect2 = rects[_hover]
	var font := get_theme_default_font()
	var text := BuildingMenu.display_name(_hover)
	var baseline := Vector2(rect.get_center().x - 100.0, rect.position.y - 0.6 * _u)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 15, 5, Color(0, 0, 0, 0.8))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 15, HIGHLIGHT)


func _draw_watchtower(base: Vector2, width: float, height: float, flag: bool) -> void:
	var rect := Rect2(base.x - width / 2.0, base.y - height, width, height)
	draw_rect(rect, _p.wood)
	for k in 3:
		var x := rect.position.x + width * (k + 1) / 4.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, base.y), _p.hide_dark, 0.25 * _u)
	var deck := Rect2(rect.position.x - 1.0 * _u, rect.position.y - 1.2 * _u, width + 2.0 * _u, 1.2 * _u)
	draw_rect(deck, _p.hide_dark)
	for k in 3:
		var x := deck.position.x + deck.size.x * (k + 0.5) / 3.0
		_triangle(Vector2(x - 0.7 * _u, deck.position.y), Vector2(x + 0.7 * _u, deck.position.y),
			Vector2(x, deck.position.y - 2.5 * _u), _p.bone)
	if flag:
		_draw_flag(Vector2(base.x, deck.position.y - 2.5 * _u), _p.banner)


func _draw_tusk(root: Vector2, control: Vector2, tip: Vector2, thickness: float) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in 11:
		var t := i / 10.0
		var point := Emblem.quad(root, control, tip, t)
		if i == 10:
			left.append(point)
			break
		var ahead := Emblem.quad(root, control, tip, t + 0.05) - Emblem.quad(root, control, tip, maxf(t - 0.05, 0.0))
		var normal := Vector2(-ahead.y, ahead.x).normalized() * thickness * 0.5 * (1.0 - t)
		left.append(point + normal)
		right.append(point - normal)
	right.reverse()
	left.append_array(right)
	draw_colored_polygon(left, _p.bone)


func _draw_torch(base: Vector2, seed_offset: float) -> void:
	draw_line(base, base - Vector2(0, 3.0 * _u), _p.wood, 0.4 * _u)
	var flicker := 0.15 * sin(_time * 13.0 + seed_offset * 5.0)
	var flame := base - Vector2(0, 3.7 * _u)
	draw_circle(flame, (0.8 + flicker) * _u, FLAME, true, -1.0, true)
	draw_circle(flame + Vector2(0, 0.2 * _u), (0.4 + flicker * 0.5) * _u, FLAME_CORE, true, -1.0, true)


func _draw_banner(rect: Rect2) -> void:
	var notch := 0.9 * _u
	var points := PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.end.y + notch),
		Vector2(rect.get_center().x, rect.end.y), Vector2(rect.position.x, rect.end.y + notch),
	])
	draw_colored_polygon(points, _p.banner)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), _p.trim, 0.35 * _u)
	draw_circle(rect.get_center(), 0.6 * _u, _p.trim, true, -1.0, true)


func _draw_flag(pole_base: Vector2, color: Color) -> void:
	var top := pole_base - Vector2(0, 3.0 * _u)
	draw_line(pole_base, top, _p.wood, 0.3 * _u)
	var wave := sin(_time * 4.0 + pole_base.x) * 0.5 * _u
	_triangle(top, top + Vector2(3.0 * _u, 0.8 * _u + wave), top + Vector2(0, 1.6 * _u), color)


## Where a job's workers leave from and drop their loads: the left or right side of the hall door.
func _home_x(job: String) -> float:
	return _hall.x + (-5.0 if job in ["gold", "skins"] else 5.0) * _u


## Where a job's workers go: the mine, the forest edge, off the left edge into the wilds, the tannery frame.
func _site_x(job: String) -> float:
	match job:
		"gold":
			return _mine.x
		"skins":
			return -3.0 * _u
		"leather":
			return size.x * TANNERY_X - 2.6 * _u
	return size.x * 0.79


func _draw_workers() -> void:
	var shown := {}
	var idle := 0
	var miners_inside := 0
	for worker in Game.workers:
		var job: String = worker.job
		if job == Game.IDLE:
			if idle < MAX_IDLE_SHOWN:
				_draw_idle(idle)
			idle += 1
			continue
		var working: bool = worker.phase == Game.Phase.WORKING
		if working and job == "gold":
			miners_inside += 1  # out of sight, inside the mine
			continue
		if working and job == "skins":
			continue  # out of sight, hunting in the wilds
		var index: int = shown.get(job, 0)
		if index >= MAX_WORKERS_SHOWN_PER_JOB:
			continue
		shown[job] = index + 1

		# Spread them over lanes so they don't walk on top of each other; jobs sharing a door interleave.
		var lane := index % 4
		var y := _ground + (2.0 + lane * 1.3 + (0.65 if job in ["skins", "leather"] else 0.0)) * _u
		var home := _home_x(job)
		var site := _site_x(job)
		var outward := signf(site - home)
		if working and job == "lumber":
			_draw_chopper(Vector2(site - lane * 1.6 * _u, y), index)
		elif working:
			_draw_scraper(Vector2(site, _ground + 1.0 * _u), index)
		elif worker.phase == Game.Phase.GOING:
			_draw_worker(Vector2(lerpf(home, site, worker.progress), y), outward, job, false, index)
		else:
			_draw_worker(Vector2(lerpf(site, home, worker.progress), y), -outward, job, true, index)
	if miners_inside > 0:
		_draw_mine_sparks(miners_inside)


## Idle peons stand around in front of the hall, waiting for a job.
## Idle peons warm themselves on both sides of the campfire.
func _draw_idle(index: int) -> void:
	var fire := Vector2(size.x * CAMPFIRE.x, _ground + CAMPFIRE.y * _u)
	var side := -1.0 if index % 2 == 0 else 1.0
	var ring := floori(index / 2.0)
	var spot := fire + Vector2(side * (3.2 + ring * 0.9), -0.6 + ring * 1.1) * _u
	var sway := sin(_time * 1.5 + index) * 0.15 * _u
	_draw_body(spot + Vector2(sway, 0), "", 0.0, 0.0)


## A leatherworker at the tannery frame, scraping the stretched hide.
func _draw_scraper(feet: Vector2, seed: int) -> void:
	var u := _u
	var body := _draw_body(feet, "leather", 0.0, 0.0)
	var stroke := sin(_time * 5.0 + seed * 1.7)
	var hand := Vector2(feet.x + 1.2 * u, body.position.y + (1.0 + stroke * 0.7) * u)
	draw_line(Vector2(feet.x + 0.6 * u, body.position.y + 0.6 * u), hand, _p.skin, 0.35 * u)
	draw_line(hand + Vector2(0, -0.5 * u), hand + Vector2(0, 0.5 * u), STEEL, 0.3 * u)


## A walking peon: the tool on the shoulder on the way out, the load on the back on the way home.
func _draw_worker(feet: Vector2, facing: float, job: String, loaded: bool, seed: int) -> void:
	var u := _u
	var step := _time * 9.0 * Game.get_gear_value(job, "boots") + seed * 1.3
	var swing := sin(step) * 0.6 * u
	var body := _draw_body(feet, job, swing, absf(sin(step)) * 0.4 * u)
	if loaded:
		var back := Vector2(feet.x - facing * 1.3 * u, body.position.y + 0.8 * u)
		var bulk := minf(Game.get_carry(job), 12.0)  # bigger bags, bigger loads
		match job:
			"gold":
				var radius := (0.75 + 0.07 * bulk) * u
				draw_circle(back, radius, GOLD, true, -1.0, true)
				draw_circle(back + Vector2(-0.3, -0.3) * radius, radius * 0.4, GOLD_LIGHT, true, -1.0, true)
			"lumber":
				var length := (3.0 + 0.2 * bulk) * u
				var thickness := (0.9 + 0.05 * bulk) * u
				draw_rect(Rect2(back.x - length / 2.0, back.y - thickness / 2.0, length, thickness), _p.trunk)
				draw_circle(Vector2(back.x - facing * length / 2.0, back.y), thickness / 2.0, LOAD_COLORS.lumber, true, -1.0, true)
			"skins":
				for leg: Vector2 in [Vector2(-1.1, -0.6), Vector2(1.1, -0.6), Vector2(-1.1, 0.6), Vector2(1.1, 0.6)]:
					draw_line(back, back + leg * u, PELT.darkened(0.25), 0.35 * u)
				_draw_ellipse(back, Vector2(1.2, 0.8) * u, PELT)
			"leather":
				draw_rect(Rect2(back.x - 1.2 * u, back.y - 0.55 * u, 2.4 * u, 1.1 * u), LEATHER)
				draw_circle(Vector2(back.x - facing * 1.2 * u, back.y), 0.55 * u, LEATHER.darkened(0.25), true, -1.0, true)
	elif job == "leather":
		pass  # leatherworkers pick up their skins at the tannery
	else:
		var shoulder := Vector2(feet.x, body.position.y + 0.5 * u)
		var grip := shoulder + Vector2(facing * 0.6, 0.6) * u
		var end := shoulder + Vector2(-facing * 1.6, -1.4) * u
		_draw_tool(grip, end, job)


## A peon at the forest edge, swinging an axe at the trees. Better tools swing faster.
func _draw_chopper(feet: Vector2, seed: int) -> void:
	var u := _u
	var body := _draw_body(feet, "lumber", 0.0, 0.0)
	var swing := 0.5 + 0.5 * sin(_time * 6.0 * Game.get_gear_value("lumber", "tools") + seed * 2.0)
	var shoulder := Vector2(feet.x + 0.3 * u, body.position.y + 0.6 * u)
	var angle := lerpf(-PI * 0.8, 0.15, swing)  # raised behind the head, then down into the trunk
	var end := shoulder + Vector2.from_angle(angle) * 2.6 * u
	_draw_tool(shoulder, end, "lumber")
	if swing > 0.85:  # wood chips fly on impact
		for k in 3:
			var chip := end + Vector2(0.8 + k * 0.5, -0.6 - k * 0.4) * u
			draw_circle(chip, 0.22 * u, LOAD_COLORS.lumber, true, -1.0, true)


## Legs, boots (once the job has bought some), body and head. Returns the body rectangle.
func _draw_body(feet: Vector2, job: String, leg_swing: float, bob: float) -> Rect2:
	var u := _u
	_shadow(feet, 1.1 * u)
	var tunic: Color = _p.tunic
	var hips := feet.y - 1.2 * u
	var left_foot := Vector2(feet.x - 0.4 * u + leg_swing, feet.y)
	var right_foot := Vector2(feet.x + 0.4 * u - leg_swing, feet.y)
	draw_line(Vector2(feet.x - 0.4 * u, hips), left_foot, tunic.darkened(0.4), 0.5 * u)
	draw_line(Vector2(feet.x + 0.4 * u, hips), right_foot, tunic.darkened(0.4), 0.5 * u)
	if Game.get_gear_level(job, "boots") > 0:
		for foot: Vector2 in [left_foot, right_foot]:
			draw_rect(Rect2(foot.x - 0.4 * u, foot.y - 0.5 * u, 0.8 * u, 0.6 * u), BOOTS_COLOR)
	var body := Rect2(feet.x - 1.0 * u, hips - 2.4 * u - bob, 2.0 * u, 2.4 * u)
	draw_rect(body, tunic)
	draw_circle(Vector2(feet.x, body.position.y - 0.9 * u), 0.95 * u, _p.skin, true, -1.0, true)
	return body


## A pick (gold), an axe (lumber) or a hunting spear (skins), from the hand to the head.
## Picks and axes are tinted by the job's tools level.
func _draw_tool(grip: Vector2, end: Vector2, job: String) -> void:
	var u := _u
	draw_line(grip, end, _p.wood, 0.3 * u)
	var across := (end - grip).normalized().orthogonal()
	match job:
		"gold":
			var metal := Gear.tool_color(job, Game.get_gear_level(job, "tools"))
			draw_line(end - across * 0.9 * u, end + across * 0.9 * u, metal, 0.35 * u)
		"lumber":
			var metal := Gear.tool_color(job, Game.get_gear_level(job, "tools"))
			draw_line(end, end + across * 0.8 * u, metal, 0.8 * u)
		"skins":
			var along := (end - grip).normalized()
			_triangle(end + across * 0.35 * u, end - across * 0.35 * u, end + along * 1.1 * u, STEEL)


## Glints in the mine entrance while peons are digging inside.
func _draw_mine_sparks(miners: int) -> void:
	for k in mini(miners, 4):
		var glint := maxf(sin(_time * 11.0 + k * 2.3), 0.0)
		var spot := _mine + Vector2(-1.6 + k * 1.1, -1.5 - (k % 2) * 2.2) * _u
		draw_circle(spot, (0.25 + 0.3 * glint) * _u, Color(GOLD_LIGHT, glint), true, -1.0, true)


func _draw_popups() -> void:
	var font := get_theme_default_font()
	for popup in _popups:
		var t: float = popup.age / POPUP_SECONDS
		var color: Color = LOAD_COLORS[popup.job]
		color.a = 1.0 - t * t
		var x: float = _home_x(popup.job) + popup.offset * _u
		var baseline := Vector2(x - 30.0, _ground - (6.0 + t * 6.0) * _u)
		draw_string_outline(font, baseline, popup.text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, 15, 4, Color(0, 0, 0, color.a * 0.7))
		draw_string(font, baseline, popup.text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, 15, color)


func _draw_dome(base: Vector2, half_width: float, height: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 21:
		var a := PI * i / 20.0
		points.append(base + Vector2(-cos(a) * half_width, -sin(a) * height))
	draw_colored_polygon(points, color)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		points.append(center + Vector2.from_angle(TAU * i / 24.0) * radii)
	draw_colored_polygon(points, color)


func _triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c]), color)


func _gradient_rect(rect: Rect2, top: Color, bottom: Color) -> void:
	var corners := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	draw_polygon(corners, PackedColorArray([top, top, bottom, bottom]))
