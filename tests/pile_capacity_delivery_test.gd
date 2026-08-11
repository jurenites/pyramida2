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
	pile.configure_starting_inventory(PileStorage.LOG_CAPACITY)
	var citizens: Array = game.get("_citizens")
	var citizen := citizens[0] as Citizen
	var loose_log := WorldItem.new()
	loose_log.configure("log", 71)
	game.add_child(loose_log)
	loose_log.global_position = citizen.global_position
	var items: Array = game.get("_items")
	items.append(loose_log)
	_check(loose_log.take_for_carry(), "Test Log could not be carried")
	citizen.set_carrying_log(true)
	citizen.task = {"kind": "deliver_log", "log": loose_log, "pile_storage": pile}

	game.call("_handle_deliver_log_arrival", citizen, citizen.task.duplicate(true))
	_check(pile.stored_logs == 16, "Full Pile accepted a seventeenth Log during delivery")
	_check(is_instance_valid(loose_log), "Rejected seventeenth Log was destroyed")
	_check(loose_log.visible and not loose_log.is_carried, "Rejected Log was not returned to the ground")
	_check(items.has(loose_log), "Rejected Log disappeared from the physical resource registry")
	_check(citizen.task.is_empty(), "Citizen kept collecting Logs after the Pile became full")

	if _failures.is_empty():
		print("PASS: full Pile preserves rejected physical Log")
		quit(0)
		return
	printerr("FAIL: full Pile delivery (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
