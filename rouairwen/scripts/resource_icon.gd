class_name ResourceIcon
extends Control
## Small drawn icon for a resource: "gold" (a coin), "lumber" (a log), "skins" (a pelt),
## "leather" (a stitched square), "cloth" (a bolt of cloth), "food" (a drumstick) or "gear" (a sword).

@export var kind := "gold":
	set(value):
		kind = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(22, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	match kind:
		"gold":
			draw_circle(c, r * 0.9, Color("a8780a"), true, -1.0, true)
			draw_circle(c, r * 0.72, Color("f5c542"), true, -1.0, true)
			draw_circle(c + Vector2(-0.25, -0.25) * r, r * 0.22, Color("fff1a8"), true, -1.0, true)
		"lumber":
			draw_set_transform(c, -0.45, Vector2.ONE)
			draw_rect(Rect2(-r * 0.95, -r * 0.4, r * 1.6, r * 0.8), Color("8b5a2b"))
			draw_line(Vector2(-r * 0.8, -r * 0.12), Vector2(r * 0.4, -r * 0.12), Color("6b4220"), r * 0.1)
			draw_line(Vector2(-r * 0.6, r * 0.16), Vector2(r * 0.5, r * 0.16), Color("6b4220"), r * 0.1)
			draw_circle(Vector2(r * 0.65, 0), r * 0.42, Color("e0b07a"), true, -1.0, true)
			draw_arc(Vector2(r * 0.65, 0), r * 0.42, 0.0, TAU, 24, Color("6b4220"), r * 0.12, true)
			draw_arc(Vector2(r * 0.65, 0), r * 0.18, 0.0, TAU, 16, Color("a8763f"), r * 0.08, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"skins":
			var hide := Color("9a6440")
			for corner: Vector2 in [Vector2(-0.6, -0.55), Vector2(0.6, -0.55), Vector2(-0.6, 0.55), Vector2(0.6, 0.55)]:
				draw_circle(c + corner * r, r * 0.22, hide.darkened(0.25), true, -1.0, true)
			_draw_ellipse(c, Vector2(r * 0.62, r * 0.78), hide)
			draw_circle(c + Vector2(-0.15, -0.2) * r, r * 0.14, hide.darkened(0.35), true, -1.0, true)
			draw_circle(c + Vector2(0.2, 0.25) * r, r * 0.1, hide.darkened(0.35), true, -1.0, true)
		"leather":
			var square := Rect2(c - Vector2(r, r) * 0.75, Vector2(r, r) * 1.5)
			draw_rect(square, Color("c58b4f"))
			var stitch := square.grow(-r * 0.2)
			for side: Array in [[stitch.position, Vector2(stitch.end.x, stitch.position.y)],
					[Vector2(stitch.end.x, stitch.position.y), stitch.end],
					[stitch.end, Vector2(stitch.position.x, stitch.end.y)],
					[Vector2(stitch.position.x, stitch.end.y), stitch.position]]:
				draw_dashed_line(side[0], side[1], Color("7a4a22"), r * 0.08, r * 0.2)
		"cloth":
			draw_rect(Rect2(c.x - r * 0.8, c.y - r * 0.55, r * 1.3, r * 1.1), Color("e9e1cf"))
			draw_rect(Rect2(c.x - r * 0.8, c.y - r * 0.1, r * 1.3, r * 0.2), Color("b55aa0"))
			draw_circle(Vector2(c.x + r * 0.5, c.y), r * 0.55, Color("d6ccb6"), true, -1.0, true)
			draw_arc(Vector2(c.x + r * 0.5, c.y), r * 0.3, 0.0, TAU, 16, Color("a89c86"), r * 0.08, true)
		"gear":
			draw_set_transform(c, -PI / 4.0, Vector2.ONE)
			draw_rect(Rect2(-r * 0.12, -r * 0.95, r * 0.24, r * 1.3), Color("d4cec3"))
			draw_rect(Rect2(-r * 0.45, r * 0.3, r * 0.9, r * 0.16), Color("c9a046"))
			draw_rect(Rect2(-r * 0.1, r * 0.46, r * 0.2, r * 0.42), Color("6b4424"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"food":
			var bone := Color("f1e6d0")
			draw_line(c + Vector2(0.05, 0.05) * r, c + Vector2(0.62, 0.62) * r, bone, r * 0.26)
			draw_circle(c + Vector2(0.72, 0.52) * r, r * 0.17, bone, true, -1.0, true)
			draw_circle(c + Vector2(0.52, 0.72) * r, r * 0.17, bone, true, -1.0, true)
			draw_circle(c + Vector2(-0.18, -0.18) * r, r * 0.62, Color("b5523b"), true, -1.0, true)
			draw_circle(c + Vector2(-0.34, -0.36) * r, r * 0.2, Color("dc8a6a"), true, -1.0, true)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 20:
		points.append(center + Vector2.from_angle(TAU * i / 20.0) * radii)
	draw_colored_polygon(points, color)
