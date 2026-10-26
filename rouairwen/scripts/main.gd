extends Control
## Main game screen: the resource bar and three tabs.
## Settlement: train peons and give them jobs. Clicking a building (in the settlement or in the
## Buildings list) swaps the shop panel for that building's menu; the buttons above the mine and the
## forest open that job's gear menu instead.
## Guild: the roster and the inn. Quests: see quest_page.gd.

const JOB_ORDER := ["gold", "lumber", "skins", "leather"]
const SITE_NAMES := {"gold": "Gold Mine", "lumber": "Forest"}
const TOOL_EFFECTS := {"gold": "Mining speed", "lumber": "Chopping speed"}
const IDLE_COLOR := Color("ffc861")

@onready var _settlement_tab: Button = %SettlementTab
@onready var _guild_tab: Button = %GuildTab
@onready var _quests_tab: Button = %QuestsTab
@onready var _amounts := {"gold": %GoldLabel, "lumber": %LumberLabel, "skins": %SkinsLabel,
	"leather": %LeatherLabel, "cloth": %ClothLabel}
@onready var _rates := {"gold": %GoldRate, "lumber": %LumberRate, "skins": %SkinsRate, "leather": %LeatherRate}
@onready var _food_label: Label = %FoodLabel
@onready var _food_caption: Label = %FoodCaption
@onready var _new_game_button: Button = %NewGameButton
@onready var _new_game_dialog: ConfirmationDialog = %NewGameDialog
@onready var _toast: Label = %Toast

# Settlement tab
@onready var _settlement_page: Control = %SettlementPage
@onready var _settlement: Settlement = %Settlement
@onready var _shop_scroll: ScrollContainer = %Scroll
@onready var _workers_title: Label = %WorkersTitle
@onready var _train_row: ShopRow = %TrainRow
@onready var _idle_label: Label = %IdleLabel
@onready var _job_list: VBoxContainer = %JobList
@onready var _building_list: VBoxContainer = %BuildingList
@onready var _building_menu: BuildingMenu = %BuildingMenu

# Gear menu (replaces the shop panel while open)
@onready var _gear_menu: Control = %GearMenu
@onready var _back_button: Button = %BackButton
@onready var _gear_menu_icon: ResourceIcon = %GearMenuIcon
@onready var _gear_menu_title: Label = %GearMenuTitle
@onready var _gear_menu_info: Label = %GearMenuInfo
@onready var _gear_rows := {"boots": %BootsRow, "tools": %ToolsRow, "bags": %BagsRow}

# Guild and quests tabs
@onready var _found_page: Control = %FoundPage
@onready var _found_title: Label = %FoundTitle
@onready var _found_row: ShopRow = %FoundRow
@onready var _guild_page: Control = %GuildPage
@onready var _quests_page: Control = %QuestsPage
@onready var _guild_name: Label = %GuildName
@onready var _guild_stats: Label = %GuildStats
@onready var _roster_list: VBoxContainer = %RosterList
@onready var _empty_roster: Label = %EmptyRoster
@onready var _sort_buttons := {"power": %SortPower, "role": %SortRole, "class": %SortClass}
@onready var _inn_scroll: Control = %InnScroll
@onready var _sheet: FighterSheet = %Sheet
@onready var _inn_row: ShopRow = %InnRow
@onready var _recruit_row: ShopRow = %RecruitRow
@onready var _odds_title: Label = %OddsTitle
@onready var _odds_list: VBoxContainer = %OddsList

var _names := HordeStyle.NAMES
var _page := "settlement"
var _gear_job := ""  # job whose gear menu is open ("gold" or "lumber"), or ""
var _menu := ""  # building whose menu is open, or ""
var _job_rows := {}  # job -> {"name": Label, "count": Label, "minus": Button, "plus": Button}
var _building_rows := {}  # building id -> ShopRow in the Buildings list
var _roster_rows := {}  # fighter id -> FighterRow
var _roster_sort := "power"  # "power", "role" or "class"
var _odds_rows: Array[Dictionary] = []  # per tier: {"bar": ProgressBar, "percent": Label}
var _odds_inn_level := -1  # inn level the odds table currently shows
var _toast_tween: Tween
var _battle_view: BattleView


func _ready() -> void:
	theme = UiTheme.build()
	_workers_title.text = str(_names.workers).to_upper()
	_found_title.text = Game.GUILD_NAME
	_guild_name.text = Game.GUILD_NAME

	_settlement_tab.pressed.connect(_show_page.bind("settlement"))
	_guild_tab.pressed.connect(_show_page.bind("guild"))
	_quests_tab.pressed.connect(_show_page.bind("quests"))
	_new_game_button.pressed.connect(_new_game_dialog.popup_centered)
	_new_game_dialog.confirmed.connect(_on_new_game_confirmed)

	_train_row.pressed.connect(Game.train_worker)
	_build_job_rows()
	for id in Buildings.ORDER:
		var row := ShopRow.new()
		row.tooltip_text = "Open the %s menu" % Buildings.INFO[id].name
		row.pressed.connect(_open_building.bind(id))
		_building_list.add_child(row)
		_building_rows[id] = row
	_building_menu.closed.connect(_close_menus)
	_building_menu.guild_tab_requested.connect(func() -> void:
		_guild_tab.button_pressed = true
		_show_page("guild"))

	_settlement.gear_menu_requested.connect(_toggle_gear_menu)
	_settlement.building_selected.connect(_open_building)
	_back_button.pressed.connect(_close_menus)
	for line in _gear_rows:
		_gear_rows[line].pressed.connect(func() -> void: Game.buy_gear(_gear_job, line))

	_found_row.pressed.connect(Game.found_guild)
	_inn_row.pressed.connect(_on_inn_row_pressed)
	_recruit_row.pressed.connect(_on_recruit_pressed)
	for sort in _sort_buttons:
		_sort_buttons[sort].pressed.connect(func() -> void:
			_roster_sort = sort
			_rebuild_roster())
	_sheet.closed.connect(_close_sheet)
	Game.roster_changed.connect(_rebuild_roster)
	Game.quest_finished.connect(_on_quest_finished)

	_battle_view = BattleView.new()
	add_child(_battle_view)
	_quests_page.watch_requested.connect(_open_battle)

	_build_odds_rows()
	_rebuild_roster()
	_refresh()

	if Game.just_started:
		Game.just_started = false
		_show_toast(_names.greeting)
	elif not Game.offline_gains.is_empty():
		var gains := []
		for resource in Game.RESOURCES:
			if Game.offline_gains[resource] >= 1.0:
				gains.append("+%s %s" % [NumberFormat.short(Game.offline_gains[resource]), resource])
		if not gains.is_empty():
			_show_toast("While you were away: " + ", ".join(PackedStringArray(gains)) + ".")


func _process(_delta: float) -> void:
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if (_gear_job != "" or _menu != "") and event.is_action_pressed("ui_cancel"):
		_close_menus()
		get_viewport().set_input_as_handled()


func _show_page(page: String) -> void:
	_page = page


## Opens a job's gear menu, or closes it when it's already open.
func _toggle_gear_menu(job: String) -> void:
	_menu = ""
	_gear_job = "" if job == _gear_job else job
	_show_selection()
	if _gear_job != "":
		_gear_menu_icon.kind = _gear_job
		_gear_menu_title.text = SITE_NAMES[_gear_job]


## Opens a building's menu, or closes it when it's already open.
func _open_building(id: String) -> void:
	_gear_job = ""
	_menu = "" if id == _menu else id
	_show_selection()
	if _menu != "":
		_building_menu.open(_menu)


func _close_menus() -> void:
	_gear_job = ""
	_menu = ""
	_show_selection()


func _show_selection() -> void:
	_settlement.set_selected_job(_gear_job)
	_settlement.set_selected_building(_menu)


func _refresh() -> void:
	for resource in _amounts:
		_amounts[resource].text = NumberFormat.short(floorf(Game.stock[resource]))
	for job in _rates:
		_rates[job].text = "+%s/s" % NumberFormat.short(Game.get_rate(job))
	_food_label.text = "%d / %d" % [Game.get_worker_count(), Game.get_food_cap()]
	_food_caption.text = "food" if Game.hunted_food < 0.1 else "food, %s hunted" % NumberFormat.short(Game.hunted_food)

	_settlement_page.visible = _page == "settlement"
	_found_page.visible = _page != "settlement" and not Game.guild_founded
	_guild_page.visible = _page == "guild" and Game.guild_founded
	_quests_page.visible = _page == "quests" and Game.guild_founded
	if _settlement_page.visible:
		_refresh_settlement()
	elif _found_page.visible:
		_found_row.show_item("Found " + Game.GUILD_NAME, "Unlocks the Inn, recruiting and quests", "", Buildings.INFO.guild.cost)
	elif _guild_page.visible:
		_refresh_guild()


# --- Settlement tab ---

func _build_job_rows() -> void:
	for job in JOB_ORDER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_job_list.add_child(row)
		var icon := ResourceIcon.new()
		icon.kind = job
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var name_label := Label.new()
		name_label.theme_type_variation = &"RowTitle"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(name_label)
		var count := Label.new()
		count.theme_type_variation = &"RowCount"
		count.custom_minimum_size = Vector2(40, 0)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(count)
		var minus := _small_button("-", "Send one back to the idle peons")
		minus.pressed.connect(Game.unassign_worker.bind(job))
		row.add_child(minus)
		var plus := _small_button("+", "Give an idle peon this job")
		plus.pressed.connect(Game.assign_worker.bind(job))
		row.add_child(plus)
		_job_rows[job] = {"name": name_label, "count": count, "minus": minus, "plus": plus}


func _small_button(text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(40, 34)
	return button


func _refresh_settlement() -> void:
	_shop_scroll.visible = _gear_job == "" and _menu == ""
	_gear_menu.visible = _gear_job != ""
	_building_menu.visible = _menu != ""
	if _gear_job != "":
		_refresh_gear_menu()
		return
	if _menu != "":
		_building_menu.refresh()
		return

	var food_ok := Game.has_food()
	var train_desc: String = _names.train_flavor + " Uses 1 food." if food_ok \
		else "Out of food. Build a %s." % _names.farm
	_train_row.show_item("Train " + _names.worker, train_desc, str(Game.get_worker_count()),
		Game.get_worker_cost(), food_ok)

	var idle := Game.count_workers(Game.IDLE)
	_idle_label.text = "%d idle %s waiting for a job: use + below." % [idle, _names.workers] if idle > 0 \
		else "Every %s has a job." % _names.worker
	_idle_label.self_modulate = IDLE_COLOR if idle > 0 else Color.WHITE
	for job in JOB_ORDER:
		_refresh_job_row(job)

	for id in _building_rows:
		_refresh_building_row(id)


## A Buildings list entry: its status, and a "!" when something in its menu is affordable.
func _refresh_building_row(id: String) -> void:
	var row: ShopRow = _building_rows[id]
	var info: Dictionary = Buildings.INFO[id]
	var status := ""
	if not Game.is_built(id):
		status = "Found the guild first" if not Game.can_build(id) else "Not built yet"
	elif id == "farm":
		status = "%d built, %d food each" % [Game.farms, Game.get_food_per_farm()]
	else:
		var levels := 0
		var total := 0
		for upgrade in info.upgrades:
			levels += Game.get_upgrade_level(upgrade)
			total += Buildings.UPGRADES[upgrade].max
		status = "%d / %d upgrades" % [levels, total]
	var ready := Game.has_affordable_upgrade(id) and Game.can_build(id)
	row.show_item(BuildingMenu.display_name(id), status, "!  »" if ready else "»", {})


func _refresh_job_row(job: String) -> void:
	var parts: Dictionary = _job_rows[job]
	var count := Game.count_workers(job)
	var title: String = _names.job_workers[job]
	if not Game.is_job_open(job):
		var building: String = Game.JOBS[job].building
		title += "  (needs a %s)" % Buildings.INFO[building].name
	elif job == "leather" and Game.count_waiting(job) > 0:
		title += "  (waiting for skins)"
	parts.name.text = title
	parts.name.modulate.a = 1.0 if Game.is_job_open(job) else 0.5
	parts.count.text = str(count)
	parts.minus.disabled = count == 0
	parts.plus.disabled = not Game.can_assign(job)


func _refresh_gear_menu() -> void:
	var job := _gear_job
	_gear_menu_info.text = "%d %s  ·  trip %.1fs  ·  carry %s  ·  +%s %s/s" % [
		Game.count_workers(job), _names.job_workers[job], Game.get_trip_time(job),
		NumberFormat.short(Game.get_carry(job)), NumberFormat.short(Game.get_rate(job)), job]
	for line in _gear_rows:
		_refresh_gear_row(job, line)


func _refresh_gear_row(job: String, line: String) -> void:
	var row: ShopRow = _gear_rows[line]
	var items: Array = Gear.LINES[job][line]
	var level := Game.get_gear_level(job, line)
	var progress := "%d/%d" % [level, items.size()]
	var item := Game.get_next_gear(job, line)
	if item.is_empty():
		row.show_maxed(items[level - 1].name, "The finest in Azeroth.", progress)
		return
	var now := Game.get_gear_value(job, line)
	var next: float = item.value
	var desc := ""
	match line:
		"boots":
			desc = "Walk speed x%s (now x%s)" % [_short_number(next), _short_number(now)]
		"tools":
			desc = "%s x%s (now x%s)" % [TOOL_EFFECTS[job], _short_number(next), _short_number(now)]
		"bags":
			desc = "Carry %s per trip (now %s)" % [_short_number(next), _short_number(now)]
	row.show_item(item.name, desc, progress, item.cost)


## 1.25 -> "1.25", 1.5 -> "1.5", 2.0 -> "2".
static func _short_number(value: float) -> String:
	return ("%.2f" % value).rstrip("0").rstrip(".")


# --- Guild tab ---

func _refresh_guild() -> void:
	var roles := Game.count_roles()
	_guild_stats.text = "%d / %d members  ·  %d tanks  ·  %d healers  ·  %d DPS  ·  %s power  ·  %d items in the vault" % [
		Game.fighters.size(), Game.GUILD_CAPACITY, roles.Tank, roles.Healer, roles.DPS,
		NumberFormat.short(Game.get_guild_power()), Game.vault.size()]

	var renown_max: int = Buildings.UPGRADES.inn_renown.max
	if not Game.inn_built:
		_inn_row.show_item("Build the Inn", "Recruit fighters of every class", "", Buildings.INFO.inn.cost)
	elif Game.is_upgrade_maxed("inn_renown"):
		_inn_row.show_maxed("Inn Renown", "The best odds there are. More upgrades in the Inn's menu.", "%d/%d" % [renown_max, renown_max])
	else:
		_inn_row.show_item("Inn Renown", "Better odds of high-tier recruits",
			"%d/%d" % [Game.inn_level, renown_max], Game.get_upgrade_cost("inn_renown"))

	_recruit_row.visible = Game.inn_built
	_odds_title.visible = Game.inn_built
	_odds_list.visible = Game.inn_built
	if Game.inn_built:
		var room := Game.has_guild_room()
		_recruit_row.show_item("Recruit a fighter",
			"Random class and spec, tier F to SS+" if room else "The guild is full. Dismiss someone first.",
			"%d/%d" % [Game.fighters.size(), Game.GUILD_CAPACITY], Game.get_recruit_cost(), room)
		if _odds_inn_level != Game.inn_level:
			_update_odds()


func _on_inn_row_pressed() -> void:
	if Game.inn_built:
		Game.buy_upgrade("inn_renown")
	else:
		Game.build("inn")


func _on_recruit_pressed() -> void:
	var fighter := Game.recruit()
	if fighter.is_empty():
		return
	var tier: Dictionary = Fighters.TIERS[fighter.tier]
	_show_toast("%s (%s-tier %s %s) joins %s!" % [fighter.name, tier.name, fighter.spec,
		Fighters.CLASSES[fighter.class_id].name, Game.GUILD_NAME], tier.color)
	if _roster_rows.has(fighter.id):
		_roster_rows[fighter.id].flash()


func _on_quest_finished(quest_id: String) -> void:
	var quest := Quests.get_quest(quest_id)
	var result: Dictionary = Game.quest_results[quest_id]
	if result.victory:
		var loot := "+%s gold, +%s cloth" % [NumberFormat.short(result.gold), NumberFormat.short(result.cloth)]
		if not result.items.is_empty():
			loot += " and %d piece%s of gear" % [result.items.size(), "s" if result.items.size() > 1 else ""]
		_show_toast("%s: victory! %s. Watch the fight from the Quests tab." % [quest.name, loot], Color("6fdc7f"))
	else:
		_show_toast("%s: the party was defeated. Watch the fight from the Quests tab." % quest.name, Color("ff6b5b"))


func _open_battle(quest_id: String) -> void:
	var result: Dictionary = Game.quest_results.get(quest_id, {})
	if result.has("battle"):
		_battle_view.open(Quests.get_quest(quest_id).name, result)


func _open_sheet(fighter_id: int) -> void:
	_sheet.show_fighter(fighter_id)
	_sheet.show()
	_inn_scroll.hide()


func _close_sheet() -> void:
	_sheet.hide()
	_inn_scroll.show()


func _on_new_game_confirmed() -> void:
	Game.new_game()
	get_tree().reload_current_scene()


## Lists guild members, sorted by power, by role (tanks, healers, then DPS) or by class.
func _rebuild_roster() -> void:
	for child in _roster_list.get_children():
		_roster_list.remove_child(child)
		child.queue_free()
	_roster_rows.clear()

	var powers := {}
	for fighter in Game.fighters:
		powers[fighter.id] = Fighters.power(fighter)
	var sorted := Game.fighters.duplicate()
	match _roster_sort:
		"role":
			sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var a_role := Fighters.ROLES.find(Fighters.spec_of(a).role)
				var b_role := Fighters.ROLES.find(Fighters.spec_of(b).role)
				return a_role < b_role or (a_role == b_role and powers[a.id] > powers[b.id]))
		"class":
			sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var a_class: String = Fighters.CLASSES[a.class_id].name + a.spec
				var b_class: String = Fighters.CLASSES[b.class_id].name + b.spec
				return a_class < b_class or (a_class == b_class and powers[a.id] > powers[b.id]))
		_:
			sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return powers[a.id] > powers[b.id])
	for fighter in sorted:
		var row := FighterRow.new()
		row.setup(fighter, "Dismiss", true)
		row.set_blocked(Game.is_on_quest(fighter.id), "On quest")
		row.action_pressed.connect(Game.dismiss)
		row.selected.connect(_open_sheet)
		_roster_list.add_child(row)
		_roster_rows[fighter.id] = row
	_empty_roster.visible = sorted.is_empty()
	if _sheet.visible:
		_sheet.rebuild()


func _build_odds_rows() -> void:
	for tier in Fighters.TIERS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_odds_list.add_child(row)

		var badge := TierBadge.new()
		badge.set_tier(tier)
		badge.custom_minimum_size = Vector2(52, 22)
		badge.add_theme_font_size_override("font_size", 14)
		row.add_child(badge)

		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.step = 0.0
		bar.custom_minimum_size = Vector2(0, 10)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fill := StyleBoxFlat.new()
		fill.bg_color = Fighters.TIERS[tier].color
		var background := StyleBoxFlat.new()
		background.bg_color = Color(0, 0, 0, 0.35)
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", background)
		row.add_child(bar)

		var percent := Label.new()
		percent.theme_type_variation = &"CostLabel"
		percent.custom_minimum_size = Vector2(64, 0)
		percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(percent)
		_odds_rows.append({"bar": bar, "percent": percent})


## Bars are scaled to the most likely tier so the rare ones stay visible; the label has the exact chance.
func _update_odds() -> void:
	_odds_inn_level = Game.inn_level
	var chances := Game.get_tier_chances()
	var best: float = chances.max()
	for i in chances.size():
		_odds_rows[i].bar.value = chances[i] / best
		_odds_rows[i].percent.text = _format_chance(chances[i])


static func _format_chance(chance: float) -> String:
	var percent := chance * 100.0
	if percent >= 10.0:
		return "%.1f%%" % percent
	if percent >= 1.0:
		return "%.2f%%" % percent
	return "%.3f%%" % percent


func _show_toast(text: String, color := Color.TRANSPARENT) -> void:
	_toast.text = text
	if color.a > 0.0:
		_toast.add_theme_color_override("font_color", color.lightened(0.2))
	else:
		_toast.remove_theme_color_override("font_color")
	_toast.modulate.a = 1.0
	_toast.show()
	if _toast_tween:
		_toast_tween.kill()  # a newer toast replaces the old one
	_toast_tween = create_tween()
	_toast_tween.tween_interval(5.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 1.0)
	_toast_tween.tween_callback(_toast.hide)
