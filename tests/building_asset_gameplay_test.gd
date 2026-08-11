extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")

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
	var pile := game.get("_starting_pile") as PileStorage
	var citizens: Array = game.get("_citizens")
	var citizen := citizens[0] as Citizen

	var platform := SupportConstructionSite.new()
	platform.configure("platform")
	game.add_child(platform)
	platform.global_position = Vector3(8.0, 0.0, 8.0)
	_check(platform.construction_recipe() == {"log": 4, "plank": 4}, "Playable Platform recipe differs from its asset")
	for log_index in 4:
		_check(platform.deliver_resource("log"), "Platform rejected required Log %d" % (log_index + 1))
	_check(platform.next_required_resource() == "plank", "Platform does not request Planks after its Supports")
	pile.store_resource("plank", 1)
	game.call("_handle_fetch_log_arrival", citizen, {
		"source_pile": pile,
		"construction_site": platform,
		"resource_kind": "plank",
	})
	game.call("_handle_deliver_log_arrival", citizen, citizen.task.duplicate(true))
	game.call("_update_labour", 2.9)
	_check(
		int(platform.installed_resource_counts().get("plank", 0)) == 0,
		"Platform installed a Plank before three seconds of labour"
	)
	game.call("_update_labour", 0.2)
	_check(
		int(platform.installed_resource_counts().get("plank", 0)) == 1,
		"Platform did not install its carried Plank after three seconds"
	)
	for plank_index in 3:
		_check(platform.deliver_resource("plank"), "Platform rejected required Plank %d" % (plank_index + 1))
	_check(platform.is_complete(), "Platform did not complete from four Logs and four Planks")
	_check(
		platform.find_children("*", "MeshInstance3D", true, false).size() >= 8,
		"Platform runtime model is missing synchronized asset parts"
	)

	var sawmill := SupportConstructionSite.new()
	sawmill.configure("sawmill")
	game.add_child(sawmill)
	sawmill.global_position = Vector3(10.0, 0.0, 8.0)
	for log_index in 10:
		_check(sawmill.deliver_resource("log"), "Sawmill rejected construction Log %d" % (log_index + 1))
	_check(sawmill.is_complete() and sawmill.is_workshop(), "Completed Sawmill is not an active workshop")

	var logs_before := pile.stored_logs
	var planks_before := pile.resource_count("plank")
	game.call("_order_process_sawmill", citizen, sawmill)
	game.call("_handle_fetch_workshop_input_arrival", citizen, citizen.task.duplicate(true))
	game.call("_handle_sawmill_arrival", citizen, citizen.task.duplicate(true))
	game.call("_update_labour", 3.1)
	_check(pile.stored_logs == logs_before - 1, "Sawmill did not consume exactly one Log")
	_check(pile.resource_count("plank") == planks_before + 1, "Sawmill did not produce exactly one Plank")

	game.call("_place_building", Vector3(15.5, 0.0, 15.5), "pile", false)
	var placed_piles: Array = game.get("_placed_piles")
	_check(placed_piles.size() == 1, "Free Pile placement did not create a Pile")
	if not placed_piles.is_empty():
		var placed_pile := placed_piles[0] as PileStorage
		_check(
			placed_pile.find_children("PileBoundaryStone_*", "MeshInstance3D", true, false).size() == 4,
			"Buildable Pile does not use four corner stones"
		)

	if _failures.is_empty():
		print("PASS: Platform, Sawmill processing, and free Pile gameplay")
		quit(0)
		return
	printerr("FAIL: Building asset gameplay (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
