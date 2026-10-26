class_name BattleView
extends Control
## Replays a quest fight turn by turn over the whole screen: the party and the foes with their
## health bars on each side, and the combat log filling in between. Skip jumps to the end.

const STEP_SECONDS := 0.45
const PARTY_COLOR := Color("4fbf5a")
const FOE_COLOR := Color("d8473a")
const ROUND_COLOR := Color("ff9a3c")

var _title: Label
var _columns := {}  # "party" / "foe" -> VBoxContainer of unit cards
var _bars: Array[ProgressBar] = []
var _hp_labels: Array[Label] = []
var _log_scroll: ScrollContainer
var _log: VBoxContainer
var _summary: Label
var _skip: Button
var _entries: Array = []
var _step := 0
var _timer := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"Solid"
	panel.custom_minimum_size = Vector2(980, 580)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	_title = Label.new()
	_title.theme_type_variation = &"BarTitle"
	box.add_child(_title)
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 16)
	box.add_child(middle)
	for side in ["party", "foe"]:
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(230, 0)
		column.add_theme_constant_override("separation", 10)
		_columns[side] = column
	middle.add_child(_columns.party)
	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	middle.add_child(_log_scroll)
	_log = VBoxContainer.new()
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.add_theme_constant_override("separation", 2)
	_log_scroll.add_child(_log)
	middle.add_child(_columns.foe)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	box.add_child(footer)
	_summary = Label.new()
	_summary.theme_type_variation = &"CostLabel"
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_summary)
	_skip = Button.new()
	_skip.text = "Skip"
	_skip.pressed.connect(_skip_to_end)
	footer.add_child(_skip)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide)
	footer.add_child(close)


## Starts replaying a quest result (Game.quest_results entry) from the first turn.
func open(quest_name: String, result: Dictionary) -> void:
	var battle: Dictionary = result.get("battle", {})
	_title.text = quest_name
	for column in _columns.values():
		for child in column.get_children():
			column.remove_child(child)
			child.queue_free()
	for child in _log.get_children():
		_log.remove_child(child)
		child.queue_free()
	_bars.clear()
	_hp_labels.clear()
	for unit in battle.get("units", []):
		_add_unit_card(unit)
	_entries = battle.get("log", [])
	_step = 0
	_timer = 0.0
	_summary.text = ""
	_summary.set_meta("result", result)
	_skip.disabled = false
	show()


func _process(delta: float) -> void:
	if not visible or _step >= _entries.size():
		return
	_timer += delta
	if _timer >= STEP_SECONDS:
		_timer = 0.0
		_show_step()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


func _skip_to_end() -> void:
	while _step < _entries.size():
		_show_step()


func _show_step() -> void:
	var entry: Dictionary = _entries[_step]
	_step += 1
	for i in mini(entry.hp.size(), _bars.size()):
		_bars[i].value = entry.hp[i]
		_hp_labels[i].text = "%d / %d" % [entry.hp[i], _bars[i].max_value]
	var line := Label.new()
	line.text = entry.text
	line.theme_type_variation = &"CostLabel"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if str(entry.text).begins_with("Round "):
		line.add_theme_color_override("font_color", ROUND_COLOR)
	_log.add_child(line)
	_scroll_to_end.call_deferred()
	if _step >= _entries.size():
		_skip.disabled = true
		_summary.text = _describe(_summary.get_meta("result"))


func _scroll_to_end() -> void:
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _add_unit_card(unit: Dictionary) -> void:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 2)
	var name_label := Label.new()
	name_label.text = unit.name
	name_label.theme_type_variation = &"RowTitle"
	if unit.side == "party" and unit.class_id != "":
		name_label.add_theme_color_override("font_color", Fighters.class_text_color(unit.class_id))
	card.add_child(name_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = unit.max_hp
	bar.value = unit.max_hp
	bar.custom_minimum_size = Vector2(0, 14)
	FighterSheet._style_bar(bar, PARTY_COLOR if unit.side == "party" else FOE_COLOR)
	card.add_child(bar)
	var hp := Label.new()
	hp.text = "%d / %d" % [unit.max_hp, unit.max_hp]
	hp.theme_type_variation = &"MutedLabel"
	card.add_child(hp)
	_columns[unit.side].add_child(card)
	_bars.append(bar)
	_hp_labels.append(hp)


static func _describe(result: Dictionary) -> String:
	if not result.victory:
		return "Defeat. The party came back empty-handed."
	var parts := ["Victory! +%s gold, +%s cloth" % [NumberFormat.short(result.gold), NumberFormat.short(result.cloth)]]
	for item in result.items:
		parts.append(item.name)
	return ", ".join(PackedStringArray(parts)) + "."
