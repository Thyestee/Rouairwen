class_name FighterRow
extends PanelContainer
## One guild member: tier, name, level, spec and class, role, power, and an action button
## ("Dismiss" in the roster, "Add" or "Remove" when building a quest party).
## Clicking anywhere else on the row emits `selected`.

signal action_pressed(fighter_id: int)
signal selected(fighter_id: int)

const CONFIRM_SECONDS := 2.5
const FAVOURED_COLOR := Color("ffd86b")

var fighter_id := 0
var _row: HBoxContainer
var _action: Button
var _action_text := ""
var _confirm := false
var _armed := false


## `confirm` makes the action need a second click, for things that can't be undone.
func setup(fighter: Dictionary, action_text: String, confirm := false) -> void:
	fighter_id = fighter.id
	_action_text = action_text
	_confirm = confirm
	theme_type_variation = &"RosterRow"
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 12)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)

	var badge := TierBadge.new()
	badge.set_tier(fighter.tier)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(badge)

	var info := _column(_row)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spec := Fighters.spec_of(fighter)
	var name_label := _label(info, fighter.name, &"RowTitle")
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var class_label := _label(info, "Lv %d  %s %s" % [fighter.level, spec.name, Fighters.CLASSES[fighter.class_id].name], &"CostLabel")
	class_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	class_label.add_theme_color_override("font_color", Fighters.class_text_color(fighter.class_id))

	_row.add_child(_chip(spec.role, Fighters.ROLE_COLORS[spec.role]))

	var power := _column(_row)
	var power_value := _label(power, str(Fighters.power(fighter)), &"RowCount")
	var power_caption := _label(power, "power", &"MutedLabel")
	power_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	power_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_action = Button.new()
	_action.text = action_text
	_action.focus_mode = Control.FOCUS_NONE
	_action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_action.custom_minimum_size = Vector2(92, 0)
	_action.add_theme_font_size_override("font_size", 14)
	_action.pressed.connect(_on_action_pressed)
	_row.add_child(_action)


## Adds a "Favoured" chip, for members whose spec the selected quest favours.
func mark_favoured() -> void:
	var chip := _chip("Favoured", FAVOURED_COLOR)
	_row.add_child(chip)
	_row.move_child(chip, 2)


## Disables the action button, showing why instead (e.g. "On quest").
func set_blocked(blocked: bool, reason := "") -> void:
	_action.disabled = blocked
	_action.text = reason if blocked and reason != "" else _action_text


## Briefly lights the row up, e.g. when the fighter has just been recruited.
func flash() -> void:
	modulate = Color(1.8, 1.8, 1.8)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.8)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		selected.emit(fighter_id)


func _on_action_pressed() -> void:
	if not _confirm or _armed:
		action_pressed.emit(fighter_id)
		return
	_armed = true
	_action.text = "Sure?"
	var tween := create_tween()
	tween.tween_interval(CONFIRM_SECONDS)
	tween.tween_callback(func() -> void:
		_armed = false
		_action.text = _action_text)


func _chip(text: String, color: Color) -> Label:
	var chip := Label.new()
	chip.text = text
	chip.theme_type_variation = &"CostLabel"
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.custom_minimum_size = Vector2(64, 0)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_color_override("font_color", color.lightened(0.45))
	var box := StyleBoxFlat.new()
	box.bg_color = color.darkened(0.55)
	box.border_color = color
	box.set_border_width_all(1)
	box.set_corner_radius_all(9)
	box.set_content_margin_all(3)
	chip.add_theme_stylebox_override("normal", box)
	return chip


func _column(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
