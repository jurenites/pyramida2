extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var loose_log := WorldItem.new()
	loose_log.configure("log", 2)
	root.add_child(loose_log)
	var loose_log_mesh := loose_log.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var loose_bounds := loose_log_mesh.mesh.get_aabb()

	var pile := PileStorage.new()
	pile.configure_starting_inventory(99)
	root.add_child(pile)
	await process_frame
	var contents := pile.get_node("StoredContents") as Node3D
	var stored_log_nodes: Array[Node] = []
	for child in contents.get_children():
		if child.name.begins_with("StoredLog_"):
			stored_log_nodes.append(child)

	_check(pile.stored_logs == PileStorage.LOG_CAPACITY, "Starting inventory was not clamped to 16 Logs")
	_check(stored_log_nodes.size() == 16, "Pile does not display exactly 16 full-capacity Logs")
	var layer_counts := [0, 0, 0, 0]
	var highest_point := 0.0
	for stored_log_node in stored_log_nodes:
		var stored_log := stored_log_node as MeshInstance3D
		var layer := int(stored_log.get_meta("stack_layer", -1))
		var slot := int(stored_log.get_meta("stack_slot", -1))
		var along_z := bool(stored_log.get_meta("along_z", false))
		_check(layer >= 0 and layer < 4, "Stored Log has an invalid stack layer")
		_check(slot >= 0 and slot < 4, "Stored Log has an invalid layer slot")
		if layer >= 0 and layer < 4:
			layer_counts[layer] += 1
			_check(along_z == (layer % 2 == 1), "Adjacent Pile layers are not rotated 90 degrees")
		var stored_bounds := stored_log.mesh.get_aabb()
		var stored_length := stored_bounds.size.z if along_z else stored_bounds.size.x
		_check(
			is_equal_approx(stored_length, loose_bounds.size.x),
			"Stored Log was resized instead of retaining loose-Log length"
		)
		highest_point = maxf(highest_point, stored_bounds.end.y)

	for layer in 4:
		_check(layer_counts[layer] == 4, "Pile layer %d does not contain four parallel Logs" % (layer + 1))
	_check(highest_point > 0.9, "Four-layer stack does not grow close to one World Unit")
	_check(highest_point <= 1.0, "Four-layer stack grows above one World Unit")
	_check(not pile.store_log(), "Pile accepted a seventeenth Log")
	_check(pile.stored_logs == 16, "Rejected seventeenth Log changed the stored count")

	loose_log.queue_free()
	pile.queue_free()
	if _failures.is_empty():
		print("PASS: full-size four-layer Pile Log stack")
		quit(0)
		return
	printerr("FAIL: full-size four-layer Pile Log stack (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
