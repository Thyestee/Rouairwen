extends HBoxContainer
## Quests tab: the quest board on the left; on the right, the selected quest's foes, favoured specs,
## its party and its last result. Pick three free guild members (or Auto-fill), check the estimated
## chance to win (from simulated fights), and send them off. When they come back, watch the fight.

signal watch_requested(quest_id: String)

const READY_COLOR := Color("c09f86")
const RUNNING_COLOR := Color("ff9a3c")
const VICTORY_COLOR := Color("6fdc7f")
const DEFEAT_COLOR := Color("ff6b5b")
const ESTIMATE_RUNS := 60

@onready var _quest_list: VBoxContainer = %QuestList
@onready var _quest_name: Label = %QuestName
@onready var _quest_info: Label = %QuestInfo
@onready var _favoured: Label = %Composition
@onready var _slots: VBoxContainer = %PartySlots
@onready var _chance: Label = %Chance
@onready var _auto_fill: Button = %AutoFillButton
@onready var _send: Button = %SendButton
@onready var _result: Label = %ResultLabel
@onready var _watch: Button = %WatchButton
@onready var _pick_title: Label = %PickTitle
@onready var _pick_scroll: ScrollContainer = %PickScroll
@onready var _pick_list: VBoxContainer = %PickList

var _cards := {}  # quest id -> QuestCard
var _selected := ""  # quest id shown on the right
var _party: Array[int] = []  # fighter ids picked for the selected quest
var _estimate := -1.0  # chance to win for the picked party, or -1 until three are picked


func _ready() -> void:
	var group := ButtonGroup.new()
	for quest in Quests.LIST:
		var card := QuestCard.new()
		card.setup(quest)
		card.button_group = group
		card.pressed.connect(_select.bind(quest.id))
		_quest_list.add_child(card)
		_cards[quest.id] = card
	_auto_fill.pressed.connect(_on_auto_fill)
	_send.pressed.connect(_on_send)
	_watch.pressed.connect(func() -> void: watch_requested.emit(_selected))
	Game.roster_changed.connect(_on_roster_changed)
	var first: String = Quests.LIST[0].id
	_cards[first].set_pressed_no_signal(true)
	_select(first)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_refresh()


func _select(quest_id: String) -> void:
	_selected = quest_id
	_party.clear()
	_rebuild_lists()


## Drops picks who left the guild or went on another quest; levels and gear may have changed too.
func _on_roster_changed() -> void:
	var still_free: Array[int] = []
	for fighter_id in _party:
		if not Game.get_fighter(fighter_id).is_empty() and not Game.is_on_quest(fighter_id):
			still_free.append(fighter_id)
	_party = still_free
	_rebuild_lists()


func _refresh() -> void:
	for quest in Quests.LIST:
		_refresh_card(quest.id)

	var run: Dictionary = Game.active_quests.get(_selected, {})
	if not run.is_empty():
		_send.disabled = true
		_send.text = "On the quest: %s left" % _format_time(Game.get_quest_time_left(_selected))
		_auto_fill.disabled = true
	else:
		_send.disabled = _party.size() != Quests.PARTY_SIZE
		_send.text = "Send party (%s)" % _format_time(Quests.DURATION)
		_auto_fill.disabled = Game.get_free_fighters().size() < Quests.PARTY_SIZE


func _refresh_card(quest_id: String) -> void:
	var card: QuestCard = _cards[quest_id]
	if Game.active_quests.has(quest_id):
		card.show_status("%s left" % _format_time(Game.get_quest_time_left(quest_id)), RUNNING_COLOR)
	elif Game.quest_results.has(quest_id):
		var victory: bool = Game.quest_results[quest_id].victory
		card.show_status("Last run: victory" if victory else "Last run: defeat", VICTORY_COLOR if victory else DEFEAT_COLOR)
	else:
		card.show_status("Ready", READY_COLOR)


## Everything on the right that only changes with the selection, the party or the roster.
func _rebuild_lists() -> void:
	var quest := Quests.get_quest(_selected)
	var favoured := Game.get_favoured(_selected)
	var foes := []
	for foe in quest.foes:
		foes.append("%s (%d health)" % [foe.name, roundi(Combat.foe_stats(foe, quest).hp)])
	_quest_name.text = quest.name
	_quest_info.text = "%s  ·  level %d  ·  %s  ·  Foes: %s" % [
		quest.zone, quest.level, _format_time(Quests.DURATION), ", ".join(PackedStringArray(foes))]
	var labels := []
	for key in favoured:
		labels.append(Fighters.spec_label(key))
	_favoured.text = "Favoured specs (+%d%% health and power each): %s" % [
		roundi((Combat.FAVOURED_BONUS - 1.0) * 100.0), ", ".join(PackedStringArray(labels))]
	_show_result()

	_clear(_slots)
	_clear(_pick_list)
	var run: Dictionary = Game.active_quests.get(_selected, {})
	var on_quest := not run.is_empty()
	var members: Array = run.party if on_quest else _party
	for i in Quests.PARTY_SIZE:
		if i < members.size():
			var fighter := Game.get_fighter(members[i])
			var row := FighterRow.new()
			row.setup(fighter, "Remove")
			if Fighters.spec_key(fighter) in favoured:
				row.mark_favoured()
			if on_quest:
				row.set_blocked(true, "Questing")
			else:
				row.action_pressed.connect(_remove)
			_slots.add_child(row)
		else:
			var empty := Label.new()
			empty.text = "Empty slot"
			empty.theme_type_variation = &"MutedLabel"
			empty.custom_minimum_size = Vector2(0, 40)
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_slots.add_child(empty)

	if on_quest:
		_chance.text = "The party is on its way. The fight happens when they arrive."
	elif _party.size() == Quests.PARTY_SIZE:
		_estimate = Combat.estimate(Game.get_party(_party), quest, favoured, ESTIMATE_RUNS, Game.get_combat_bonus())
		_chance.text = "Estimated chance to win: about %d%%" % roundi(_estimate * 100.0)
	else:
		_chance.text = "Pick %d members to see their chance to win." % Quests.PARTY_SIZE

	_pick_title.visible = not on_quest
	_pick_scroll.visible = not on_quest
	if on_quest:
		return
	var free := Game.get_free_fighters().filter(func(fighter: Dictionary) -> bool: return not (fighter.id in _party))
	free.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_favoured := Fighters.spec_key(a) in favoured
		var b_favoured := Fighters.spec_key(b) in favoured
		if a_favoured != b_favoured:
			return a_favoured
		return Fighters.power(a) > Fighters.power(b))
	var full := _party.size() >= Quests.PARTY_SIZE
	for fighter in free:
		var row := FighterRow.new()
		row.setup(fighter, "Add")
		if Fighters.spec_key(fighter) in favoured:
			row.mark_favoured()
		row.set_blocked(full, "Party full")
		row.action_pressed.connect(_add)
		_pick_list.add_child(row)
	if free.is_empty():
		var none := Label.new()
		none.text = "No free members. Recruit more at the Inn, or wait for a party to come back."
		none.theme_type_variation = &"MutedLabel"
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_pick_list.add_child(none)


func _show_result() -> void:
	var result: Dictionary = Game.quest_results.get(_selected, {})
	_watch.visible = result.has("battle")
	if result.is_empty():
		_result.text = ""
		return
	var parts := []
	if result.victory:
		parts.append("Last run: victory in %d rounds. Brought back %s gold, %s cloth" % [
			result.rounds, NumberFormat.short(result.gold), NumberFormat.short(result.cloth)])
		for item in result.items:
			parts.append(item.name)
	else:
		parts.append("Last run: defeat")
	var levels := []
	for member in result.members:
		if member.levels > 0:
			levels.append("%s reached level %d" % [member.name, member.level])
	_result.text = ", ".join(PackedStringArray(parts)) + "." + ("" if levels.is_empty() else " " + ", ".join(PackedStringArray(levels)) + "!")
	_result.self_modulate = VICTORY_COLOR if result.victory else DEFEAT_COLOR


func _add(fighter_id: int) -> void:
	if _party.size() < Quests.PARTY_SIZE and not (fighter_id in _party):
		_party.append(fighter_id)
		_rebuild_lists()


func _remove(fighter_id: int) -> void:
	_party.erase(fighter_id)
	_rebuild_lists()


func _on_auto_fill() -> void:
	_party.clear()
	for fighter in Quests.suggest_party(Game.get_free_fighters(), Game.get_favoured(_selected)):
		_party.append(fighter.id)
	_rebuild_lists()


func _on_send() -> void:
	if Game.start_quest(_selected, _party):
		_party.clear()
		_rebuild_lists()


static func _format_time(seconds: float) -> String:
	var total := ceili(seconds)
	return "%d:%02d" % [floori(total / 60.0), total % 60]


static func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
