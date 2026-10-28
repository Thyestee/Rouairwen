class_name DamageMeter
extends Control
## A meter in the style of the Details! addon: one bar per party member, in class colours, for damage
## done, healing done (absorbs included) or damage taken, with per second and share of the total.
## It shows the current fight or the whole outing. Click the title to switch what it shows, its
## right side to switch fight/outing; hover a bar for the breakdown by ability.

const MODES := [["damage", "Damage Done", "damage_by"], ["healing", "Healing Done", "healing_by"],
	["taken", "Damage Taken", "taken_by"]]
const TITLE := 20.0
const ROW := 19.0
const GAP := 1.0

## Kept between fights and outings, like the addon remembers its window.
static var mode := 0
static var overall := false

var engine: CombatEngine
## Finished fights of this outing (name -> totals, see snapshot) and how long they lasted.
var _past := {}
var _past_time := 0.0
## [rect, name, entry] of each bar as last drawn.
var _rows: Array = []
var _since := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


## Follows a new fight; the one before it joins the outing's totals.
func set_engine(e: CombatEngine) -> void:
	if engine != null and engine != e:
		DamageMeter.merge(_past, DamageMeter.snapshot(engine))
		_past_time += engine.time
	engine = e
	queue_redraw()


## A fight's totals per party member: name -> {class_id, damage, healing, taken, damage_by, healing_by, taken_by}.
static func snapshot(e: CombatEngine) -> Dictionary:
	var out := {}
	for m in e.party:
		out[m.name] = {"class_id": m.class_id, "damage": m.damage_done, "healing": m.healing_done, "taken": m.damage_taken,
			"damage_by": m.damage_by.duplicate(), "healing_by": m.healing_by.duplicate(), "taken_by": m.taken_by.duplicate()}
	return out


static func merge(into: Dictionary, add: Dictionary) -> void:
	for n in add:
		if not into.has(n):
			into[n] = {"class_id": add[n]["class_id"], "damage": 0.0, "healing": 0.0, "taken": 0.0,
				"damage_by": {}, "healing_by": {}, "taken_by": {}}
		for k in ["damage", "healing", "taken"]:
			into[n][k] += add[n][k]
		for k in ["damage_by", "healing_by", "taken_by"]:
			for label in add[n][k]:
				into[n][k][label] = into[n][k].get(label, 0.0) + add[n][k][label]


## The shown segment's totals and its length in seconds.
func segment() -> Array:
	if engine == null:
		return [{}, 0.0]
	if not overall:
		return [DamageMeter.snapshot(engine), engine.time]
	var all := {}
	DamageMeter.merge(all, _past)
	DamageMeter.merge(all, DamageMeter.snapshot(engine))
	return [all, _past_time + engine.time]


## "45.2K", "1.23M": numbers the way the addon writes them.
static func short(v: float) -> String:
	if v >= 1000000.0:
		return "%.2fM" % (v / 1000000.0)
	if v >= 1000.0:
		return "%.1fK" % (v / 1000.0)
	return str(int(v))


func _process(delta: float) -> void:
	_since += delta
	if _since >= 0.2:
		_since = 0.0
		queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.position.y <= TITLE:
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.position.x > size.x * 0.62:
			overall = not overall
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			mode = (mode + 1) % MODES.size()
		elif ev.button_index == MOUSE_BUTTON_RIGHT:
			mode = (mode + MODES.size() - 1) % MODES.size()
		else:
			return
		accept_event()
		queue_redraw()


func _draw() -> void:
	var font := Style.bold_font()
	var w := size.x
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.035, 0.04, 0.82))
	# Title bar
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, TITLE), Vector2(0, TITLE)]),
		PackedColorArray([Color(0.2, 0.2, 0.22), Color(0.2, 0.2, 0.22), Color(0.09, 0.09, 0.1), Color(0.09, 0.09, 0.1)]))
	draw_line(Vector2(0, TITLE), Vector2(w, TITLE), Color(0, 0, 0), 1.0)
	draw_string(font, Vector2(6, TITLE - 6), MODES[mode][1], HORIZONTAL_ALIGNMENT_LEFT, w * 0.6, 12, Color(0.95, 0.95, 0.95))
	draw_string(font, Vector2(0, TITLE - 6), "Overall" if overall else "Current", HORIZONTAL_ALIGNMENT_RIGHT, w - 6, 11,
		Color(1.0, 0.82, 0.25) if overall else Color(0.7, 0.7, 0.72))
	_rows.clear()
	var seg := segment()
	var data: Dictionary = seg[0]
	var secs: float = maxf(seg[1], 1.0)
	var key: String = MODES[mode][0]
	var names := data.keys().filter(func(n): return data[n][key] >= 1.0)
	names.sort_custom(func(a, b): return data[a][key] > data[b][key])
	if names.is_empty():
		draw_string(font, Vector2(8, TITLE + 18), "Nothing yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))
		return
	var top: float = data[names[0]][key]
	var total := 0.0
	for n in names:
		total += data[n][key]
	for i in names.size():
		var y := TITLE + 2.0 + i * (ROW + GAP)
		if y + ROW > size.y:
			break
		var e: Dictionary = data[names[i]]
		var v: float = e[key]
		var col := ClassData.color(e["class_id"])
		var bar := Rect2(ROW, y, w - ROW, ROW)
		draw_rect(bar, Color(0.1, 0.1, 0.11, 0.7))
		var fw: float = bar.size.x * v / top
		var light := col.lightened(0.12)
		var dark := col.darkened(0.25)
		draw_polygon(PackedVector2Array([bar.position, bar.position + Vector2(fw, 0), bar.position + Vector2(fw, ROW), bar.position + Vector2(0, ROW)]),
			PackedColorArray([light, light, dark, dark]))
		# Class icon
		var icon := Rect2(0, y, ROW, ROW)
		var tex := WowIcons.texture(WowIcons.class_icon(e["class_id"]))
		if tex != null:
			draw_texture_rect_region(tex, icon, Rect2(Vector2.ONE * tex.get_width() * 0.07, Vector2.ONE * tex.get_width() * 0.86))
		else:
			draw_rect(icon, col.darkened(0.4))
		var right := "%s (%s, %.1f%%)" % [DamageMeter.short(v), DamageMeter.short(v / secs), 100.0 * v / maxf(total, 1.0)]
		var rw := font.get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var ty := y + ROW - 5.0
		var left := "%d. %s" % [i + 1, names[i]]
		_text(font, Vector2(ROW + 4, ty), left, w - ROW - rw - 14, 12)
		_text(font, Vector2(w - rw - 4, ty), right, rw + 2, 11)
		_rows.append([Rect2(0, y, w, ROW), names[i], e])


## White text with the addon's dark shadow.
func _text(font: Font, pos: Vector2, text: String, width: float, fs: int) -> void:
	draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, Color(0, 0, 0, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, Color.WHITE)


func _get_tooltip(at_position: Vector2) -> String:
	if at_position.y <= TITLE:
		return "[b]%s[/b]\nClick to switch between damage done, healing done and damage taken (right-click goes back).\n" % MODES[mode][1] + \
			"Click [color=#ffd86b]%s[/color] for %s." % ["Overall" if overall else "Current", "this fight only" if overall else "the whole outing so far"]
	for r in _rows:
		if r[0].has_point(at_position):
			return _breakdown(r[1], r[2])
	return ""


## The bar's abilities, biggest first, like the addon's tooltip.
func _breakdown(unit_name: String, e: Dictionary) -> String:
	var by: Dictionary = e[MODES[mode][2]]
	var total: float = e[MODES[mode][0]]
	var col := ClassData.color(e["class_id"]).to_html(false)
	var s := "[b][color=#%s]%s[/color][/b]  [color=#c0c0c0]%s: %s[/color]" % [col, unit_name, MODES[mode][1], DamageMeter.short(total)]
	var labels := by.keys()
	labels.sort_custom(func(a, b): return by[a] > by[b])
	for label in labels.slice(0, 10):
		s += "\n%s  [color=#ffffff]%s[/color] [color=#c0c0c0](%.1f%%)[/color]" % [label, DamageMeter.short(by[label]), 100.0 * by[label] / maxf(total, 1.0)]
	return s


func _make_custom_tooltip(for_text: String) -> Object:
	return TipButton.make_tip(for_text, 280)
