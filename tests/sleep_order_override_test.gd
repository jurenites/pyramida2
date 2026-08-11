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

	var citizens: Array = game.get("_citizens")
	var citizen := citizens[0] as Citizen
	var target_tree := WorldItem.new()
	target_tree.configure("tree", 101)
	game.add_child(target_tree)
	target_tree.global_position = citizen.global_position + Vector3(3.0, 0.0, 0.0)
	var items: Array = game.get("_items")
	items.append(target_tree)

	var selection: Array[Citizen] = [citizen]
	game.call("_set_selected_citizens", selection)
	game.call("_set_citizens_sleeping", true)
	_check(citizen.is_sleeping(), "Citizen did not enter sleep before the direct order")

	game.call("_order_group_chop", target_tree)
	_check(not citizen.is_sleeping(), "Direct Tree order did not wake the sleeping Citizen")
	_check(
		str(citizen.task.get("kind", "")) == GameplayActionCatalog.CHOP_TREE,
		"Awakened Citizen did not receive the Tree job"
	)
	_check(
		citizen.work_assignment.is_empty(),
		"Sleep-overriding Tree order incorrectly became continuous work"
	)

	# This is the continuation point reached after the one Log has been cut and
	# delivered. An empty assignment must stop instead of selecting another Tree.
	game.call("_continue_persistent_assignment", citizen)
	_check(citizen.task.is_empty(), "One-shot awakened Citizen continued into another job")

	if _failures.is_empty():
		print("PASS: sleep order override")
		quit(0)
		return
	printerr("FAIL: sleep order override (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
