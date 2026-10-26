class_name BuildingMenu
extends VBoxContainer
## One settlement building's menu, shown in place of the shop panel: what the building does and what
## it gives right now, the action to build it (or another Pig Farm), then its upgrades.

signal closed
signal guild_tab_requested

var building := ""
var _names := HordeStyle.NAMES
var _title: Label
var _about: Label
var _details: Label
var _build_row: ShopRow
var _rows: VBoxContainer
var _upgrade_rows := {}  # upgrade id -> ShopRow
var _guild_button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	var back := Button.new()
	back.text = "« Back"
	back.tooltip_text = "Back to the settlement shop (Esc)"
	back.focus_mode = Control.FOCUS_NONE
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	header.add_child(back)
	_title = _label(header, &"BarTitle")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_about = _label(self, &"MutedLabel")
	_about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details = _label(self, &"CostLabel")
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var upgrades_title := _label(self, &"SectionTitle")
	upgrades_title.text = "UPGRADES"
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	add_child(_rows)
	_guild_button = Button.new()
	_guild_button.text = "Recruit in the Guild tab"
	_guild_button.focus_mode = Control.FOCUS_NONE
	_guild_button.pressed.connect(func() -> void: guild_tab_requested.emit())
	add_child(_guild_button)


func open(id: String) -> void:
	building = id
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_upgrade_rows.clear()
	_build_row = ShopRow.new()
	_build_row.pressed.connect(_on_build_pressed)
	_rows.add_child(_build_row)
	for upgrade in Buildings.INFO[id].upgrades:
		var row := ShopRow.new()
		row.pressed.connect(Game.buy_upgrade.bind(upgrade))
		_rows.add_child(row)
		_upgrade_rows[upgrade] = row
	refresh()


func refresh() -> void:
	var info: Dictionary = Buildings.INFO[building]
	var built := Game.is_built(building)
	_title.text = display_name(building)
	_about.text = info.about
	_details.text = "\n".join(PackedStringArray(_details_lines() if built else ["Not built yet."]))
	_guild_button.visible = building == "inn" and built

	_build_row.visible = building == "farm" or not built
	if building == "farm":
		_build_row.show_item("Build a " + _names.farm, "+%d food" % Game.get_food_per_farm(), str(Game.farms), Game.get_farm_cost())
	elif not built:
		var blocked := not Game.can_build(building)
		var title: String = "Found " + Game.GUILD_NAME if building == "guild" else "Build the " + info.name
		var desc: String = "Found the guild first" if blocked else info.about
		_build_row.show_item(title, desc, "", info.cost, not blocked)

	for upgrade in _upgrade_rows:
		_refresh_upgrade(upgrade, built)


## The building's name as the settlement knows it now (the Great Hall becomes a Stronghold...).
static func display_name(id: String) -> String:
	match id:
		"hall":
			return HordeStyle.NAMES.halls[Game.hall_tier]
		"guild":
			return "%s Guild Hall" % Game.GUILD_NAME
	return Buildings.INFO[id].name


func _refresh_upgrade(id: String, built: bool) -> void:
	var row: ShopRow = _upgrade_rows[id]
	var upgrade: Dictionary = Buildings.UPGRADES[id]
	var level := Game.get_upgrade_level(id)
	var progress := "%d/%d" % [level, upgrade.max]
	var title: String = upgrade.name
	var desc := Buildings.effect_text(id, level + 1)
	if id == "hall_tier":
		var halls: Array = _names.halls
		if Game.is_upgrade_maxed(id):
			row.show_maxed(halls[level], "Gold and lumber deliveries are worth x%d" % roundi(Game.get_multiplier()), progress)
			return
		title = "Upgrade to " + halls[level + 1]
		desc = "Deliveries worth x%d, +%d food" % [roundi(Game.get_multiplier() * 2.0), Game.FOOD_PER_HALL_TIER]
	if Game.is_upgrade_maxed(id):
		row.show_maxed(title, Buildings.effect_text(id, level), progress)
	else:
		row.show_item(title, desc if built else "Build the %s first" % Buildings.INFO[building].name, progress,
			Game.get_upgrade_cost(id), built)


## What the building gives right now, in numbers.
func _details_lines() -> Array:
	var lines := []
	match building:
		"hall":
			lines.append("Every gold and lumber delivery is worth x%d." % roundi(Game.get_multiplier()))
			lines.append("Food from the hall: %d." % (Game.HALL_FOOD + Game.FOOD_PER_HALL_TIER * Game.hall_tier))
			lines.append("Training the next Peon costs %s gold." % NumberFormat.short(Game.get_worker_cost().gold))
			lines.append("Keeps gathering for up to %dh while you're away." % roundi(Game.get_offline_cap() / 3600.0))
		"farm":
			lines.append("%d %s, %d food each: %d food." % [Game.farms, _names.farm + "s", Game.get_food_per_farm(),
				Game.farms * Game.get_food_per_farm()])
			lines.append("Food cap %d, with %d Peons." % [Game.get_food_cap(), Game.get_worker_count()])
			if Game.get_upgrade_value("roasting_spits") > 0.0:
				lines.append("Peons walk %d%% faster on roast pork." % roundi(Game.get_upgrade_value("roasting_spits") * 100.0))
		"mill":
			lines.append("Lumber deliveries are worth %d%% more." % roundi(Game.get_upgrade_value("lumber_harvesting") * 100.0))
			lines.append("Lumberjacks chop %d%% faster." % roundi(Game.get_upgrade_value("sawpit") * 100.0))
			lines.append(_job_line("lumber"))
		"lodge":
			lines.append("Each hunt brings back %s skins and %s food." % [
				NumberFormat.short(Game.get_carry("skins")), _short(Game.get_food_per_hunt())])
			lines.append("Hunted food so far: %s." % _short(Game.hunted_food))
			lines.append(_job_line("skins"))
		"tannery":
			lines.append("Each leather takes %s skins." % _short(Game.get_skins_per_leather()))
			lines.append("Leatherworkers work %d%% faster." % roundi(Game.get_upgrade_value("tanning_racks") * 100.0))
			lines.append(_job_line("leather"))
		"inn":
			var chances := Game.get_tier_chances()
			var top := 0.0
			for i in range(6, chances.size()):
				top += chances[i]
			lines.append("Renown %d: %s chance of an S-tier recruit or better." % [Game.inn_level, _percent(top)])
			lines.append("Recruiting costs %s gold." % NumberFormat.short(Game.get_recruit_cost().gold))
			lines.append("Members gain %d%% more experience on quests." % roundi(Game.get_upgrade_value("comfortable_beds") * 100.0))
		"guild":
			lines.append("%d / %d members." % [Game.fighters.size(), Game.GUILD_CAPACITY])
			lines.append("Members fight with %d%% more health and power." % roundi(Game.get_combat_bonus() * 100.0))
			lines.append("Quests bring back %d%% more gold and cloth, and %d%% more gear." % [
				roundi(Game.get_upgrade_value("war_chest") * 100.0), roundi(Game.get_upgrade_value("quartermaster") * 100.0)])
	return lines


func _job_line(job: String) -> String:
	return "%d %s: a trip every %.1fs, about %s %s per second." % [Game.count_workers(job), _names.job_workers[job],
		Game.get_trip_time(job), _short(Game.get_rate(job)), job]


func _on_build_pressed() -> void:
	if building == "farm":
		Game.build_farm()
	else:
		Game.build(building)


func _label(parent: Node, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	parent.add_child(label)
	return label


static func _short(value: float) -> String:
	return ("%.2f" % value).rstrip("0").rstrip(".")


static func _percent(chance: float) -> String:
	return ("%.2f" % (chance * 100.0)).rstrip("0").rstrip(".") + "%"
