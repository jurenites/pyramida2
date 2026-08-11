extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const ActionCatalog = preload("res://scripts/gameplay_action_catalog.gd")

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

	var bush: WorldItem
	for item_value in game.get("_items"):
		var item := item_value as WorldItem
		if item.can_harvest():
			bush = item
			break
	var citizens: Array = game.get("_citizens")
	var citizen := citizens[0] as Citizen
	var pile := game.get("_starting_pile") as PileStorage
	_check(is_instance_valid(bush), "Startup generated no harvestable Berry Bush")
	_check(is_instance_valid(pile), "Startup generated no Pile")
	if is_instance_valid(bush) and is_instance_valid(pile):
		var calories_before := pile.stored_calories
		citizen.set_work_assignment({"kind": ActionCatalog.HARVEST_BUSH})
		game.call("_complete_bush_harvest_work", citizen, bush)
		_check(
			str(citizen.task.get("kind", "")) == ActionCatalog.DELIVER_FOOD,
			"Harvest completion did not assign a carry-to-Pile task"
		)
		_check(pile.stored_calories == calories_before, "Calories reached the Pile before delivery")
		var carried_food := citizen.find_child("CarriedFood", true, false) as Node3D
		_check(is_instance_valid(carried_food) and carried_food.visible, "Citizen does not visibly carry berries")
		var delivery_task := citizen.task.duplicate(true)
		game.call("_handle_deliver_food_arrival", citizen, delivery_task)
		_check(pile.stored_calories == calories_before + 1, "Delivered berries did not add one Calories")
		_check(
			not is_instance_valid(carried_food) or not carried_food.visible,
			"Carried berries remain visible after Pile delivery"
		)

	if _failures.is_empty():
		print("PASS: Berry Bush to Pile delivery")
		quit(0)
		return
	printerr("FAIL: Berry Bush to Pile delivery (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
