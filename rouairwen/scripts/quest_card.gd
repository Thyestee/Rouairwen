class_name QuestCard
extends Button
## A quest on the board: name, zone, level and recommended power on the left; on the right its status
## (ready, time left, last result) and the kinds of reward, whose amounts stay hidden until the party returns.

var _status: Label


func setup(quest: Dictionary) -> void:
	custom_minimum_size = Vector2(0, 66)
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true

	var content := MarginContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		content.add_theme_constant_override("margin_" + side, 14)
	for side in ["top", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 8)
	add_child(content)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)

	var left := _column(row)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(left, quest.name, &"RowTitle")
	_label(left, "%s  ·  level %d  ·  recommended power %d" % [quest.zone, quest.level, Quests.recommended_power(quest)], &"MutedLabel")

	var right := _column(row)
	_status = _label(right, "", &"CostLabel")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var rewards := HBoxContainer.new()
	rewards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rewards.alignment = BoxContainer.ALIGNMENT_END
	rewards.add_theme_constant_override("separation", 4)
	right.add_child(rewards)
	for kind in ["gold", "cloth", "gear"]:
		var icon := ResourceIcon.new()
		icon.kind = kind
		icon.custom_minimum_size = Vector2(18, 18)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rewards.add_child(icon)
	_label(rewards, "???", &"MutedLabel")


func show_status(text: String, color: Color) -> void:
	_status.text = text
	_status.self_modulate = color


func _column(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	parent.add_child(column)
	return column


func _label(parent: Control, text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
