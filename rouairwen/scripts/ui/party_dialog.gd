class_name PartyDialog
extends Node
## Picks the guildmates who go on an activity, and shows party power and supplies.

var main
var act := {}
var chosen: Array = []
var box: VBoxContainer
var list: VBoxContainer
var power_label: RichTextLabel
var go_button: Button


func setup(p_main, p_act: Dictionary) -> void:
	main = p_main
	act = p_act
	box = main.open_overlay(760)
	box.add_child(self)
	chosen = _auto_pick()
	_build()


func slots() -> int:
	return act["party_size"] - 1


## Strongest members first, but bring a tank in dungeons and raids when the guild has one.
func _auto_pick() -> Array:
	var ms: Array = Game.members().duplicate()
	ms.sort_custom(func(a, b): return Game.member_power(a) > Game.member_power(b))
	var pick := []
	var want := {"tank": 1 if act["party_size"] >= 5 else 0}
	for role in want:
		for m in ms:
			if want[role] <= 0:
				break
			if ClassData.SPECS[m["spec"]]["role"] == role and not (m["id"] in pick):
				pick.append(m["id"])
				want[role] -= 1
	# Then damage dealers, strongest first; extra tanks only fill leftover slots.
	for m in ms:
		if pick.size() >= slots():
			break
		if not (m["id"] in pick) and ClassData.SPECS[m["spec"]]["role"] in ["melee", "ranged"]:
			pick.append(m["id"])
	for m in ms:
		if pick.size() >= slots():
			break
		if not (m["id"] in pick):
			pick.append(m["id"])
	return pick.slice(0, slots())


func _build() -> void:
	for c in box.get_children():
		if c != self:
			c.queue_free()
	var h := Style.hbox(10)
	var tv := Style.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(Style.title(act["title"], 26))
	tv.add_child(Style.label("%s · Level %d · %s · %d fight%s" % [act["place"], act["level"], act["kind_label"], act["fights"].size(), "" if act["fights"].size() == 1 else "s"], 14, Style.C["muted"]))
	var g := Activities.guarantee_bb(act)
	if g != "":
		tv.add_child(Style.rich(g + " [color=#8a7262]on completion[/color]", 14))
	h.add_child(tv)
	box.add_child(h)
	box.add_child(Style.label("Choose up to %d guildmate%s to join you:" % [slots(), "" if slots() == 1 else "s"], 15, Style.C["gold"]))
	list = Style.vbox(4)
	var sc := Style.scroll(list)
	sc.custom_minimum_size.y = 300
	box.add_child(sc)
	var ms: Array = Game.members().duplicate()
	ms.sort_custom(func(a, b): return Game.member_power(a) > Game.member_power(b))
	for m in ms:
		list.add_child(_row(m))
	power_label = Style.rich("", 16)
	box.add_child(power_label)
	box.add_child(_supplies())
	var foot := Style.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_child(Style.button("Cancel", main.close_overlay))
	go_button = Style.button("Set out!", _go, true)
	go_button.custom_minimum_size = Vector2(160, 40)
	foot.add_child(go_button)
	box.add_child(foot)
	_update()


func _row(m: Dictionary) -> Control:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = m["id"] in chosen
	b.custom_minimum_size = Vector2(0, 40)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.toggled.connect(_toggle.bind(m["id"], b))
	var h := Style.hbox(10)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp: Dictionary = ClassData.SPECS[m["spec"]]
	var n := Style.label(m["name"], 16, Style.class_color(m["class"]))
	n.custom_minimum_size.x = 150
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(n)
	var s := Style.label("%s %s" % [sp["name"], ClassData.class_name_of(m["class"])], 14, Style.C["muted"])
	s.custom_minimum_size.x = 210
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(s)
	var r := Style.label(Style.role_label(sp["role"]), 14, Style.C["text"])
	r.custom_minimum_size.x = 70
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(r)
	var tb := Style.tier_badge(m["tier"], 18)
	tb.custom_minimum_size.x = 50
	tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tb)
	var pw := Style.label("power %d" % int(100 * Game.member_power(m)), 14, Style.C["muted"])
	pw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(pw)
	b.add_child(h)
	return b


func _toggle(on: bool, id, b: Button) -> void:
	if on and not (id in chosen):
		if chosen.size() >= slots():
			b.set_pressed_no_signal(false)
			Game.toast.emit("This activity only takes %d guildmates." % slots())
			return
		chosen.append(id)
	elif not on:
		chosen.erase(id)
	_update()


func _update() -> void:
	var have := Game.party_power(chosen)
	var need := Game.recommended_power(act)
	var col := "6ee06e" if have >= need else ("ffb040" if have >= need * 0.88 else "ff5a4a")
	var roles := {"tank": 0, "melee": 0, "ranged": 0}
	for id in chosen:
		roles[ClassData.SPECS[Game.member(id)["spec"]]["role"]] += 1
	var warn := ""
	if act["party_size"] >= 5 and roles["tank"] == 0:
		warn = "\n[color=#ffb040]No tank: enemies will hit your damage dealers much harder.[/color]"
	if chosen.size() < slots():
		warn += "\n[color=#ffb040]%d empty slot%s: the fights are sized for a full party.[/color]" % [slots() - chosen.size(), "" if slots() - chosen.size() == 1 else "s"]
	power_label.text = "[color=#c09f86]Party:[/color] %d/%d   [color=#c09f86]Tanks[/color] %d  [color=#c09f86]Melee[/color] %d  [color=#c09f86]Ranged[/color] %d     [color=#c09f86]Power:[/color] [color=#%s]%d[/color] / %d recommended%s" % [
		chosen.size() + 1, act["party_size"], roles["tank"], roles["melee"], roles["ranged"], col, have, need, warn]
	if go_button:
		go_button.disabled = chosen.is_empty()


func _supplies() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_child(Style.label("Supplies:", 14, Style.C["gold"]))
	for cat in ShopData.ORDER:
		var n := Game.stock(cat)
		var cb := CheckBox.new()
		var r := Game.best_stock_rank(cat)
		cb.text = "%s ×%d" % [ShopData.rank_name(cat, r) if r >= 0 else ShopData.CATEGORIES[cat]["name"], n]
		cb.button_pressed = Game.data["use"].get(cat, true) and n > 0
		cb.disabled = n == 0
		cb.focus_mode = Control.FOCUS_NONE
		cb.add_theme_font_size_override("font_size", 13)
		cb.toggled.connect(_use.bind(cat))
		flow.add_child(cb)
	if not Game.data["world_buff"].is_empty():
		flow.add_child(Style.label("%s (%d left)" % [Game.data["world_buff"]["name"], Game.data["world_buff"]["charges"]], 13, Style.C["good"]))
	return flow


func _use(on: bool, cat: String) -> void:
	Game.data["use"][cat] = on


func _go() -> void:
	if chosen.is_empty():
		return
	Game.start_run(act, chosen)
	main.start_combat()
