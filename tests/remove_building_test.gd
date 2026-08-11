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

	var building := SupportConstructionSite.new()
	game.add_child(building)
	building.global_position = Vector3(4.5, 0.0, 4.5)
	for unused_log in SupportConstructionSite.REQUIRED_LOGS:
		building.deliver_log()
	var construction_sites: Array = game.get("_construction_sites")
	construction_sites.append(building)
	var excavation_count_before := (game.get("_excavation_sites") as Array).size()

	var citizens: Array = game.get("_citizens")
	var citizen := citizens[0] as Citizen
	citizen.task = {"kind": "move", "target": building}

	game.call("_enter_build_mode", false)
	game.call("_toggle_remove_building_tool")
	_check(bool(game.get("_removing_buildings")), "Remove building did not activate")
	_check(not bool(game.get("_placing_support")), "Remove building still permits Support placement")
	_check(not bool(game.get("_placing_excavation")), "Remove building still permits excavation placement")

	var removed := bool(game.call("_remove_world_object", building))
	_check(removed, "Completed building was not accepted by Remove building")
	_check(not building.visible, "Removed building remained visible for an extra frame")
	_check(building.is_queued_for_deletion(), "Removed building was not queued for deletion")
	_check(not construction_sites.has(building), "Removed building remained in the construction registry")
	_check(citizen.task.is_empty(), "Citizen kept a job targeting the removed building")
	_check(
		(game.get("_excavation_sites") as Array).size() == excavation_count_before,
		"Removing a building created a map marker or Excavation Site"
	)
	_check(bool(game.get("_removing_buildings")), "Remove building unexpectedly stopped after one use")

	await process_frame
	_check(not is_instance_valid(building), "Removed building still exists after the frame completed")

	if _failures.is_empty():
		print("PASS: Remove building tool")
		quit(0)
		return
	printerr("FAIL: Remove building tool (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
