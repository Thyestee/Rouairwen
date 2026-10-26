class_name ShopRow
extends Button
## Shop entry: name and description on the left; count or level and the cost on the right.
## The cost shows one icon and amount per resource needed, in red when there isn't enough.

const TOO_EXPENSIVE := Color(1.0, 0.45, 0.4)

var _content: MarginContainer
var _title: Label
var _desc: Label
var _count: Label
var _costs := {}  # resource -> {"box": HBoxContainer, "label": Label}


func _init() -> void:
	custom_minimum_size = Vector2(0, 66)
	focus_mode = Control.FOCUS_NONE

	_content = MarginContainer.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		_content.add_theme_constant_override("margin_" + side, 14)
	for side in ["top", "bottom"]:
		_content.add_theme_constant_override("margin_" + side, 8)
	add_child(_content)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	_content.add_child(row)

	var left := _column(row)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title = _label(left, &"RowTitle")
	_desc = _label(left, &"MutedLabel")
	# Long names shrink with "…" rather than squeezing out the count and cost.
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var right := _column(row)
	_count = _label(right, &"RowCount")
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var cost_row := HBoxContainer.new()
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.alignment = BoxContainer.ALIGNMENT_END
	cost_row.add_theme_constant_override("separation", 10)
	right.add_child(cost_row)
	for resource in Game.RESOURCES:
		_costs[resource] = _cost_box(cost_row, resource)


## Shows a purchasable entry. `allowed` can block the purchase for reasons other than cost.
func show_item(title: String, desc: String, count_text: String, cost: Dictionary, allowed := true) -> void:
	_title.text = title
	_desc.text = desc
	_count.text = count_text
	for resource in _costs:
		var amount: float = cost.get(resource, 0.0)
		var parts: Dictionary = _costs[resource]
		parts.box.visible = amount > 0.0
		parts.label.text = NumberFormat.short(amount)
		parts.label.self_modulate = Color.WHITE if Game.stock[resource] >= amount else TOO_EXPENSIVE
	disabled = not (allowed and Game.can_afford(cost))
	_content.modulate.a = 0.7 if disabled else 1.0


## Shows an entry that can't be bought any more.
func show_maxed(title: String, desc: String, count_text: String) -> void:
	_title.text = title
	_desc.text = desc
	_count.text = count_text
	for resource in _costs:
		_costs[resource].box.hide()
	disabled = true
	_content.modulate.a = 0.85


func _cost_box(parent: Control, resource: String) -> Dictionary:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	box.hide()
	var icon := ResourceIcon.new()
	icon.kind = resource
	icon.custom_minimum_size = Vector2(16, 16)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var label := _label(box, &"CostLabel")
	parent.add_child(box)
	return {"box": box, "label": label}


func _column(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	parent.add_child(column)
	return column


func _label(parent: Control, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	parent.add_child(label)
	return label
