class_name KeyBindPage
extends VBoxContainer
## Key bindings: click an action's key, then press the new one (Shift, Ctrl and Alt combinations work).
## Escape cancels. A key already in use swaps with the action being changed.

var main
## The action waiting for a key ("" when none).
var waiting := ""


func rebuild() -> void:
	add_theme_constant_override("separation", 10)
	Style.clear(self)
	add_child(Style.title("Key Bindings"))
	var note := Style.label("Click a key, then press the new one; Shift, Ctrl and Alt combinations work. Escape cancels. " +
		"A key already in use swaps with it. Keys belong to action bar slots: change which spell sits in a slot in the Spellbook.",
		13, Style.C["muted"])
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
	var bar: Array = Game.action_bar() if Game.data.has("priest") else []
	var cols := Style.hbox(20)
	var half := ceili(Settings.SLOTS / 2.0)
	for c in 2:
		var col := Style.vbox(4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for i in range(c * half, mini((c + 1) * half, Settings.SLOTS)):
			col.add_child(_row(Settings.slot_action(i), bar[i] if i < bar.size() else ""))
		cols.add_child(col)
	add_child(cols)
	add_child(HSeparator.new())
	var other := Style.hbox(20)
	for a in Settings.ACTION_NAMES:
		var r := _row(a, "")
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		other.add_child(r)
	add_child(other)
	var h := Style.hbox(10)
	h.add_child(Style.button("Reset to defaults", _reset))
	h.add_child(Style.spacer())
	h.add_child(Style.button("Done", _done, true))
	add_child(h)


## One action: its spell (for a slot), its name and its key.
func _row(action: String, spell_id: String) -> Control:
	var h := Style.hbox(8)
	var ic: Control
	if spell_id != "":
		ic = SpellIcon.new(Spells.BOOK[spell_id]["icon"], WowIcons.spell(spell_id, Game.level()))
	elif action == "potion":
		ic = SpellIcon.new("mana_potion", WowIcons.consumable(ShopData.rank_name("mana_potion", 0)))
	else:
		ic = Control.new()
	ic.custom_minimum_size = Vector2(30, 30)
	h.add_child(ic)
	var title := Settings.action_name(action)
	if action.begins_with("slot"):
		title = "%s. %s" % [action.substr(4), Spells.display_name(spell_id, Game.level()) if spell_id != "" else "(empty)"]
	var l := Style.label(title, 15, Style.C["text"] if spell_id != "" or not action.begins_with("slot") else Style.C["dim"])
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var label := Settings.key_label(action)
	var b := Style.button("Press a key..." if waiting == action else (label if label != "" else "Not bound"), _wait.bind(action), waiting == action)
	b.custom_minimum_size = Vector2(130, 32)
	h.add_child(b)
	return h


func _wait(action: String) -> void:
	waiting = "" if waiting == action else action
	rebuild()


func _input(ev: InputEvent) -> void:
	if waiting == "" or not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	get_viewport().set_input_as_handled()
	if ev.keycode == KEY_ESCAPE or ev.physical_keycode == KEY_ESCAPE:
		waiting = ""
		rebuild()
		return
	var code := Settings.event_code(ev)
	if Settings.reserved(code):
		# A lone Shift/Ctrl/Alt is the start of a combination; F11 and Escape are taken.
		if (code & KEY_CODE_MASK) == KEY_F11:
			main.show_toast("F11 toggles fullscreen and can't be bound.")
		return
	Settings.bind(waiting, code)
	Settings.save_settings()
	waiting = ""
	rebuild()


func _reset() -> void:
	Settings.reset_keys()
	Settings.save_settings()
	waiting = ""
	rebuild()


func _done() -> void:
	main.close_overlay()
	if main.screen is HubScreen:
		main.screen.refresh()
