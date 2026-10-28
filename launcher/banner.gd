extends Control
## <Lumens>' banner, as the game draws it: the guild logo on a cloth hanging from a rod, ending in a
## swallowtail, with a gold trim. It fills its width; height_for() gives the height that goes with it.

const LOGO := preload("res://lumens_banner.png")
const CLOTH := Color("01060f")
const TRIM := Color("d8b060")
const ROD := Color("5a3418")
## The swallowtail below the logo, as a share of the logo's height.
const TAIL := 0.2

var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func height_for(width: float) -> float:
	return _rod(width) + width * LOGO.get_height() / LOGO.get_width() * (1.0 + TAIL)


static func _rod(width: float) -> float:
	return maxf(4.0, width * 0.035)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var rod := _rod(w)
	var logo_h := w * LOGO.get_height() / LOGO.get_width()
	var top := rod * 0.6
	var bottom := top + logo_h
	var tail := logo_h * TAIL
	var s := sin(_t * 1.1) * w * 0.012
	var cloth := PackedVector2Array([Vector2(0, top), Vector2(w, top), Vector2(w, bottom), Vector2(w + s, bottom + tail),
		Vector2(w * 0.5 + s * 0.6, bottom + tail * 0.4), Vector2(s, bottom + tail), Vector2(0, bottom)])
	# A shadow on the gate behind it
	var shadow := cloth.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(6, 6)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	draw_colored_polygon(cloth, CLOTH)
	draw_texture_rect(LOGO, Rect2(0, top, w, logo_h), false)
	var trim := cloth.duplicate()
	trim.append(cloth[0])
	draw_polyline(trim, TRIM, maxf(1.5, w * 0.012), true)
	draw_rect(Rect2(-w * 0.05, 0, w * 1.1, rod), ROD)
	draw_rect(Rect2(-w * 0.05, 0, w * 1.1, rod), Color(0, 0, 0, 0.5), false, 1.0)
	for x in [-w * 0.05, w * 1.05]:
		draw_circle(Vector2(x, rod * 0.5), rod * 0.85, TRIM)
