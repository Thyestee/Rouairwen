class_name Settings
## Display, key binding and testing settings, saved in user://settings.cfg.
##
## The 1280x720 layout is stretched to fill the window (stretch mode canvas_items, aspect expand),
## so the game fits any resolution and aspect ratio. "UI size" shrinks the interface below that fit
## to leave more room on big screens; it never grows past it, which would cut layouts off.
##
## Keys are bound by physical position (a binding made on QWERTY sits on the same key on AZERTY), with
## Shift, Ctrl and Alt allowed, and labelled with what the player's layout prints on that key.

const PATH := "user://settings.cfg"
const MODES := ["windowed", "maximized", "fullscreen"]
const MODE_NAMES := {"windowed": "Windowed", "maximized": "Maximized", "fullscreen": "Fullscreen"}
const SCALES := [1.0, 0.9, 0.8, 0.7]
const MIN_WINDOW := Vector2i(960, 540)
## Experience multiplier while the testing boost is on.
const XP_BOOST := 10

## Action bar slots, then the other bindable actions.
const SLOTS := 14
const DEFAULT_SLOT_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_Q, KEY_E, KEY_R, KEY_T]
const ACTION_NAMES := {"potion": "Drink a mana potion", "pause": "Pause"}
const DEFAULT_KEYS := {"potion": KEY_F, "pause": KEY_SPACE}
## Escape cancels a cast and opens menus, F11 toggles fullscreen.
const RESERVED := [KEY_ESCAPE, KEY_F11]

static var mode := "windowed"
static var ui_scale := 1.0
static var xp_boost := false
## Action -> physical keycode with modifier masks (0: unbound).
static var keys := default_keys()


static func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) == OK:
		mode = cf.get_value("display", "mode", mode)
		ui_scale = cf.get_value("display", "ui_scale", ui_scale)
		xp_boost = cf.get_value("testing", "xp_boost", xp_boost)
		for a in keys:
			keys[a] = int(cf.get_value("keys", a, keys[a]))
	if not (mode in MODES):
		mode = "windowed"
	ui_scale = clampf(ui_scale, SCALES[-1], 1.0)


static func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("display", "mode", mode)
	cf.set_value("display", "ui_scale", ui_scale)
	cf.set_value("testing", "xp_boost", xp_boost)
	for a in keys:
		cf.set_value("keys", a, keys[a])
	cf.save(PATH)


## What every experience gain is multiplied by.
static func xp_rate() -> int:
	return XP_BOOST if xp_boost else 1


# ---------------------------------------------------------------- key bindings

static func slot_action(i: int) -> String:
	return "slot%d" % (i + 1)


static func default_keys() -> Dictionary:
	var out := {}
	for i in SLOTS:
		out[slot_action(i)] = DEFAULT_SLOT_KEYS[i]
	for a in DEFAULT_KEYS:
		out[a] = DEFAULT_KEYS[a]
	return out


static func reset_keys() -> void:
	keys = default_keys()


static func action_name(action: String) -> String:
	if action.begins_with("slot"):
		return "Action button %s" % action.substr(4)
	return ACTION_NAMES.get(action, action)


## The binding a key press matches, from a key event.
static func event_code(ev: InputEventKey) -> int:
	return ev.get_physical_keycode_with_modifiers() if ev.physical_keycode != 0 else ev.get_keycode_with_modifiers()


## The action bound to a key code ("" when none).
static func action_for(code: int) -> String:
	if code == 0:
		return ""
	for a in keys:
		if keys[a] == code:
			return a
	return ""


## Binds a key; the action that had it gets this action's old key, so nothing is lost.
static func bind(action: String, code: int) -> void:
	var other := action_for(code)
	if other != "" and other != action:
		keys[other] = keys[action]
	keys[action] = code


## Whether a key can't be bound (it is reserved, or a lone modifier).
static func reserved(code: int) -> bool:
	var base := code & KEY_CODE_MASK
	return base in RESERVED or base in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_NONE]


## What the player's keyboard prints on a bound key ("A" for the Q spot on AZERTY), with modifiers.
static func key_label(action: String) -> String:
	var code: int = keys.get(action, 0)
	if code == 0:
		return ""
	var base := code & KEY_CODE_MASK
	if DisplayServer.get_name() != "headless":
		var local := DisplayServer.keyboard_get_label_from_physical(base)
		if local != KEY_NONE:
			base = local
	return OS.get_keycode_string(base | (code & KEY_MODIFIER_MASK))


## The short form shown on action buttons ("s-1" for Shift+1), like WoW's bars.
static func key_short(action: String) -> String:
	return key_label(action).replace("Shift+", "s-").replace("Ctrl+", "c-").replace("Alt+", "a-").replace("Command+", "m-")


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
