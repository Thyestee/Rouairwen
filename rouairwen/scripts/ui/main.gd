extends Control
## Screen manager: title screen, Orgrimmar hub and combat. Also shows toasts and confirmations.

var screen: Control
var toast_box: VBoxContainer
var overlay: Control


func _ready() -> void:
	theme = Style.theme()
	Game.toast.connect(show_toast)
	Settings.load_settings()
	# Size the window to the screen, except in test runs, which set their own resolution.
	Settings.apply(get_window(), not ("--smoke" in OS.get_cmdline_user_args()))
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	toast_box = Style.vbox(6)
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	toast_box.offset_left = -380
	toast_box.offset_right = -16
	toast_box.offset_top = 84
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(toast_box)
	show_title()
	if DisplayServer.get_name() != "headless":
		var icons := IconDownloader.new()
		add_child(icons)
		icons.finished.connect(_on_icons_downloaded)
		icons.start()
	if "--smoke" in OS.get_cmdline_user_args():
		var smoke: Node = load("res://tools/smoke_test.gd").new()
		smoke.main = self
		add_child(smoke)
		smoke.run()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_F11:
		Settings.toggle_fullscreen(get_window())
		get_viewport().set_input_as_handled()


## Display mode and UI size.
func open_options() -> void:
	var v := open_overlay(520)
	v.add_child(Style.title("Options"))
	v.add_child(Style.label("Display", 15, Style.C["gold"]))
	var modes := Style.hbox(8)
	var mg := ButtonGroup.new()
	for m in Settings.MODES:
		var b := Style.button(Settings.MODE_NAMES[m])
		b.toggle_mode = true
		b.button_group = mg
		b.button_pressed = Settings.mode == m
		b.custom_minimum_size.x = 140
		b.pressed.connect(_set_mode.bind(m))
		modes.add_child(b)
	v.add_child(modes)
	v.add_child(Style.label("Interface size", 15, Style.C["gold"]))
	var scales := Style.hbox(8)
	var sg := ButtonGroup.new()
	for s in Settings.SCALES:
		var b := Style.button("Fit window" if s == 1.0 else "%d%%" % int(round(s * 100.0)))
		b.toggle_mode = true
		b.button_group = sg
		b.button_pressed = is_equal_approx(Settings.ui_scale, s)
		b.custom_minimum_size.x = 100
		b.pressed.connect(_set_scale.bind(s))
		scales.add_child(b)
	v.add_child(scales)
	var note := Style.label("The interface always stretches to fill the window at any resolution. Smaller sizes leave more room on large screens. F11 toggles fullscreen.", 13, Style.C["muted"])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	var h := Style.hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_child(Style.button("Close", close_overlay, true))
	v.add_child(h)


func _set_mode(m: String) -> void:
	Settings.mode = m
	Settings.apply(get_window(), m == "windowed")
	Settings.save_settings()


func _set_scale(s: float) -> void:
	Settings.ui_scale = s
	Settings.apply(get_window())
	Settings.save_settings()


func _on_icons_downloaded(count: int) -> void:
	if count <= 0:
		return
	show_toast("Downloaded %d WoW icons." % count)
	if screen is HubScreen:
		screen.refresh()


func _set_screen(s: Control) -> void:
	if screen != null:
		screen.queue_free()
	close_overlay()
	screen = s
	add_child(s)
	move_child(s, 0)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_toast(text: String) -> void:
	var p := Style.panel(Color(0.1, 0.04, 0.03, 0.95), Style.C["border_gold"], 1, 8)
	var l := Style.label(text, 15, Style.C["gold"])
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_child(p)
	while toast_box.get_child_count() > 3:
		var old := toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


## A modal overlay holding one centered panel. Returns the panel's content box.
func open_overlay(width := 640.0) -> VBoxContainer:
	close_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var p := Style.panel(Style.C["panel"], Style.C["border_gold"], 2, 16)
	p.custom_minimum_size = Vector2(width, 0)
	center.add_child(p)
	var v := Style.vbox(10)
	p.add_child(v)
	add_child(overlay)
	return v


func close_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null


func confirm(text: String, on_yes: Callable, yes_label := "Yes") -> void:
	var v := open_overlay(440)
	var l := Style.label(text, 16)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var h := Style.hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_child(Style.button("Cancel", close_overlay))
	h.add_child(Style.button(yes_label, _confirm_yes.bind(on_yes), true))
	v.add_child(h)


func _confirm_yes(on_yes: Callable) -> void:
	close_overlay()
	on_yes.call()


# ---------------------------------------------------------------- title

func show_title() -> void:
	var root := Control.new()
	root.add_child(Backdrop.new("orgrimmar"))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var p := Style.panel(Color(0.08, 0.03, 0.02, 0.88), Style.C["border_gold"], 2, 28)
	p.custom_minimum_size = Vector2(460, 0)
	center.add_child(p)
	var v := Style.vbox(12)
	p.add_child(v)
	var emblem := GuildEmblem.new()
	emblem.custom_minimum_size = Vector2(96, 96)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(emblem)
	var t := Style.label("<Lumens>", 52, Style.C["gold"], true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := Style.label("A guild of the Horde, led by a priest", 16, Style.C["muted"])
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(HSeparator.new())
	if Game.has_save():
		var cont := Style.button("Continue", _continue, true)
		cont.custom_minimum_size.y = 44
		v.add_child(cont)
	var ng := Style.button("New Game", _new_game_dialog, not Game.has_save())
	ng.custom_minimum_size.y = 44
	v.add_child(ng)
	v.add_child(Style.button("Options", open_options))
	var q := Style.button("Quit", func(): get_tree().quit())
	v.add_child(q)
	_set_screen(root)


func _continue() -> void:
	if Game.load_game():
		show_hub()
	else:
		show_toast("The save file could not be read.")


func _new_game_dialog() -> void:
	var v := open_overlay(480)
	v.add_child(Style.title("Found the Guild"))
	var txt := Style.label("You are %s, an Undead priest of the Horde, freshly arrived in Orgrimmar with two loyal companions: Nightdude, an Enhancement shaman, and Raynkoy, a Fury warrior. Together you found <Lumens>." % Game.PRIEST_NAME, 15, Style.C["muted"])
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	if Game.has_save():
		var warn := Style.label("Starting a new game will erase your current save.", 13, Style.C["bad"])
		v.add_child(warn)
	var h := Style.hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_child(Style.button("Cancel", close_overlay))
	h.add_child(Style.button("Found <Lumens>", _found_guild, true))
	v.add_child(h)


func _found_guild() -> void:
	Game.new_game()
	show_hub()


# ---------------------------------------------------------------- hub / combat

func show_hub(page := "") -> void:
	var hub := HubScreen.new()
	hub.main = self
	_set_screen(hub)
	if page != "":
		hub.open_page(page)


func start_combat() -> void:
	var c := CombatScreen.new()
	c.main = self
	_set_screen(c)
