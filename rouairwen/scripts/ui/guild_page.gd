class_name GuildPage
extends HBoxContainer
## The roster, the selected member's equipment, and the guild bank.

var hub
var _menu: PopupMenu
var _menu_item := {}


func rebuild() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.clear(self)
	var sel := Game.member(hub.selected_member)
	if sel.is_empty():
		hub.selected_member = "priest"
		sel = Game.priest()
	add_child(_roster(sel))
	add_child(_detail(sel))
	add_child(_bank(sel))
	_menu = PopupMenu.new()
	_menu.id_pressed.connect(_on_menu)
	add_child(_menu)


func _roster(sel: Dictionary) -> Control:
	var v := Style.vbox(6)
	v.custom_minimum_size.x = 230
	v.add_child(Style.title("Roster  %d/%d" % [Game.members().size() + 1, Game.MAX_GUILD], 22))
	var list := Style.vbox(5)
	list.add_child(_member_card(Game.priest(), sel))
	var ms: Array = Game.members().duplicate()
	ms.sort_custom(func(a, b): return a["tier"] > b["tier"])
	for m in ms:
		list.add_child(_member_card(m, sel))
	v.add_child(Style.scroll(list))
	return v


func _member_card(m: Dictionary, sel: Dictionary) -> Control:
	var is_p := Game.is_priest(m)
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = (is_p and Game.is_priest(sel)) or (not is_p and not Game.is_priest(sel) and m["id"] == sel["id"])
	b.custom_minimum_size = Vector2(0, 54)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(_select.bind("priest" if is_p else m["id"]))
	var h := Style.hbox(8)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_right = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stripe := ColorRect.new()
	stripe.color = Style.class_color(Game.member_class(m))
	stripe.custom_minimum_size = Vector2(5, 0)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stripe)
	var v := Style.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := Style.label(m["name"] + ("  (you)" if is_p else ""), 16, Style.class_color(Game.member_class(m)))
	n.add_theme_font_override("font", Style.bold_font())
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(n)
	var sub := "Discipline / Holy Priest" if is_p else "%s %s" % [ClassData.SPECS[m["spec"]]["name"], ClassData.class_name_of(m["class"])]
	var sl := Style.label("%s · power %d" % [sub, int(100 * Game.member_power(m))], 12, Style.C["muted"])
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sl)
	h.add_child(v)
	if not is_p:
		var tb := Style.tier_badge(m["tier"], 22)
		tb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tb)
	b.add_child(h)
	return b


func _select(id) -> void:
	hub.selected_member = id
	rebuild()


func _detail(m: Dictionary) -> Control:
	var p := Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)
	p.custom_minimum_size.x = 290
	var v := Style.vbox(5)
	p.add_child(v)
	var is_p := Game.is_priest(m)
	var cls := Game.member_class(m)
	var h := Style.hbox(8)
	var nv := Style.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(Style.label(m["name"], 24, Style.class_color(cls), true))
	if is_p:
		nv.add_child(Style.label("Level %d %s Priest · guild leader" % [Game.level(), ClassData.RACES.get(m["race"], "")], 13, Style.C["muted"]))
	else:
		var sp: Dictionary = ClassData.SPECS[m["spec"]]
		nv.add_child(Style.label("Level %d %s %s %s · %s" % [Game.level(), ClassData.RACES.get(m["race"], ""), sp["name"], ClassData.class_name_of(cls), Style.role_label(sp["role"])], 13, Style.C["muted"]))
	h.add_child(nv)
	if not is_p:
		h.add_child(Style.tier_badge(m["tier"], 34))
	v.add_child(h)
	var gb := Game.gear_bonus(m)
	if is_p:
		v.add_child(Style.rich("[color=#c09f86]Healing:[/color] +%d%%   [color=#c09f86]Mana:[/color] +%d%%   [color=#c09f86]Power:[/color] %d" % [int(gb * 100), int(gb * 60), int(100 * Game.member_power(m))], 13))
	else:
		v.add_child(Style.rich("[color=#c09f86]Gear:[/color] +%d%%   [color=#c09f86]Power:[/color] %d" % [int(gb * 100), int(100 * Game.member_power(m))], 13))
		var gs := Style.rich("[color=#c09f86]Grade:[/color] " + (Tiers.stats_text(Game.grade_stats(m)) if m["tier"] > 0 else "no bonus stats (F)"), 12)
		gs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(gs)
		var tr := Style.rich(MemberText.traits_bb(m), 12)
		tr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(tr)
	v.add_child(HSeparator.new())
	var slots := Style.vbox(3)
	for slot in Items.SLOTS:
		var it: Dictionary = m["gear"].get(slot, {})
		var row := Style.hbox(6)
		var sl := Style.label(Items.SLOT_NAMES[slot], 12, Style.C["muted"])
		sl.custom_minimum_size.x = 66
		row.add_child(sl)
		var ib := ItemButton.new().setup(it, slot, "[color=#8a7262]Click to unequip.[/color]" if not it.is_empty() else "", true)
		ib.custom_minimum_size = Vector2(0, 24)
		ib.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not it.is_empty():
			ib.pressed.connect(Game.unequip.bind(m, slot))
		row.add_child(ib)
		slots.add_child(row)
	v.add_child(Style.scroll(slots))
	var bh := Style.hbox(6)
	bh.add_child(Style.button("Equip best", _equip_best.bind(m)))
	bh.add_child(Style.button("Sheet & talents", _open_sheet))
	if not is_p:
		bh.add_child(Style.button("Dismiss", _dismiss.bind(m)))
	v.add_child(bh)
	return p


func _equip_best(m: Dictionary) -> void:
	var n := Game.auto_equip(m)
	Game.toast.emit("%s equipped %d upgrade%s." % [m["name"], n, "" if n == 1 else "s"] if n > 0 else "No upgrades in the bank for %s." % m["name"])
	Game.save()
	Game.changed.emit()


func _dismiss(m: Dictionary) -> void:
	var extra := " A founder of the guild!" if m.get("founder", false) else ""
	hub.main.confirm("Dismiss %s from <Lumens>?%s Their gear goes to the guild bank." % [m["name"], extra], Game.dismiss.bind(m["id"]), "Dismiss")


func _bank(sel: Dictionary) -> Control:
	var v := Style.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := Style.hbox(8)
	var t := Style.title("Guild Bank  %d/%d" % [Game.data["bank"].size(), Game.BANK_SIZE], 22)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var f := CheckBox.new()
	f.text = "Usable only"
	f.button_pressed = hub.bank_filter
	f.focus_mode = Control.FOCUS_NONE
	f.toggled.connect(_set_filter)
	head.add_child(f)
	v.add_child(head)
	var tools := Style.hbox(6)
	tools.add_child(Style.button("Equip all", Game.auto_equip_all, true))
	tools.add_child(Style.button("Sell junk", _sell_obsolete))
	v.add_child(tools)
	var list := Style.vbox(3)
	var items: Array = Game.data["bank"].duplicate()
	items.sort_custom(func(a, b): return a["ilvl"] > b["ilvl"] if a["slot"] == b["slot"] else Items.SLOTS.find(a["slot"]) < Items.SLOTS.find(b["slot"]))
	var shown := 0
	for it in items:
		var usable := Items.can_use(it, Game.member_class(sel))
		if hub.bank_filter and not usable:
			continue
		var gain := Game.upgrade_amount(sel, it)
		var row := Style.hbox(6)
		var mark := Style.label("▲" if gain > 0.0 else " ", 14, Style.C["good"])
		mark.custom_minimum_size.x = 14
		mark.tooltip_text = "Upgrade for %s" % sel["name"] if gain > 0.0 else ""
		row.add_child(mark)
		var bw := Game.best_wearer(it)
		var cmp := "[color=#6ee06e]Upgrade for %s[/color]" % bw[0]["name"] if bw[0] != null else "[color=#8a7262]Not an upgrade for anyone.[/color]"
		cmp += "\n[color=#8a7262]Click for options.[/color]"
		var ib := ItemButton.new().setup(it, "", cmp, true)
		ib.custom_minimum_size = Vector2(0, 26)
		ib.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ib.pressed.connect(_item_menu.bind(it, sel))
		row.add_child(ib)
		row.add_child(Style.label(Items.SLOT_NAMES[it["slot"]], 12, Style.C["muted"]))
		list.add_child(row)
		shown += 1
	if shown == 0:
		list.add_child(Style.label("Nothing here. Loot from quests, dungeons and raids lands in the bank.", 14, Style.C["muted"]))
	v.add_child(Style.scroll(list))
	return v


func _set_filter(on: bool) -> void:
	hub.bank_filter = on
	rebuild()


func _sell_obsolete() -> void:
	hub.main.confirm("Sell every bank item that is not an upgrade for anyone in the guild?", Game.sell_obsolete, "Sell")


func _item_menu(it: Dictionary, sel: Dictionary) -> void:
	_menu.clear()
	_menu_item = {"item": it, "member": sel}
	if Items.can_use(it, Game.member_class(sel)):
		_menu.add_item("Equip on %s" % sel["name"], 0)
	var bw := Game.best_wearer(it)
	if bw[0] != null and bw[0] != sel:
		_menu.add_item("Equip on %s (best)" % bw[0]["name"], 1)
	_menu.add_item("Sell for %s" % Balance.money(Items.sell_price(it)), 2)
	_menu.reset_size()
	_menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i.ZERO))


func _on_menu(id: int) -> void:
	var it: Dictionary = _menu_item["item"]
	match id:
		0:
			Game.equip(_menu_item["member"], it["uid"])
		1:
			Game.equip(Game.best_wearer(it)[0], it["uid"])
		2:
			Game.sell(it["uid"])


func _open_sheet() -> void:
	hub.open_page("character")
