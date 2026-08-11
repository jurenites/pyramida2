extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const Palette = preload("res://scripts/game_palette.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _count_colour(image: Image, colour: Color) -> int:
	var colour_count := 0
	for pixel_x in image.get_width():
		for pixel_y in image.get_height():
			if image.get_pixel(pixel_x, pixel_y) == colour:
				colour_count += 1
	return colour_count


func _run() -> void:
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var greenery_button := game.find_child("GreeneryModeButton", true, false) as Button
	var landscape_button := game.find_child("LandscapeModeButton", true, false) as Button
	var landscape_menu := game.find_child("BottomLandscapeMenu", true, false) as PanelContainer
	var remove_button := game.find_child("RemoveSoilButton", true, false) as Button
	var add_button := game.find_child("AddSoilButton", true, false) as Button
	_check(is_instance_valid(landscape_button), "Top toolbar has no Landscape Mode button")
	_check(
		is_instance_valid(greenery_button)
		and is_instance_valid(landscape_button)
		and landscape_button.get_index() == greenery_button.get_index() + 1,
		"Landscape button is not directly beside Building and Greenery"
	)
	_check(
		is_instance_valid(landscape_menu)
		and is_instance_valid(remove_button)
		and is_instance_valid(add_button),
		"Landscape Mode has no Add and Remove soil tool menu"
	)
	if is_instance_valid(landscape_button):
		var outline_image := (landscape_button.get_meta("normal_icon") as ImageTexture).get_image()
		var active_image := (landscape_button.get_meta("pressed_icon") as ImageTexture).get_image()
		_check(
			_count_colour(active_image, Palette.LIMESTONE_SIDE)
			> _count_colour(outline_image, Palette.LIMESTONE_SIDE),
			"Active dirt-and-shovel icon does not fill its outlined dirt pile"
		)

	game.call("_enter_landscape_mode")
	game.call("_update_interface")
	_check(bool(game.get("_landscape_mode")), "Landscape Mode did not activate")
	_check(not bool(game.get("_build_mode")), "Landscape Mode left Building Mode active")
	_check(not bool(game.get("_greenery_mode")), "Landscape Mode left Greenery Mode active")
	_check(landscape_button.button_pressed, "Landscape toolbar icon did not enter its active state")
	_check(landscape_menu.visible, "Landscape tool menu did not open")
	_check(remove_button.button_pressed, "Remove Soil was not the default Landscape tool")

	var occupied: Dictionary = game.get("_occupied_static_world_units")
	var citizens: Array = game.get("_citizens")
	var test_cell := Vector2i(8, 8)
	var found_test_cell := false
	for cell_x in range(-12, 13):
		for cell_z in range(-12, 13):
			var candidate := Vector2i(cell_x, cell_z)
			var citizen_occupies_candidate := false
			for citizen_value in citizens:
				var citizen := citizen_value as Citizen
				if GridNavigation.world_cell(citizen.global_position) == candidate:
					citizen_occupies_candidate = true
					break
			if not occupied.has(candidate) and not citizen_occupies_candidate:
				test_cell = candidate
				found_test_cell = true
				break
		if found_test_cell:
			break
	_check(found_test_cell, "Landscape test could not find an unoccupied terrain cell")

	var excavated_cells: Dictionary = game.get("_excavated_cells")
	var pit_roots: Dictionary = game.get("_excavated_pit_roots")
	_check(bool(game.call("_remove_base_terrain_block", test_cell)), "Remove Soil could not remove base terrain")
	_check(excavated_cells.has(test_cell), "Removed base cube was not recorded as a sparse terrain delta")
	_check(pit_roots.has(test_cell), "Removed base cube has no visible one-World-Unit pit")
	_check(bool(game.call("_restore_base_terrain_block", test_cell)), "Add Soil could not restore removed base terrain")
	_check(not excavated_cells.has(test_cell), "Restored base cube remains excavated")
	_check(not pit_roots.has(test_cell), "Restored base cube retained its pit geometry")

	var terrain_blocks: Dictionary = game.get("_terrain_blocks")
	var lower_block := Vector3i(test_cell.x, 0, test_cell.y)
	var upper_block := Vector3i(test_cell.x, 1, test_cell.y)
	_check(bool(game.call("_place_terrain_block", lower_block)), "Add Soil could not place a surface cube")
	_check(terrain_blocks.has(lower_block), "Placed surface cube is absent from sparse terrain state")
	_check(bool(game.call("_place_terrain_block", upper_block)), "Add Soil could not stack a second cube")
	_check(terrain_blocks.has(upper_block), "Stacked cube is absent from sparse terrain state")
	_check(
		not bool(game.call("_place_terrain_block", Vector3i(test_cell.x, 256, test_cell.y))),
		"Landscape tools placed terrain above height 255"
	)
	_check(bool(game.call("_remove_terrain_block", upper_block)), "Remove Soil could not remove stacked cube")
	_check(bool(game.call("_remove_terrain_block", lower_block)), "Remove Soil could not remove surface cube")
	_check(terrain_blocks.is_empty(), "Removed soil cubes remain in sparse terrain state")

	game.call("_set_landscape_tool", "add")
	_check(str(game.get("_landscape_tool")) == "add", "Add Soil tool did not become active")
	_check(add_button.button_pressed, "Add Soil button did not show its active state")
	game.call("_leave_landscape_mode")
	game.call("_update_interface")
	_check(not bool(game.get("_landscape_mode")), "Landscape Mode did not close")
	_check(not landscape_menu.visible, "Landscape tool menu stayed visible after closing")

	if _failures.is_empty():
		print("PASS: Landscape Mode and sparse terrain cubes")
		quit(0)
		return
	printerr("FAIL: Landscape Mode and sparse terrain cubes (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
