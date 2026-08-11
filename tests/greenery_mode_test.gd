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

	var building_button := game.find_child("BuildingModeButton", true, false) as Button
	var greenery_button := game.find_child("GreeneryModeButton", true, false) as Button
	_check(is_instance_valid(greenery_button), "Top toolbar has no Greenery Mode tree button")
	_check(
		is_instance_valid(building_button)
		and is_instance_valid(greenery_button)
		and greenery_button.get_parent() == building_button.get_parent()
		and greenery_button.get_index() == building_button.get_index() + 1,
		"Greenery Mode button is not directly beside the Building button"
	)

	game.call("_enter_greenery_mode")
	game.call("_update_interface")
	_check(bool(game.get("_greenery_mode")), "Greenery Mode did not activate")
	_check(not bool(game.get("_build_mode")), "Greenery Mode left Building Mode active")
	_check(greenery_button.button_pressed, "Tree toolbar button did not show its active state")

	var empty_cells: Array[Vector2i] = []
	var occupied: Dictionary = game.get("_occupied_static_world_units")
	for cell_x in range(-10, 11):
		for cell_z in range(-10, 11):
			var candidate := Vector2i(cell_x, cell_z)
			if not occupied.has(candidate):
				empty_cells.append(candidate)
			if empty_cells.size() >= 2:
				break
		if empty_cells.size() >= 2:
			break
	_check(empty_cells.size() >= 2, "Test world has no two empty relocation cells")
	if empty_cells.size() >= 2:
		var source_cell := empty_cells[0]
		var destination_cell := empty_cells[1]
		var bush := game.call(
			"_spawn_item",
			"bush",
			Vector3(float(source_cell.x) + 0.5, 0.0, float(source_cell.y) + 0.5),
			811
		) as WorldItem
		occupied[source_cell] = true
		var bush_cells: Dictionary = game.get("_occupied_bush_world_units")
		bush_cells[source_cell] = true
		game.set("_selected_greenery", bush)
		game.call("_select_world_object", bush)
		var moved := bool(game.call(
			"_try_relocate_selected_greenery",
			Vector3(float(destination_cell.x) + 0.5, 0.0, float(destination_cell.y) + 0.5)
		))
		_check(moved, "Selected Bush could not be moved to an empty revealed World Unit")
		_check(
			game.call("_world_unit_cell", bush.global_position) == destination_cell,
			"Moved Bush did not root in its destination World Unit"
		)
		_check(not occupied.has(source_cell), "Moved Bush left its source cell occupied")
		_check(occupied.has(destination_cell), "Moved Bush did not occupy its destination cell")

	game.call("_leave_greenery_mode")
	game.call("_update_interface")
	_check(not bool(game.get("_greenery_mode")), "Greenery Mode did not close")
	_check(not greenery_button.button_pressed, "Tree toolbar button stayed active after closing")

	if _failures.is_empty():
		print("PASS: Greenery Mode toolbar and Bush relocation")
		quit(0)
		return
	printerr("FAIL: Greenery Mode toolbar and Bush relocation (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
