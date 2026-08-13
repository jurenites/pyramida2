extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const ActionCatalog = preload("res://scripts/gameplay_action_catalog.gd")
const GameplaySettingsScript = preload("res://scripts/gameplay_settings.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.call("_place_building", Vector3(15.5, 0.0, 15.5), "pile", false)
	var placed_piles: Array = game.get("_placed_piles")
	var second_pile := placed_piles[0] as PileStorage
	var starting_pile := game.get("_starting_pile") as PileStorage
	starting_pile.configure_starting_inventory(PileStorage.LOG_CAPACITY)
	var citizens: Array = game.get("_citizens")
	var citizen := citizens[0] as Citizen
	var loose_log := WorldItem.new()
	loose_log.configure("log", 902)
	game.add_child(loose_log)
	loose_log.global_position = citizen.global_position
	var items: Array = game.get("_items")
	items.append(loose_log)
	_check(loose_log.take_for_carry(), "Test Log could not be carried")
	citizen.set_carrying_log(true)
	citizen.task = {
		"kind": ActionCatalog.DELIVER_LOG,
		"log": loose_log,
		"pile_storage": starting_pile,
		"pickup_position": citizen.global_position - Vector3.RIGHT,
	}
	game.call("_handle_deliver_log_arrival", citizen, citizen.task.duplicate(true))
	_check(
		citizen.task.get("pile_storage") == second_pile,
		"A full first Pile did not redirect the carried Log to the second Pile"
	)
	citizen.global_position = citizen.route_target()
	game.call("_handle_deliver_log_arrival", citizen, citizen.task.duplicate(true))
	var active_log_work: Dictionary = game.get("_active_work").get(citizen, {})
	var log_labour_key := str(active_log_work.get("labour_key", ""))
	var log_labour_record: Dictionary = game.get("_labour_records").get(log_labour_key, {})
	var log_labour_bar := log_labour_record.get("bar") as LabourProgressBar
	_check(is_instance_valid(log_labour_bar) and not log_labour_bar.visible, "Pile delivery displayed a labour progress bar")
	game.call("_update_labour", GameplaySettingsScript.STORAGE_DELIVERY_LABOUR_SECONDS)
	_check(second_pile.stored_logs == 1, "The redirected Log did not reach the second Pile")

	var bush: WorldItem
	for item_value in items:
		var item := item_value as WorldItem
		if is_instance_valid(item) and item.can_harvest():
			bush = item
			break
	_check(is_instance_valid(bush), "Startup generated no harvestable Berry Bush")
	if is_instance_valid(bush):
		citizen.global_position = Vector3(14.5, 0.0, 15.5)
		citizen.set_work_assignment({"kind": ActionCatalog.HARVEST_BUSH})
		game.call("_complete_bush_harvest_work", citizen, bush)
		_check(
			citizen.task.get("pile_storage") == second_pile,
			"Gathered berries did not choose the nearest reachable Pile"
		)
		var pickup_position: Vector3 = citizen.task.get("pickup_position", citizen.global_position)
		_check(
			pickup_position.distance_to(citizen.route_target()) >= GameplaySettingsScript.MINIMUM_DELIVERY_TRAVEL_DISTANCE,
			"Berry delivery route is shorter than half a World Unit"
		)
		citizen.global_position = citizen.route_target()
		game.call("_handle_deliver_food_arrival", citizen, citizen.task.duplicate(true))
		_check(second_pile.stored_calories == 0, "Berries entered storage before one second of delivery labour")
		game.call("_update_labour", GameplaySettingsScript.STORAGE_DELIVERY_LABOUR_SECONDS)
		_check(second_pile.stored_calories == 1, "Berries did not reach the second Pile")
		_check(
			int(game.get("_calories")) == 1,
			"Global Calories did not include storage outside the starting Pile"
		)

	if _failures.is_empty():
		print("PASS: multiple-Pile gathered-resource delivery")
		quit(0)
		return
	printerr("FAIL: multiple-Pile gathered-resource delivery (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
