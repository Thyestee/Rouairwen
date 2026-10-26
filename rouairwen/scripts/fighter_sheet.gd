class_name FighterSheet
extends ScrollContainer
## Character sheet for one guild member: level and experience, stats and what they mean in a fight,
## spells, worn gear, and the vault items they could wear instead (with the power each would add).

signal closed

const GOOD := Color("6fdc7f")
const BAD := Color("ff6b5b")

var fighter_id := 0
var _box: VBoxContainer


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)


func show_fighter(id: int) -> void:
	fighter_id = id
	scroll_vertical = 0
	rebuild()


func rebuild() -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	var fighter := Game.get_fighter(fighter_id)
	if fighter.is_empty():
		closed.emit()
		return
	var spec := Fighters.spec_of(fighter)
	var busy := Game.is_on_quest(fighter_id)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_box.add_child(header)
	var back := Button.new()
	back.text = "« Back"
	back.focus_mode = Control.FOCUS_NONE
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	header.add_child(back)
	var badge := TierBadge.new()
	badge.set_tier(fighter.tier)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(badge)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	header.add_child(names)
	_label(names, fighter.name, &"BarTitle")
	var title := _label(names, "Level %d %s %s  ·  %s" % [fighter.level, spec.name, Fighters.CLASSES[fighter.class_id].name, spec.role], &"CostLabel")
	title.add_theme_color_override("font_color", Fighters.class_text_color(fighter.class_id))

	# Experience
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 10)
	_box.add_child(xp_row)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = Fighters.XP_PER_LEVEL
	bar.value = fighter.xp if fighter.level < Fighters.MAX_LEVEL else Fighters.XP_PER_LEVEL
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_bar(bar, Color("b65cff"))
	xp_row.add_child(bar)
	_label(xp_row, "Max level" if fighter.level >= Fighters.MAX_LEVEL else "%d / %d XP" % [fighter.xp, Fighters.XP_PER_LEVEL], &"MutedLabel")
	if busy:
		var note := _label(_box, "Away on a quest: gear can't be changed until they're back.", &"MutedLabel")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Stats
	_label(_box, "STATS", &"SectionTitle")
	var base := Fighters.base_stats(fighter)
	var total := Fighters.total_stats(fighter)
	var profile := Fighters.combat_profile(fighter)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	_box.add_child(grid)
	var derived := [
		["Health", str(roundi(profile.hp))],
		[_potency_name(spec), str(roundi(profile.potency))],
		["Critical", "%d%%" % roundi(profile.crit * 100.0)],
		["Dodge", "%d%%" % roundi(profile.dodge * 100.0)],
		["Armor", "%d (%d%%)" % [profile.armor, roundi(profile.dr * 100.0)]],
	]
	for i in Fighters.STATS.size():
		var stat: String = Fighters.STATS[i]
		var from_gear: int = total[stat] - floori(base[stat])
		var name_label := _label(grid, Fighters.STAT_NAMES[stat] + ("  (main)" if stat == spec.main else ""), &"MutedLabel")
		name_label.custom_minimum_size = Vector2(110, 0)
		var value := _label(grid, str(total[stat]) + (" (+%d)" % from_gear if from_gear > 0 else ""), &"CostLabel")
		if from_gear > 0:
			value.add_theme_color_override("font_color", GOOD)
		_label(grid, derived[i][0], &"MutedLabel")
		_label(grid, derived[i][1], &"CostLabel")
	var power := _label(_box, "Power %d" % Fighters.power(fighter), &"RowTitle")
	power.add_theme_color_override("font_color", HordeStyle.PALETTE.accent)

	# Spells
	_label(_box, "SPELLS", &"SectionTitle")
	for spell in Spells.kit_of(fighter) + [Spells.basic_attack(fighter.class_id)]:
		_label(_box, spell.name, &"RowTitle")
		var desc := _label(_box, Spells.describe(spell), &"MutedLabel")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Gear
	_label(_box, "GEAR", &"SectionTitle")
	for slot in Items.SLOTS:
		var item: Dictionary = fighter.gear.get(slot, {})
		var row := _item_row(Items.SLOT_NAMES[slot], item)
		if not item.is_empty():
			var unequip := _button("Remove", busy)
			unequip.pressed.connect(Game.unequip.bind(fighter_id, slot))
			row.add_child(unequip)
		_box.add_child(row)

	# Vault
	_label(_box, "VAULT (%d)" % Game.vault.size(), &"SectionTitle")
	if Game.vault.is_empty():
		var empty := _label(_box, "Victorious quests bring back gear. It waits here until someone wears it.", &"MutedLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var items := Game.vault.duplicate()
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _power_change(fighter, a) > _power_change(fighter, b))
	for item in items:
		var change := _power_change(fighter, item)
		var row := _item_row(Items.SLOT_NAMES[item.slot], item, change)
		var equip := _button("Equip", busy)
		equip.pressed.connect(Game.equip.bind(fighter_id, item.id))
		row.add_child(equip)
		var sell := _button("Sell %d" % Items.sell_price(item), false)
		sell.tooltip_text = "Sell for %d gold" % Items.sell_price(item)
		sell.pressed.connect(Game.sell_item.bind(item.id))
		row.add_child(sell)
		_box.add_child(row)


## Power the fighter would gain (or lose) by wearing this item instead of their current one.
static func _power_change(fighter: Dictionary, item: Dictionary) -> int:
	var trial := fighter.duplicate()
	trial.gear = fighter.gear.duplicate()
	trial.gear[item.slot] = item
	return Fighters.power(trial) - Fighters.power(fighter)


static func _potency_name(spec: Dictionary) -> String:
	if spec.role == "Healer":
		return "Healing power"
	return "Spell power" if spec.main == "int" else "Attack power"


func _item_row(slot_name: String, item: Dictionary, change := 0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var slot := _label(row, slot_name, &"MutedLabel")
	slot.custom_minimum_size = Vector2(56, 0)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	if item.is_empty():
		_label(info, "Empty", &"MutedLabel")
		return row
	var name_label := _label(info, item.name, &"CostLabel")
	name_label.add_theme_color_override("font_color", Items.color_of(item))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var details := Items.describe(item)
	if change != 0:
		details += "  ·  %+d power" % change
	var stats := _label(info, details, &"MutedLabel")
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if change > 0:
		stats.add_theme_color_override("font_color", GOOD)
	elif change < 0:
		stats.add_theme_color_override("font_color", BAD)
	return row


func _button(text: String, disabled: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 13)
	return button


func _label(parent: Control, text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	parent.add_child(label)
	return label


static func _style_bar(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.35)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
