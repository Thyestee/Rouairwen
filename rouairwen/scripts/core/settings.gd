class_name Settings
## Display settings, saved in user://settings.cfg.
##
## The 1280x720 layout is stretched to fill the window (stretch mode canvas_items, aspect expand),
## so the game fits any resolution and aspect ratio. "UI size" shrinks the interface below that fit
## to leave more room on big screens; it never grows past it, which would cut layouts off.

const PATH := "user://settings.cfg"
const MODES := ["windowed", "maximized", "fullscreen"]
const MODE_NAMES := {"windowed": "Windowed", "maximized": "Maximized", "fullscreen": "Fullscreen"}
const SCALES := [1.0, 0.9, 0.8, 0.7]
const MIN_WINDOW := Vector2i(960, 540)

static var mode := "windowed"
static var ui_scale := 1.0


static func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) == OK:
		mode = cf.get_value("display", "mode", mode)
		ui_scale = cf.get_value("display", "ui_scale", ui_scale)
	if not (mode in MODES):
		mode = "windowed"
	ui_scale = clampf(ui_scale, SCALES[-1], 1.0)


static func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("display", "mode", mode)
	cf.set_value("display", "ui_scale", ui_scale)
	cf.save(PATH)


## Applies the window mode and UI size. `first_launch` sizes a windowed game to the screen.
static func apply(window: Window, first_launch := false) -> void:
	window.min_size = MIN_WINDOW
	window.content_scale_factor = ui_scale
	if DisplayServer.get_name() == "headless":
		return
	match mode:
		"fullscreen":
			window.mode = Window.MODE_FULLSCREEN
		"maximized":
			window.mode = Window.MODE_MAXIMIZED
		_:
			if window.mode != Window.MODE_WINDOWED:
				window.mode = Window.MODE_WINDOWED
				first_launch = true
			if first_launch:
				_fit_to_screen(window)


## A 16:9 window covering about 80% of the screen, centered.
static func _fit_to_screen(window: Window) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var area := DisplayServer.screen_get_usable_rect(screen)
	var w := int(area.size.x * 0.8)
	var h := int(w * 9.0 / 16.0)
	if h > area.size.y * 0.85:
		h = int(area.size.y * 0.85)
		w = int(h * 16.0 / 9.0)
	window.size = Vector2i(maxi(w, MIN_WINDOW.x), maxi(h, MIN_WINDOW.y))
	window.position = area.position + (area.size - window.size) / 2


static func toggle_fullscreen(window: Window) -> void:
	mode = "windowed" if mode == "fullscreen" else "fullscreen"
	apply(window)
	save_settings()
