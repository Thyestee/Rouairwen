class_name GuildEmblem
extends Control
## The Lumens crest: a violet shield bearing a radiant golden sun.

var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := size
	var c := Vector2(s.x / 2, s.y * 0.46)
	var m := minf(s.x, s.y)
	var shield := PackedVector2Array([Vector2(s.x * 0.12, s.y * 0.06), Vector2(s.x * 0.88, s.y * 0.06), Vector2(s.x * 0.86, s.y * 0.55),
		Vector2(s.x * 0.5, s.y * 0.96), Vector2(s.x * 0.14, s.y * 0.55)])
	draw_colored_polygon(shield, Color("3b2675"))
	draw_polyline(shield + PackedVector2Array([shield[0]]), Color("ffd86b"), maxf(2.0, m * 0.04))
	var rot := _t * 0.25
	for i in 12:
		var a := rot + i * TAU / 12.0
		var inner := c + Vector2.from_angle(a) * m * 0.17
		var outer := c + Vector2.from_angle(a) * m * (0.33 if i % 2 == 0 else 0.27)
		draw_line(inner, outer, Color("ffd86b"), maxf(1.5, m * 0.035))
	draw_circle(c, m * 0.15, Color("ffd86b"))
	draw_circle(c, m * 0.1, Color("fff4cf"))
