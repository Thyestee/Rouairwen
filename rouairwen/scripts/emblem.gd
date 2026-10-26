class_name Emblem
extends Control
## A crest drawn in code: "horde" (a spiked war disc with crossed axes)
## or "lumens" (the guild's radiant sun on a violet disc).

const STEEL := Color("d4cec3")
const STEEL_DARK := Color("6e655c")
const IRON := Color("2b201b")

@export var kind := "horde":
	set(value):
		kind = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size / 2.0
	var s := minf(size.x, size.y) / 2.0 * 0.9
	match kind:
		"horde":
			_draw_war_disc(center, s)
		"lumens":
			_draw_sun(center, s)


func _draw_war_disc(center: Vector2, s: float) -> void:
	var p := HordeStyle.PALETTE
	var spikes := PackedVector2Array()
	for i in 28:
		var radius := s if i % 2 == 0 else s * 0.8
		spikes.append(center + Vector2.from_angle(TAU * i / 28.0 - PI / 2.0) * radius)
	draw_colored_polygon(spikes, IRON)
	_closed_line(spikes, p.border, s * 0.03)
	draw_circle(center, s * 0.72, p.banner, true, -1.0, true)
	draw_arc(center, s * 0.72, 0.0, TAU, 48, p.bone, s * 0.05, true)

	# Two crossed axes, blades facing outward
	for side: float in [-1.0, 1.0]:
		draw_set_transform(center, side * 0.55, Vector2.ONE)
		draw_rect(Rect2(-0.045 * s, -0.62 * s, 0.09 * s, 1.22 * s), p.wood)
		var blade := PackedVector2Array()
		for point: Vector2 in [Vector2(0.03, -0.64), Vector2(0.3, -0.8), Vector2(0.4, -0.56), Vector2(0.3, -0.3), Vector2(0.03, -0.42)]:
			blade.append(Vector2(point.x * side, point.y) * s)
		draw_colored_polygon(blade, STEEL)
		_closed_line(blade, STEEL_DARK, s * 0.025)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sun(center: Vector2, s: float) -> void:
	var p := HordeStyle.PALETTE
	var light: Color = p.guild_light
	draw_circle(center, s * 0.95, p.guild, true, -1.0, true)
	draw_arc(center, s * 0.95, 0.0, TAU, 64, light, s * 0.06, true)
	for i in 16:
		var direction := Vector2.from_angle(TAU * i / 16.0 - PI / 2.0)
		var across := Vector2(-direction.y, direction.x) * s * 0.07
		var length := 0.8 if i % 2 == 0 else 0.6
		draw_colored_polygon(PackedVector2Array([
			center + direction * s * 0.3 + across,
			center + direction * s * length,
			center + direction * s * 0.3 - across,
		]), light)
	draw_circle(center, s * 0.32, light, true, -1.0, true)
	draw_circle(center, s * 0.22, p.guild_core, true, -1.0, true)


func _closed_line(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


static func quad(a: Vector2, control: Vector2, b: Vector2, t: float) -> Vector2:
	return a * (1.0 - t) * (1.0 - t) + control * 2.0 * (1.0 - t) * t + b * t * t
