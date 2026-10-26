extends Node
## Global game state (autoloaded as "Game"): resources, workers, gear, buildings, the guild,
## quests and saving.

signal roster_changed  # members joined, left, levelled, changed gear, or went on / came back from a quest
signal delivered(job: String, amount: float)  # a worker brought a load back to the hall
signal quest_finished(quest_id: String)  # its result is in quest_results

## A worker walks to their work site, works there for a while, then carries the load back.
enum Phase { GOING, WORKING, RETURNING }

const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL := 10.0
const OFFLINE_CAP_SECONDS := 8.0 * 3600.0
const OFFLINE_MIN_SECONDS := 30.0

const RESOURCES := ["gold", "lumber", "skins", "leather", "cloth"]
const IDLE := "idle"  # job of peons waiting at the hall for an assignment
## Each job is named after the resource it brings back. Times are seconds with no gear: walking
## one way, then working at the site. "needs" is taken from stock (per unit produced) before the
## work starts; "building" has to be built before peons can take the job.
const JOBS := {
	"gold": {"walk": 3.0, "work": 2.0},
	"lumber": {"walk": 3.0, "work": 3.0},
	"skins": {"walk": 4.0, "work": 6.0, "building": "lodge"},
	"leather": {"walk": 2.0, "work": 5.0, "building": "tannery", "needs": {"skins": 2.0}},
}
const HALL_BOOSTED_JOBS := ["gold", "lumber"]  # hall upgrades multiply these deliveries
## The building upgrade that speeds up each job's work.
const WORK_SPEED_UPGRADES := {"lumber": "sawpit", "skins": "tracking", "leather": "tanning_racks"}
const FOOD_PER_HUNT := 0.02  # skinners also bring back a little meat, slowly raising the food cap

const START_GOLD := 15.0
const START_WORKERS := 2

const HALL_FOOD := 5
const FOOD_PER_HALL_TIER := 5
const FOOD_PER_FARM := 4

const WORKER_COST := 10.0
const WORKER_COST_GROWTH := 1.15
const FARM_COST := {"gold": 20.0, "lumber": 10.0}
const FARM_COST_GROWTH := 1.3

const GUILD_NAME := "Lumens"
const GUILD_CAPACITY := 40  # a full Classic raid
const RECRUIT_COST := 50.0
const RECRUIT_COST_PER_INN_LEVEL := 0.5  # each Inn Renown level makes recruiting 50% pricier

var stock := {}  # resource -> amount
var workers: Array[Dictionary] = []  # each: {"job": a JOBS key or IDLE, "phase": Phase, "progress": 0 to 1}
var gear := {}  # job -> {gear line ("boots", "tools", "bags") -> number of items bought in that line}
var buildings := {}  # building id -> built? (for the Buildings that have a build cost)
var upgrades := {}  # upgrade id (see Buildings.UPGRADES) -> level
var farms := 0
var hunted_food := 0.0  # food cap gained from skinners' hunts

## Shortcuts for the upgrades and buildings the rest of the game asks about most.
var hall_tier: int:
	get:
		return get_upgrade_level("hall_tier")
var inn_level: int:
	get:
		return get_upgrade_level("inn_renown")
var guild_founded: bool:
	get:
		return is_built("guild")
var inn_built: bool:
	get:
		return is_built("inn")

var fighters: Array[Dictionary] = []
var vault: Array[Dictionary] = []  # gear items nobody is wearing
var active_quests := {}  # quest id -> {"party": fighter ids, "ends_at": unix time}
var quest_favoured := {}  # quest id -> the three spec keys it currently favours
## Quest id -> the last outcome: {"victory", "rounds", "gold", "cloth", "items": [item names],
## "members": [{"name", "xp", "levels"}], "battle": Combat.simulate() result (this session only)}.
var quest_results := {}

var just_started := false  # true on a brand new game, to show a greeting
var offline_gains := {}  # resource -> amount gathered while the game was closed, set on load

var _next_fighter_id := 1
var _next_item_id := 1
var _autosave_timer := 0.0


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	for worker in workers:
		_advance_worker(worker, delta)
	_check_quests()
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Wipes all progress and starts over.
func new_game() -> void:
	_reset_progress()
	just_started = true
	save_game()
	roster_changed.emit()


# --- Worker trips ---

## Walking speed comes from the job's boots and the farms' Roasting Spits.
func get_walk_time(job: String) -> float:
	return JOBS[job].walk / (get_gear_value(job, "boots") * (1.0 + get_upgrade_value("roasting_spits")))


## Working speed comes from the job's tools and its building's upgrade.
func get_work_time(job: String) -> float:
	return JOBS[job].work / (get_gear_value(job, "tools") * (1.0 + get_upgrade_value(WORK_SPEED_UPGRADES.get(job, ""))))


func get_trip_time(job: String) -> float:
	return 2.0 * get_walk_time(job) + get_work_time(job)


## How much a worker brings back per trip: bags for miners and lumberjacks, trophies for skinners.
func get_carry(job: String) -> float:
	var carry := get_gear_value(job, "bags")
	if job == "skins":
		carry += get_upgrade_value("trophy_hunting")
	return carry


func get_multiplier() -> float:
	return pow(2.0, hall_tier)


## What one load is worth once it reaches the hall.
func get_delivery(job: String) -> float:
	var amount := get_carry(job)
	if job in HALL_BOOSTED_JOBS:
		amount *= get_multiplier()
	if job == "lumber":
		amount *= 1.0 + get_upgrade_value("lumber_harvesting")
	return amount


## Skins a leatherworker uses up for each leather.
func get_skins_per_leather() -> float:
	return JOBS.leather.needs.skins - get_upgrade_value("salt_curing")


func get_food_per_hunt() -> float:
	return FOOD_PER_HUNT * (1.0 + get_upgrade_value("smokehouse"))


## How long the game keeps gathering while closed, raised by the Warchief's Vault.
func get_offline_cap() -> float:
	return OFFLINE_CAP_SECONDS + get_upgrade_value("warchiefs_vault") * 3600.0


## Average income per second for a job, for display and offline progress.
## For leather this is what the leatherworkers could make with enough skins.
func get_rate(job: String) -> float:
	return count_workers(job) * get_delivery(job) / get_trip_time(job)


## Stock a job uses up for one trip ({} for jobs that need nothing).
func get_trip_needs(job: String) -> Dictionary:
	if job == "leather":
		return {"skins": get_skins_per_leather() * get_carry(job)}
	return {}


## A worker who reached the site but has nothing to work with waits there.
func is_waiting(worker: Dictionary) -> bool:
	return worker.phase == Phase.GOING and worker.progress >= 1.0


func _advance_worker(worker: Dictionary, delta: float) -> void:
	if worker.job == IDLE:
		return
	var time_left := delta
	while time_left > 0.0:
		var duration := get_work_time(worker.job) if worker.phase == Phase.WORKING else get_walk_time(worker.job)
		var needed: float = (1.0 - worker.progress) * duration
		if time_left < needed:
			worker.progress += time_left / duration
			return
		time_left -= needed
		if worker.phase == Phase.GOING and not _try_spend(get_trip_needs(worker.job)):
			worker.progress = 1.0
			return
		worker.progress = 0.0
		if worker.phase == Phase.RETURNING:
			_deliver(worker.job)
			worker.phase = Phase.GOING
		else:
			worker.phase += 1


func _deliver(job: String) -> void:
	var amount := get_delivery(job)
	stock[job] += amount
	if job == "skins":
		hunted_food += get_food_per_hunt()
	delivered.emit(job, amount)


# --- Workers and food ---

func count_workers(job: String) -> int:
	var count := 0
	for worker in workers:
		if worker.job == job:
			count += 1
	return count


func count_waiting(job: String) -> int:
	var count := 0
	for worker in workers:
		if worker.job == job and is_waiting(worker):
			count += 1
	return count


func get_worker_count() -> int:
	return workers.size()


func get_food_per_farm() -> int:
	return FOOD_PER_FARM + roundi(get_upgrade_value("bigger_pens"))


func get_food_cap() -> int:
	return HALL_FOOD + FOOD_PER_HALL_TIER * hall_tier + get_food_per_farm() * farms + floori(hunted_food)


func has_food() -> bool:
	return get_worker_count() < get_food_cap()


func get_worker_cost() -> Dictionary:
	var discount := 1.0 - get_upgrade_value("peon_barracks")
	return {"gold": ceilf(WORKER_COST * pow(WORKER_COST_GROWTH, get_worker_count()) * discount)}


## New peons wait at the hall until they're given a job.
func train_worker() -> bool:
	if not has_food() or not _try_spend(get_worker_cost()):
		return false
	workers.append(_new_worker(IDLE))
	return true


func is_job_open(job: String) -> bool:
	var building: String = JOBS[job].get("building", "")
	return building == "" or has_building(building)


func can_assign(job: String) -> bool:
	return is_job_open(job) and count_workers(IDLE) > 0


## Gives an idle peon the job; they set off from the hall.
func assign_worker(job: String) -> void:
	if not can_assign(job):
		return
	for i in workers.size():
		if workers[i].job == IDLE:
			workers[i] = _new_worker(job)
			return


## Sends one of the job's workers back to the idle peons, preferring one who isn't carrying a load.
func unassign_worker(job: String) -> void:
	var pick := -1
	for i in range(workers.size() - 1, -1, -1):
		if workers[i].job == job:
			pick = i
			if workers[i].phase != Phase.RETURNING:
				break
	if pick != -1:
		workers[pick] = _new_worker(IDLE)


func _new_worker(job: String) -> Dictionary:
	return {"job": job, "phase": Phase.GOING, "progress": 0.0}


## Adds workers spread out along their trip, so they don't all move in lockstep.
func _spawn_workers(job: String, count: int) -> void:
	for i in count:
		var worker := _new_worker(job)
		if job != IDLE:
			worker.phase = randi() % Phase.size()
			worker.progress = randf()
		workers.append(worker)


# --- Gear ---

func get_gear_level(job: String, line: String) -> int:
	return gear[job][line] if gear.has(job) else 0


func get_gear_value(job: String, line: String) -> float:
	var level := get_gear_level(job, line)
	return Gear.BASE[line] if level == 0 else Gear.LINES[job][line][level - 1].value


## The next item to buy in one of a job's gear lines, or an empty Dictionary when the line is complete.
func get_next_gear(job: String, line: String) -> Dictionary:
	var items: Array = Gear.LINES[job][line]
	var level := get_gear_level(job, line)
	return items[level] if level < items.size() else {}


## True when at least one of the job's next gear items is affordable right now.
func can_upgrade_gear(job: String) -> bool:
	for line in Gear.BASE:
		var item := get_next_gear(job, line)
		if not item.is_empty() and can_afford(item.cost):
			return true
	return false


func buy_gear(job: String, line: String) -> bool:
	var item := get_next_gear(job, line)
	if item.is_empty() or not _try_spend(item.cost):
		return false
	gear[job][line] += 1
	return true


# --- Buildings ---

func get_farm_cost() -> Dictionary:
	return _scaled(FARM_COST, pow(FARM_COST_GROWTH, farms))


func build_farm() -> bool:
	if not _try_spend(get_farm_cost()):
		return false
	farms += 1
	return true


## The Great Hall and the Pig Farms are always there; other buildings have to be built first.
func is_built(id: String) -> bool:
	return not Buildings.INFO[id].has("cost") or buildings.get(id, false)


func has_building(id: String) -> bool:
	return is_built(id)


## False while the building it depends on (the Inn needs the guild) isn't built.
func can_build(id: String) -> bool:
	var required: String = Buildings.INFO[id].get("requires", "")
	return required == "" or is_built(required)


func build(id: String) -> bool:
	if is_built(id) or not can_build(id) or not _try_spend(Buildings.INFO[id].cost):
		return false
	buildings[id] = true
	return true


func found_guild() -> bool:
	return build("guild")


# --- Building upgrades ---

func get_upgrade_level(id: String) -> int:
	return upgrades.get(id, 0)


## The upgrade's total effect: its value per level times its level (0 for unknown ids).
func get_upgrade_value(id: String) -> float:
	if not Buildings.UPGRADES.has(id):
		return 0.0
	return Buildings.UPGRADES[id].value * get_upgrade_level(id)


func is_upgrade_maxed(id: String) -> bool:
	return get_upgrade_level(id) >= Buildings.UPGRADES[id].max


func get_upgrade_cost(id: String) -> Dictionary:
	return {} if is_upgrade_maxed(id) else Buildings.upgrade_cost(id, get_upgrade_level(id))


func can_buy_upgrade(id: String) -> bool:
	return is_built(Buildings.UPGRADES[id].building) and not is_upgrade_maxed(id) and can_afford(get_upgrade_cost(id))


func buy_upgrade(id: String) -> bool:
	if not is_built(Buildings.UPGRADES[id].building) or is_upgrade_maxed(id) or not _try_spend(get_upgrade_cost(id)):
		return false
	upgrades[id] = get_upgrade_level(id) + 1
	return true


## True when the building (or a new Pig Farm) can be built, or one of its upgrades bought, right now.
func has_affordable_upgrade(building: String) -> bool:
	if not is_built(building):
		return can_build(building) and can_afford(Buildings.INFO[building].cost)
	if building == "farm" and can_afford(get_farm_cost()):
		return true
	for id in Buildings.INFO[building].upgrades:
		if can_buy_upgrade(id):
			return true
	return false


# --- Guild and inn ---

func get_recruit_cost() -> Dictionary:
	var cost := RECRUIT_COST * (1.0 + RECRUIT_COST_PER_INN_LEVEL * inn_level) * (1.0 - get_upgrade_value("recruitment_board"))
	return {"gold": ceilf(cost)}


func has_guild_room() -> bool:
	return fighters.size() < GUILD_CAPACITY


func get_tier_chances() -> Array[float]:
	return Fighters.tier_chances(inn_level)


## Hires a random fighter at the inn. Returns the new fighter, or an empty Dictionary if not possible.
func recruit() -> Dictionary:
	if not inn_built or not has_guild_room() or not _try_spend(get_recruit_cost()):
		return {}
	var fighter := Fighters.create(_next_fighter_id, inn_level)
	_next_fighter_id += 1
	fighters.append(fighter)
	roster_changed.emit()
	return fighter


## Members away on a quest can't be dismissed. Their gear goes back to the vault.
func dismiss(fighter_id: int) -> void:
	if is_on_quest(fighter_id):
		return
	for i in fighters.size():
		if fighters[i].id == fighter_id:
			for item in fighters[i].gear.values():
				vault.append(item)
			fighters.remove_at(i)
			roster_changed.emit()
			return


func get_fighter(fighter_id: int) -> Dictionary:
	for fighter in fighters:
		if fighter.id == fighter_id:
			return fighter
	return {}


func get_guild_power() -> int:
	var total := 0
	for fighter in fighters:
		total += Fighters.power(fighter)
	return total


# --- Member gear ---

## Puts an item from the vault on a member; whatever they wore in that slot goes back to the vault.
func equip(fighter_id: int, item_id: int) -> void:
	var fighter := get_fighter(fighter_id)
	var index := _vault_index(item_id)
	if fighter.is_empty() or index == -1:
		return
	var item: Dictionary = vault[index]
	vault.remove_at(index)
	if fighter.gear.has(item.slot):
		vault.append(fighter.gear[item.slot])
	fighter.gear[item.slot] = item
	roster_changed.emit()


func unequip(fighter_id: int, slot: String) -> void:
	var fighter := get_fighter(fighter_id)
	if fighter.is_empty() or not fighter.gear.has(slot):
		return
	vault.append(fighter.gear[slot])
	fighter.gear.erase(slot)
	roster_changed.emit()


func sell_item(item_id: int) -> void:
	var index := _vault_index(item_id)
	if index == -1:
		return
	stock.gold += Items.sell_price(vault[index])
	vault.remove_at(index)
	roster_changed.emit()


func _vault_index(item_id: int) -> int:
	for i in vault.size():
		if vault[i].id == item_id:
			return i
	return -1


## Number of guild members per role: {"Tank": n, "Healer": n, "DPS": n}.
func count_roles() -> Dictionary:
	var counts := {}
	for role in Fighters.ROLES:
		counts[role] = 0
	for fighter in fighters:
		counts[Fighters.spec_of(fighter).role] += 1
	return counts


# --- Quests ---

func is_on_quest(fighter_id: int) -> bool:
	for run in active_quests.values():
		if fighter_id in run.party:
			return true
	return false


## Guild members who aren't away on a quest.
func get_free_fighters() -> Array[Dictionary]:
	var free: Array[Dictionary] = []
	for fighter in fighters:
		if not is_on_quest(fighter.id):
			free.append(fighter)
	return free


## Sends three free members on a quest. The fight happens when the timer ends.
func start_quest(quest_id: String, party_ids: Array) -> bool:
	var quest := Quests.get_quest(quest_id)
	if quest.is_empty() or active_quests.has(quest_id) or party_ids.size() != Quests.PARTY_SIZE:
		return false
	var seen := []
	for fighter_id in party_ids:
		if get_fighter(fighter_id).is_empty() or is_on_quest(fighter_id) or fighter_id in seen:
			return false
		seen.append(fighter_id)
	active_quests[quest_id] = {"party": party_ids.duplicate(), "ends_at": Time.get_unix_time_from_system() + Quests.DURATION}
	roster_changed.emit()
	return true


## The fighters of a party, skipping anyone no longer in the guild.
func get_party(fighter_ids: Array) -> Array:
	var party := []
	for fighter_id in fighter_ids:
		var fighter := get_fighter(fighter_id)
		if not fighter.is_empty():
			party.append(fighter)
	return party


## Extra health and power members fight with, from the guild's Training Grounds.
func get_combat_bonus() -> float:
	return get_upgrade_value("training_grounds")


func get_favoured(quest_id: String) -> Array:
	if not quest_favoured.has(quest_id):
		quest_favoured[quest_id] = Quests.roll_favoured()
	return quest_favoured[quest_id]


func get_quest_time_left(quest_id: String) -> float:
	var run: Dictionary = active_quests.get(quest_id, {})
	return 0.0 if run.is_empty() else maxf(run.ends_at - Time.get_unix_time_from_system(), 0.0)


## Quest end times are real clock times, so quests also finish while the game is closed.
func _check_quests() -> void:
	var now := Time.get_unix_time_from_system()
	for quest_id in active_quests.keys():
		if now >= active_quests[quest_id].ends_at:
			_finish_quest(quest_id)


## The party fights the quest's foes; victory brings back the rewards. Everyone gains experience,
## and the quest picks new favoured specs.
func _finish_quest(quest_id: String) -> void:
	var run: Dictionary = active_quests[quest_id]
	active_quests.erase(quest_id)
	var quest := Quests.get_quest(quest_id)
	var party := get_party(run.party)
	var battle := Combat.simulate(party, quest, get_favoured(quest_id), true, get_combat_bonus()) if not party.is_empty() \
		else {"victory": false, "rounds": 0, "units": [], "log": []}
	var victory: bool = battle.victory

	var result := {"victory": victory, "rounds": battle.rounds, "gold": 0.0, "cloth": 0.0, "items": [], "members": [], "battle": battle}
	if victory:
		var rewards := Quests.roll_rewards(quest, _next_item_id, get_upgrade_value("quartermaster"),
			1.0 + get_upgrade_value("war_chest"))
		stock.gold += rewards.gold
		stock.cloth += rewards.cloth
		result.gold = rewards.gold
		result.cloth = rewards.cloth
		for item in rewards.items:
			vault.append(item)
			_next_item_id = maxi(_next_item_id, item.id + 1)
			result.items.append({"name": item.name, "quality": item.quality})
	for fighter in party:
		var xp := roundi(Quests.xp_for(fighter.level, quest, victory) * (1.0 + get_upgrade_value("comfortable_beds")))
		var levels := Fighters.gain_xp(fighter, xp)
		result.members.append({"name": fighter.name, "xp": xp, "levels": levels, "level": fighter.level})

	quest_results[quest_id] = result
	quest_favoured[quest_id] = Quests.roll_favoured()
	quest_finished.emit(quest_id)
	roster_changed.emit()


# --- Spending ---

func can_afford(cost: Dictionary) -> bool:
	for resource in cost:
		if stock.get(resource, 0.0) < cost[resource]:
			return false
	return true


func _try_spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for resource in cost:
		stock[resource] -= cost[resource]
	return true


func _scaled(base: Dictionary, factor: float) -> Dictionary:
	var scaled := {}
	for resource in base:
		scaled[resource] = ceilf(base[resource] * factor)
	return scaled


# --- Saving ---

func _reset_progress() -> void:
	stock = {}
	for resource in RESOURCES:
		stock[resource] = 0.0
	stock.gold = START_GOLD
	workers.clear()
	_spawn_workers("gold", START_WORKERS)
	gear = {}
	for job in Gear.LINES:
		gear[job] = {}
		for line in Gear.BASE:
			gear[job][line] = 0
	buildings = {}
	for id in Buildings.INFO:
		if Buildings.INFO[id].has("cost"):
			buildings[id] = false
	upgrades = {}
	farms = 0
	hunted_food = 0.0
	fighters.clear()
	vault.clear()
	active_quests = {}
	quest_favoured = {}
	quest_results = {}
	_next_fighter_id = 1
	_next_item_id = 1
	offline_gains = {}


func save_game() -> void:
	var worker_counts := {}
	for job in [IDLE] + JOBS.keys():
		worker_counts[job] = count_workers(job)
	var results := {}
	for quest_id in quest_results:  # fight logs are only kept for this session
		results[quest_id] = quest_results[quest_id].duplicate()
		results[quest_id].erase("battle")
	var data := {
		"stock": stock,
		"workers": worker_counts,
		"gear": gear,
		"buildings": buildings,
		"upgrades": upgrades,
		"farms": farms,
		"hunted_food": hunted_food,
		"fighters": fighters,
		"next_fighter_id": _next_fighter_id,
		"vault": vault,
		"next_item_id": _next_item_id,
		"active_quests": active_quests,
		"quest_favoured": quest_favoured,
		"quest_results": results,
		"saved_at": Time.get_unix_time_from_system(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the game: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))


func load_game() -> void:
	_reset_progress()
	if not FileAccess.file_exists(SAVE_PATH):
		just_started = true
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (data is Dictionary):
		push_warning("Save file is unreadable; starting a new game.")
		just_started = true
		return

	# Older saves kept gold and lumber at the top level, and only had miners and lumberjacks.
	var saved_stock: Dictionary = data.get("stock", {"gold": data.get("gold", START_GOLD), "lumber": data.get("lumber", 0.0)})
	for resource in RESOURCES:
		stock[resource] = float(saved_stock.get(resource, 0.0))
	var saved_workers: Dictionary = data.get("workers", {
		"gold": data.get("gold_workers", START_WORKERS), "lumber": data.get("lumber_workers", 0)})
	workers.clear()
	for job in [IDLE] + JOBS.keys():
		_spawn_workers(job, int(saved_workers.get(job, 0)))

	var saved_gear = data.get("gear", {})
	if saved_gear is Dictionary:
		for job in gear:
			# Older saves had one set of gear shared by everyone: both jobs keep it.
			var levels = saved_gear.get(job, saved_gear)
			if levels is Dictionary:
				for line in gear[job]:
					gear[job][line] = clampi(int(levels.get(line, 0)), 0, Gear.LINES[job][line].size())
	var saved_buildings: Dictionary = data.get("buildings", {})
	for id in buildings:
		buildings[id] = bool(saved_buildings.get(id, false))
	var saved_upgrades: Dictionary = data.get("upgrades", {})
	for id in saved_upgrades:
		if Buildings.UPGRADES.has(id):
			upgrades[id] = clampi(int(saved_upgrades[id]), 0, Buildings.UPGRADES[id].max)
	if not data.has("upgrades"):
		# Older saves kept the hall tier, the War Mill and Inn levels, and the guild and Inn, apart.
		upgrades["hall_tier"] = clampi(int(data.get("hall_tier", 0)), 0, Buildings.UPGRADES.hall_tier.max)
		upgrades["lumber_harvesting"] = clampi(int(data.get("mill_level", 0)), 0, Buildings.UPGRADES.lumber_harvesting.max)
		upgrades["inn_renown"] = clampi(int(data.get("inn_level", 0)), 0, Buildings.UPGRADES.inn_renown.max)
		buildings["mill"] = upgrades["lumber_harvesting"] > 0
		buildings["guild"] = bool(data.get("guild_founded", false))
		buildings["inn"] = bool(data.get("inn_built", false))
	farms = int(data.get("farms", farms))
	hunted_food = float(data.get("hunted_food", 0.0))

	for saved in data.get("fighters", []):
		if saved is Dictionary:
			fighters.append(_read_fighter(saved))
	_next_fighter_id = int(data.get("next_fighter_id", fighters.size() + 1))
	for saved in data.get("vault", []):
		if saved is Dictionary:
			vault.append(_read_item(saved))
	_next_item_id = int(data.get("next_item_id", 1))
	for fighter in fighters:  # item ids must stay unique
		for item in fighter.gear.values():
			_next_item_id = maxi(_next_item_id, item.id + 1)
	for item in vault:
		_next_item_id = maxi(_next_item_id, item.id + 1)

	var saved_quests: Dictionary = data.get("active_quests", {})
	for quest_id in saved_quests:
		var run: Dictionary = saved_quests[quest_id]
		if not Quests.get_quest(quest_id).is_empty():
			var party := []
			for fighter_id in run.get("party", []):
				party.append(int(fighter_id))
			active_quests[quest_id] = {"party": party, "ends_at": float(run.get("ends_at", 0.0))}
	var saved_favoured: Dictionary = data.get("quest_favoured", {})
	var spec_keys := Fighters.all_spec_keys()
	for quest_id in saved_favoured:
		var keys: Array = saved_favoured[quest_id]
		if keys.size() == Quests.PARTY_SIZE and keys.all(func(key) -> bool: return key in spec_keys):
			quest_favoured[quest_id] = keys
	var saved_results: Dictionary = data.get("quest_results", {})
	for quest_id in saved_results:
		var saved: Dictionary = saved_results[quest_id]
		quest_results[quest_id] = {
			"victory": bool(saved.get("victory", saved.get("success", false))),
			"rounds": int(saved.get("rounds", 0)),
			"gold": float(saved.get("gold", 0.0)),
			"cloth": float(saved.get("cloth", 0.0)),
			"items": saved.get("items", []),
			"members": saved.get("members", []),
		}

	var now := Time.get_unix_time_from_system()
	var away := clampf(now - float(data.get("saved_at", now)), 0.0, get_offline_cap())
	if away >= OFFLINE_MIN_SECONDS:
		_apply_offline_progress(away)


## Approximates what the workers did while the game was closed, from their average rates.
## Leatherworkers can only use the skins there were, plus those hunted in the meantime.
func _apply_offline_progress(seconds: float) -> void:
	var before := stock.duplicate()
	for job in ["gold", "lumber", "skins"]:
		stock[job] += get_rate(job) * seconds
	var skins_per_leather := get_skins_per_leather()
	var leather := minf(get_rate("leather") * seconds, stock.skins / skins_per_leather)
	stock.leather += leather
	stock.skins -= leather * skins_per_leather
	hunted_food += count_workers("skins") * seconds / get_trip_time("skins") * get_food_per_hunt()
	for resource in RESOURCES:
		offline_gains[resource] = stock[resource] - before[resource]


## JSON turns every number into a float, so saved fighters are rebuilt with proper types.
## Fighters from older saves get whatever they're missing: a spec, level 1, a talent roll, a spell kit.
func _read_fighter(saved: Dictionary) -> Dictionary:
	var class_id := str(saved.get("class_id", ""))
	if not Fighters.CLASSES.has(class_id):
		class_id = "warrior"
	var specs := Fighters.spec_names(class_id)
	var spec := str(saved.get("spec", ""))
	if not (spec in specs):
		spec = specs.pick_random()

	var talent := {}
	var saved_talent: Dictionary = saved.get("talent", {})
	for stat in Fighters.STATS:
		talent[stat] = float(saved_talent.get(stat, randf_range(Fighters.TALENT_RANGE.x, Fighters.TALENT_RANGE.y)))
	var known := []
	for spell in Spells.spec_spells(class_id, spec):
		known.append(spell.name)
	var spells: Array[String] = []
	for spell_name in saved.get("spells", []):
		if spell_name in known:
			spells.append(str(spell_name))
	if spells.is_empty():
		spells = Spells.random_kit(class_id, spec)
	var gear := {}
	var saved_gear: Dictionary = saved.get("gear", {})
	for slot in saved_gear:
		if slot in Items.SLOTS and saved_gear[slot] is Dictionary:
			gear[slot] = _read_item(saved_gear[slot])

	return {
		"id": int(saved.get("id", 0)),
		"name": str(saved.get("name", "Nameless")),
		"class_id": class_id,
		"spec": spec,
		"tier": clampi(int(saved.get("tier", 0)), 0, Fighters.TIERS.size() - 1),
		"level": clampi(int(saved.get("level", 1)), 1, Fighters.MAX_LEVEL),
		"xp": int(saved.get("xp", 0)),
		"talent": talent,
		"spells": spells,
		"gear": gear,
	}


func _read_item(saved: Dictionary) -> Dictionary:
	var stats := {}
	var saved_stats: Dictionary = saved.get("stats", {})
	for stat in saved_stats:
		if stat in Fighters.STATS:
			stats[stat] = int(saved_stats[stat])
	var slot := str(saved.get("slot", "chest"))
	return {
		"id": int(saved.get("id", 0)),
		"name": str(saved.get("name", "Unknown Item")),
		"slot": slot if slot in Items.SLOTS else "chest",
		"quality": clampi(int(saved.get("quality", 0)), 0, Items.QUALITIES.size() - 1),
		"level": int(saved.get("level", 1)),
		"stats": stats,
		"armor": int(saved.get("armor", 0)),
	}
