class_name CombatScreen
extends Control
## The fight: enemies on top, party frames in the middle, your spells at the bottom.
##
## Hover a frame and press a spell key to cast on it, or click a frame to target it and
## click a spell. Space pauses, Escape cancels the current cast.

const KEYCODES := Spells.PHYSICAL

var main
var eng: CombatEngine
var running := false
var paused := false
var countdown := 0.0
var frames := {}
var enemy_frames := {}
var selected: UnitFrame
var hovered: UnitFrame
var buttons: Array = []

var header_title: Label
var header_fight: Label
var header_time: Label
var enemy_row: HBoxContainer
var party_grid: GridContainer
var cast_bar: ProgressBar
var cast_label: Label
var mana_bar: ProgressBar
var mana_label: Label
var bar_row: HBoxContainer
var log_box: RichTextLabel
const LOG_MAX := 300
var log_entries: Array = []
var log_filter := {"heal": true, "damage": true, "event": true}
var error_label: Label
var center_label: Label
var pause_dim: ColorRect


func _ready() -> void:
	var act: Dictionary = Game.run["activity"]
	add_child(Backdrop.new("zone", Color(act["sky"]), Color(act["ground"]), hash(act["title"])))
	var root := Style.vbox(6)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12
	root.offset_right = -12
	root.offset_top = 8
	root.offset_bottom = -8
	add_child(root)
	# Header
	var head := Style.hbox(12)
	header_title = Style.label(act["title"], 22, Style.C["gold"], true)
	head.add_child(header_title)
	header_fight = Style.label("", 16, Style.C["text"])
	header_fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(header_fight)
	header_time = Style.label("0:00", 16, Style.C["muted"])
	head.add_child(header_time)
	head.add_child(Style.button("Pause (Space)", toggle_pause))
	root.add_child(head)
	# Enemies
	enemy_row = Style.hbox(10)
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.custom_minimum_size.y = 172
	root.add_child(enemy_row)
	# Party
	var pc := CenterContainer.new()
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	party_grid = GridContainer.new()
	party_grid.columns = 5
	party_grid.add_theme_constant_override("h_separation", 8)
	party_grid.add_theme_constant_override("v_separation", 8)
	pc.add_child(party_grid)
	root.add_child(pc)
	# Bottom: casting + spells (center), log (right)
	var bottom := Style.hbox(12)
	bottom.custom_minimum_size.y = 250
	var left_pad := Control.new()
	left_pad.custom_minimum_size.x = 40
	bottom.add_child(left_pad)
	var mid := Style.vbox(6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_END
	mid.size_flags_vertical = Control.SIZE_SHRINK_END
	error_label = Style.label("", 16, Style.C["bad"])
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(error_label)
	var cbw := Control.new()
	cbw.custom_minimum_size = Vector2(380, 22)
	cbw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cast_bar = Style.bar(Color("e8c040"), 22)
	cast_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cbw.add_child(cast_bar)
	cast_label = Style.label("", 13, Color.WHITE)
	cast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	cast_label.add_theme_constant_override("outline_size", 4)
	cbw.add_child(cast_label)
	mid.add_child(cbw)
	var mbw := Control.new()
	mbw.custom_minimum_size = Vector2(380, 18)
	mbw.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mana_bar = Style.bar(Style.C["mana"], 18)
	mana_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mbw.add_child(mana_bar)
	mana_label = Style.label("", 12, Color.WHITE)
	mana_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mana_label.add_theme_color_override("font_outline_color", Color.BLACK)
	mana_label.add_theme_constant_override("outline_size", 4)
	mbw.add_child(mana_label)
	mid.add_child(mbw)
	var barp := Style.panel(Color(0.05, 0.02, 0.02, 0.85), Style.C["border"], 2, 6)
	barp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar_row = Style.hbox(5)
	barp.add_child(bar_row)
	mid.add_child(barp)
	bottom.add_child(mid)
	var logp := Style.panel(Color(0, 0, 0, 0.6), Color(0.3, 0.15, 0.1), 1, 6)
	logp.custom_minimum_size = Vector2(300, 0)
	var logv := Style.vbox(2)
	logp.add_child(logv)
	var logh := Style.hbox(4)
	var lt := Style.label("Combat Log", 13, Style.C["gold"], true)
	lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logh.add_child(lt)
	for cat in [["heal", "Heals"], ["damage", "Damage"], ["event", "Events"]]:
		var cb := CheckBox.new()
		cb.text = cat[1]
		cb.button_pressed = log_filter[cat[0]]
		cb.focus_mode = Control.FOCUS_NONE
		cb.add_theme_font_size_override("font_size", 11)
		cb.toggled.connect(_set_log_filter.bind(cat[0]))
		logh.add_child(cb)
	logv.add_child(logh)
	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_theme_font_size_override("normal_font_size", 12)
	log_box.mouse_filter = Control.MOUSE_FILTER_PASS
	logv.add_child(log_box)
	bottom.add_child(logp)
	root.add_child(bottom)
	# Center messages and pause
	pause_dim = ColorRect.new()
	pause_dim.color = Color(0, 0, 0, 0.45)
	pause_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_dim.visible = false
	add_child(pause_dim)
	center_label = Style.label("", 40, Style.C["gold"], true)
	center_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	center_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_label.add_theme_constant_override("outline_size", 8)
	add_child(center_label)
	if not Game.run["buff_names"].is_empty():
		_log("[color=#6ee06e]Buffs for this outing: %s.[/color]" % ", ".join(Game.run["buff_names"]))
	start_fight()


# ---------------------------------------------------------------- fight setup

func start_fight() -> void:
	main.close_overlay()
	eng = Game.build_engine()
	eng.floating.connect(_on_floating)
	eng.log_line.connect(_log)
	eng.combat_log.connect(_add_log)
	eng.ended.connect(_on_ended)
	var act: Dictionary = Game.run["activity"]
	var f := Game.run_fight()
	header_fight.text = "   Fight %d/%d: %s" % [Game.run["fight"] + 1, act["fights"].size(), f["label"]]
	# Party frames
	Style.clear(party_grid)
	frames.clear()
	party_grid.columns = 5 if eng.party.size() > 6 else mini(eng.party.size(), 5)
	for unit in eng.party:
		var fr := UnitFrame.new()
		fr.unit = unit
		fr.engine = eng
		fr.custom_minimum_size = Vector2(200, 70) if eng.party.size() <= 5 else Vector2(196, 64)
		fr.clicked.connect(_on_frame_clicked)
		fr.hover_changed.connect(_on_frame_hover)
		party_grid.add_child(fr)
		frames[unit.uid] = fr
	var t := eng.tank()
	_select(frames[(t if t != null else eng.priest).uid])
	hovered = null
	for c in enemy_row.get_children():
		enemy_row.remove_child(c)
		c.queue_free()
	for uid in enemy_frames:
		if is_instance_valid(enemy_frames[uid]):
			enemy_frames[uid].queue_free()
	enemy_frames.clear()
	_last_enemy_count = eng.enemies.size()
	_rebuild_enemies()
	# Action bar
	Style.clear(bar_row)
	buttons.clear()
	for i in eng.known.size():
		var id: String = eng.known[i]
		var b := ActionButton.new().setup(id, Spells.key_label(i), eng, Game.level())
		b.pressed.connect(_cast.bind(id, true))
		bar_row.add_child(b)
		buttons.append(b)
	var pot := ActionButton.new()
	pot.is_potion = true
	pot.setup("", "F", eng, Game.level())
	pot.pressed.connect(_potion)
	bar_row.add_child(pot)
	_log("[color=#ffd86b]— Fight %d: %s —[/color]" % [Game.run["fight"] + 1, f["label"]])
	running = false
	paused = false
	pause_dim.visible = false
	countdown = 2.5
	center_label.text = f["label"]


func _rebuild_enemies() -> void:
	var known := {}
	for e in eng.enemies:
		known[e.uid] = true
		if not enemy_frames.has(e.uid) or not is_instance_valid(enemy_frames[e.uid]):
			var ef := EnemyFrame.new()
			ef.unit = e
			ef.engine = eng
			if e.is_boss:
				ef.custom_minimum_size = Vector2(320, 80)
			ef.clicked.connect(_on_enemy_clicked)
			enemy_frames[e.uid] = ef
	# Rebuild the nameplates; with many enemies the dead ones are hidden
	for c in enemy_row.get_children():
		for line in c.get_children():
			for fr in line.get_children():
				line.remove_child(fr)
		enemy_row.remove_child(c)
		c.queue_free()
	var shown := 0
	var col := Style.vbox(6)
	var rows := []
	for e in eng.enemies:
		if not e.alive and eng.enemies.size() > 6:
			continue
		rows.append(enemy_frames[e.uid])
	# Two rows of nameplates when there are many enemies
	var per_row := 4 if rows.size() > 4 else rows.size()
	var line: HBoxContainer = null
	for fr in rows:
		if line == null or line.get_child_count() >= per_row:
			line = Style.hbox(10)
			line.alignment = BoxContainer.ALIGNMENT_CENTER
			col.add_child(line)
		if fr.get_parent() != null:
			fr.get_parent().remove_child(fr)
		line.add_child(fr)
		shown += 1
	enemy_row.add_child(col)
	for uid in enemy_frames.keys():
		if not known.has(uid):
			enemy_frames[uid].queue_free()
			enemy_frames.erase(uid)


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if eng == null:
		return
	if countdown > 0.0 and not paused:
		countdown -= delta
		if countdown <= 0.0:
			center_label.text = ""
			running = true
		elif countdown < 1.0:
			center_label.text = "Fight!"
	if running and not paused and not eng.over:
		eng.tick(minf(delta, 0.1))
		if _enemy_count_changed():
			_rebuild_enemies()
	_update_hud()


var _last_enemy_count := 0


func _enemy_count_changed() -> bool:
	var n := eng.enemies.size()
	if n != _last_enemy_count:
		_last_enemy_count = n
		return true
	return false


func _update_hud() -> void:
	header_time.text = "%d:%02d" % [int(eng.time) / 60, int(eng.time) % 60]
	mana_bar.value = eng.mana / eng.max_mana
	mana_label.text = "Mana %d / %d" % [int(eng.mana), int(eng.max_mana)]
	if eng.casting.is_empty():
		cast_bar.value = 0.0
		cast_label.text = ""
		if eng.silenced > 0.0:
			cast_label.text = "Silenced (%.1f)" % eng.silenced
	else:
		var c: Dictionary = eng.casting
		var tname: String = c["target"].name if c["target"] != null else "party"
		if c.get("channel", false):
			cast_bar.value = c["remaining"] / c["total"]
		else:
			cast_bar.value = 1.0 - c["remaining"] / c["total"]
		cast_label.text = "%s → %s  %.1f" % [Spells.display_name(c["id"], Game.level()), tname, maxf(0.0, c["remaining"])]


# ---------------------------------------------------------------- input

func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	if main.overlay != null:
		return
	var kc: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
	if kc == KEY_SPACE:
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if kc == KEY_ESCAPE:
		if not eng.casting.is_empty():
			eng.cancel_cast()
		else:
			_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if kc == KEY_F:
		_potion()
		get_viewport().set_input_as_handled()
		return
	var idx := KEYCODES.find(kc)
	if idx >= 0 and idx < eng.known.size():
		_cast(eng.known[idx], false)
		get_viewport().set_input_as_handled()


func _cast(id: String, from_click: bool) -> void:
	if not running or paused:
		_error("Wait for the fight to start." if not running else "Paused.")
		return
	var target = null
	if hovered != null and not from_click:
		target = hovered.unit
	elif selected != null:
		target = selected.unit
	var err := eng.cast(id, target)
	if err != "":
		_error(err)
	elif target != null and frames.has(target.uid) and Spells.BOOK[id]["target"] == "ally":
		frames[target.uid].flash()


func _potion() -> void:
	if not running or paused:
		return
	var err := eng.use_mana_potion()
	if err != "":
		_error(err)


func _error(text: String) -> void:
	error_label.text = text
	var tw := create_tween()
	error_label.modulate.a = 1.0
	tw.tween_interval(1.0)
	tw.tween_property(error_label, "modulate:a", 0.0, 0.4)


func _select(fr: UnitFrame) -> void:
	if selected != null and is_instance_valid(selected):
		selected.selected = false
	selected = fr
	fr.selected = true


func _on_frame_clicked(fr: UnitFrame) -> void:
	_select(fr)


func _on_frame_hover(fr: UnitFrame, inside: bool) -> void:
	if inside:
		hovered = fr
	elif hovered == fr:
		hovered = null


func _on_enemy_clicked(ef: EnemyFrame) -> void:
	if ef.unit.alive:
		eng.focus = null if eng.focus == ef.unit else ef.unit


func _on_floating(unit, text: String, kind: String) -> void:
	if frames.has(unit.uid):
		frames[unit.uid].pop(text, kind)
	elif enemy_frames.has(unit.uid) and is_instance_valid(enemy_frames[unit.uid]):
		enemy_frames[unit.uid].pop(text, kind)


func _log(text: String) -> void:
	_add_log("event", text)


func _add_log(category: String, text: String) -> void:
	var t: float = eng.time if eng != null else 0.0
	var line := "[color=#8a7262]%d:%02d[/color] %s" % [int(t) / 60, int(t) % 60, text]
	log_entries.append([category, line])
	if log_entries.size() > LOG_MAX:
		log_entries.pop_front()
	if log_filter.get(category, true):
		log_box.append_text(line + "\n")
		while log_box.get_paragraph_count() > LOG_MAX:
			log_box.remove_paragraph(0)


func _set_log_filter(on: bool, category: String) -> void:
	log_filter[category] = on
	log_box.clear()
	for e in log_entries:
		if log_filter.get(e[0], true):
			log_box.append_text(e[1] + "\n")


func toggle_pause() -> void:
	if eng == null or eng.over:
		return
	paused = not paused
	pause_dim.visible = paused
	center_label.text = "Paused" if paused else ("" if running else center_label.text)


func _pause_menu() -> void:
	if eng.over:
		return
	paused = true
	pause_dim.visible = true
	var v: VBoxContainer = main.open_overlay(420)
	v.add_child(Style.title("Paused"))
	v.add_child(Style.button("Resume", _resume, true))
	var leave_txt := "Abandon the quest" if Game.run["activity"]["type"] == "quest" else "Leave (keep what you looted)"
	v.add_child(Style.button(leave_txt, _leave))
	v.add_child(Style.button("Options", _options))


func _resume() -> void:
	main.close_overlay()
	paused = false
	pause_dim.visible = false
	center_label.text = ""


func _leave() -> void:
	main.close_overlay()
	Game.settle_potions(eng)
	Game.finish_run(false)
	main.show_hub()


# ---------------------------------------------------------------- results

func _on_ended(won: bool) -> void:
	running = false
	if won:
		center_label.text = "Victory!"
		var res := Game.fight_won(eng)
		get_tree().create_timer(0.9).timeout.connect(_victory_panel.bind(res))
	else:
		center_label.text = "Defeat"
		Game.wipe(eng)
		get_tree().create_timer(1.0).timeout.connect(_defeat_panel)


func _stats_text() -> String:
	var s := eng.stats
	var oh: float = s["overheal"] / maxf(1.0, s["healing"] + s["overheal"]) * 100.0
	return "[color=#c09f86]Healing:[/color] %s  [color=#c09f86]Absorbed:[/color] %s  [color=#c09f86]Overheal:[/color] %d%%  [color=#c09f86]Dispels:[/color] %d  [color=#c09f86]Time:[/color] %d:%02d" % [
		Balance.big(s["healing"]), Balance.big(s["absorbed"]), int(oh), s["dispels"], int(eng.time) / 60, int(eng.time) % 60]


func _loot_list(v: VBoxContainer, items: Array) -> void:
	for it in items:
		var bw := Game.best_wearer(it)
		var note := ("[color=#6ee06e]Upgrade for %s[/color]" % bw[0]["name"]) if bw[0] != null else "[color=#8a7262]Not an upgrade for anyone.[/color]"
		if it.get("guaranteed", false):
			var role: String = it["profile"]
			note = "[color=#%s]Guaranteed %s piece[/color] · %s" % [Activities.ROLE_COLORS.get(role, "ffffff"), Activities.ROLE_PIECES.get(role, role), note]
		var row := Style.hbox(8)
		var ib := ItemButton.new().setup(it, "", note, true)
		ib.custom_minimum_size = Vector2(320, 26)
		row.add_child(ib)
		row.add_child(Style.rich(note, 13))
		row.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(row)


func _victory_panel(res: Dictionary) -> void:
	center_label.text = ""
	var act: Dictionary = Game.run["activity"]
	var v: VBoxContainer = main.open_overlay(640)
	var finished := Game.run_finished()
	v.add_child(Style.title("Victory!" if not finished else "%s complete!" % ("Quest" if act["type"] == "quest" else act["title"]), 28))
	v.add_child(Style.rich(_stats_text(), 13))
	var gains := "[color=#c09f86]Earned:[/color] "
	if res["xp"] > 0:
		gains += "%s XP, " % Balance.big(res["xp"])
	gains += Balance.money_bb(res["gold"])
	v.add_child(Style.rich(gains, 15))
	if res["levels"] > 0:
		v.add_child(Style.label("You reached level %d!" % Game.level(), 20, Style.C["gold"], true))
	if not res["items"].is_empty():
		v.add_child(Style.label("Loot (sent to the guild bank):", 14, Style.C["gold"]))
		_loot_list(v, res["items"])
	var foot := Style.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_END
	if not finished:
		var leave_txt := "Return to Orgrimmar"
		if act["type"] == "raid":
			leave_txt = "Return to Orgrimmar (progress saved)"
		elif act["type"] == "quest":
			leave_txt = "Abandon the quest"
		foot.add_child(Style.button(leave_txt, _leave_after_win))
		var nxt := Game.run_fight()
		foot.add_child(Style.button("Next: %s" % nxt["label"], start_fight, true))
	elif act["type"] == "quest":
		foot.add_child(Style.button("Turn in the quest", _turn_in_quest, true))
	else:
		foot.add_child(Style.button("Return to Orgrimmar", _finish_success, true))
	v.add_child(foot)


func _leave_after_win() -> void:
	main.close_overlay()
	Game.finish_run(false)
	main.show_hub()


## Turns in the quest: the gold and gear are rolled now and shown as they land in the bank.
func _turn_in_quest() -> void:
	var act: Dictionary = Game.run["activity"]
	var res := Game.complete_quest()
	var v: VBoxContainer = main.open_overlay(600)
	v.add_child(Style.title("Quest complete!", 28))
	v.add_child(Style.label("%s thanks the Lumens for completing %s." % [act["giver"], act["title"]], 15, Style.C["muted"]))
	v.add_child(Style.rich("[color=#c09f86]Received:[/color] %s XP, %s" % [Balance.big(res["xp"]), Balance.money_bb(res["gold"])], 15))
	if res["levels"] > 0:
		v.add_child(Style.label("You reached level %d!" % Game.level(), 20, Style.C["gold"], true))
	if not res["items"].is_empty():
		v.add_child(Style.label("Gear (sent to the guild bank):", 14, Style.C["gold"]))
	_loot_list(v, res["items"])
	_run_summary(v)
	var foot := Style.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_child(Style.button("Return to Orgrimmar", _finish_success, true))
	v.add_child(foot)


func _run_summary(v: VBoxContainer) -> void:
	var r: Dictionary = Game.run
	v.add_child(HSeparator.new())
	v.add_child(Style.rich("[color=#c09f86]This outing:[/color] %s XP, %s, %d item%s%s" % [Balance.big(r["xp"]), Balance.money_bb(r["gold"]),
		r["loot"].size(), "" if r["loot"].size() == 1 else "s", (", %d wipe%s" % [r["wipes"], "" if r["wipes"] == 1 else "s"]) if r["wipes"] > 0 else ""], 14))


func _finish_success() -> void:
	main.close_overlay()
	Game.finish_run(true)
	main.show_hub("guild" if not Game.data["bank"].is_empty() else "")


func _defeat_panel() -> void:
	center_label.text = ""
	var v: VBoxContainer = main.open_overlay(560)
	v.add_child(Style.title("Your party has been defeated", 26))
	v.add_child(Style.rich(_stats_text(), 13))
	var tips := []
	if eng.mana < eng.max_mana * 0.1:
		tips.append("You ran out of mana: favour efficient heals (Heal, Renew, Prayer of Mending) and drink potions earlier.")
	if eng.time > 0 and eng.alive_enemies().size() > 0 and eng.alive_enemies()[0].berserk > 0.0 and eng.time > eng.alive_enemies()[0].berserk:
		tips.append("The enemy went berserk: your party needs more damage (better gear, higher grades, elixirs).")
	if eng.tank() == null and Game.run["activity"]["party_size"] >= 5:
		tips.append("Bring a tank: without one, enemies tear through your damage dealers.")
	tips.append("Recommended power: %d. Your party: %d." % [Game.recommended_power(Game.run["activity"]), Game.party_power(Game.run["members"])])
	var tl := Style.label("\n".join(tips), 14, Style.C["muted"])
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tl)
	var foot := Style.hbox(10)
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_child(Style.button("Return to Orgrimmar", _leave_after_win))
	foot.add_child(Style.button("Try again", start_fight, true))
	v.add_child(foot)


## Options from the pause menu; closing them leaves the fight paused.
func _options() -> void:
	main.open_options()
