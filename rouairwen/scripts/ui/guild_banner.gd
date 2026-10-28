class_name GuildBanner
extends Control
## <Lumens>' banner: the guild logo on a cloth hanging from a rod, ending in a swallowtail, with a
## gold trim. It fills its width; height_for() gives the height that goes with it.

const LOGO := preload("res://assets/lumens_banner.png")
## The logo's own background, continued below it into the tail.
const CLOTH := Color("01060f")
const TRIM := Color("d8b060")
const ROD := Color("5a3418")
## The swallowtail below the logo, as a share of the logo's height.
const TAIL := 0.2

## Sways gently in the wind.
var sway := true
var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func height_for(width: float) -> float:
	var logo_h := width * LOGO.get_height() / LOGO.get_width()
	return _rod(width) + logo_h * (1.0 + TAIL)


static func _rod(width: float) -> float:
	return maxf(4.0, width * 0.035)


func _process(delta: float) -> void:
	if sway and is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	GuildBanner.paint(self, Vector2.ZERO, size.x, _t)


## Paints the banner `w` wide with its rod's top-left at `o`, on any canvas item (the guild hall's
## backdrop hangs one too). `t` drives the sway.
static func paint(ci: CanvasItem, o: Vector2, w: float, t: float) -> void:
	var rod := _rod(w)
	var logo_h := w * LOGO.get_height() / LOGO.get_width()
	var top := rod * 0.6
	var bottom := top + logo_h
	var tail := logo_h * TAIL
	var s := sin(t * 1.1) * w * 0.012
	var cloth := PackedVector2Array([Vector2(0, top), Vector2(w, top), Vector2(w, bottom), Vector2(w + s, bottom + tail),
		Vector2(w * 0.5 + s * 0.6, bottom + tail * 0.4), Vector2(s, bottom + tail), Vector2(0, bottom)])
	for i in cloth.size():
		cloth[i] += o
	ci.draw_colored_polygon(cloth, CLOTH)
	ci.draw_texture_rect(LOGO, Rect2(o + Vector2(0, top), Vector2(w, logo_h)), false)
	var trim := cloth.duplicate()
	trim.append(cloth[0])
	ci.draw_polyline(trim, TRIM, maxf(1.5, w * 0.012), true)
	# The rod it hangs from, with gold caps
	ci.draw_rect(Rect2(o + Vector2(-w * 0.05, 0), Vector2(w * 1.1, rod)), ROD)
	ci.draw_rect(Rect2(o + Vector2(-w * 0.05, 0), Vector2(w * 1.1, rod)), Color(0, 0, 0, 0.5), false, 1.0)
	for x in [-w * 0.05, w * 1.05]:
		ci.draw_circle(o + Vector2(x, rod * 0.5), rod * 0.85, TRIM)
