extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const Palette = preload("res://scripts/game_palette.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _count_exact_colour(image: Image, colour: Color) -> int:
	var count := 0
	for pixel_x in image.get_width():
		for pixel_y in image.get_height():
			if image.get_pixel(pixel_x, pixel_y) == colour:
				count += 1
	return count


func _run() -> void:
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var category_row := game.find_child("ConstructionCategoryRow", true, false) as HBoxContainer
	var catalog_row := game.find_child("ConstructionCatalogRow", true, false) as HBoxContainer
	_check(is_instance_valid(category_row), "Construction category row was not created")
	_check(is_instance_valid(catalog_row), "Construction catalog row was not created")
	if is_instance_valid(category_row):
		_check(
			category_row.get_child_count() == 4,
			"Building menu must contain Path, Storage, Livable, and Structure categories"
		)
		var expected_categories := ["Path", "Storage", "Livable", "Structure"]
		for category_index in mini(expected_categories.size(), category_row.get_child_count()):
			_check(
				(category_row.get_child(category_index) as Button).name
				== "%sCategoryButton" % expected_categories[category_index],
				"Building category order changed"
			)
	if is_instance_valid(catalog_row):
		_check(catalog_row.get_child_count() == 4, "Structure must contain Support, Platform, Sawmill, and Remove building")
		if catalog_row.get_child_count() == 4:
			var support_button := catalog_row.get_child(0) as Button
			_check(support_button.name == "PlaceSupportButton", "First Building entry is not Support")
			var support_image := support_button.icon.get_image()
			_check(
				_count_exact_colour(support_image, Palette.SAND_SURFACE) >= 200,
				"Support thumbnail does not contain a full Sand World Unit"
			)
			_check(
				_count_exact_colour(support_image, Palette.ROOF_LOG) >= 30,
				"Support thumbnail does not visibly contain four completed Logs"
			)
			_check((catalog_row.get_child(1) as Button).name == "PlatformButton", "Structure has no Platform")
			_check(not (catalog_row.get_child(1) as Button).disabled, "Platform is not playable")
			_check((catalog_row.get_child(2) as Button).name == "SawmillButton", "Structure has no Sawmill")
			_check(not (catalog_row.get_child(2) as Button).disabled, "Sawmill is not playable")
			var remove_button := catalog_row.get_child(3) as Button
			_check(
				remove_button.name == "RemoveBuildingButton",
				"Last Building entry is not Remove building"
			)
			var remove_image := remove_button.icon.get_image()
			var black_pixels := _count_exact_colour(remove_image, Color.BLACK)
			_check(
				black_pixels >= 20 and black_pixels <= 180,
				"Remove building icon is not a sparse dotted Building outline"
			)

	game.call("_select_build_category", "path")
	_check(catalog_row.get_child_count() == 5, "Path must contain four Path forms and Remove building")
	var expected_path_entries := [
		"RoadButton", "RopeBridgeButton", "SuspensionBridgeButton", "TunnelButton",
	]
	for path_index in expected_path_entries.size():
		var path_button := catalog_row.get_child(path_index) as Button
		_check(path_button.name == expected_path_entries[path_index], "Path entry order changed")
		_check(path_button.disabled, "Unimplemented Path entry became falsely playable")

	game.call("_select_build_category", "storage")
	_check(catalog_row.get_child_count() == 3, "Storage must contain Pile, Warehouse, and Remove building")
	_check((catalog_row.get_child(0) as Button).name == "PileButton", "Storage does not begin with Pile")
	_check(not (catalog_row.get_child(0) as Button).disabled, "Free Pile is not playable")
	_check((catalog_row.get_child(1) as Button).name == "WarehouseButton", "Storage has no Warehouse")

	game.call("_select_build_category", "livable")
	_check(catalog_row.get_child_count() == 2, "Livable must contain Small home and Remove building")
	_check((catalog_row.get_child(0) as Button).name == "SmallLivableButton", "Livable has no Small home")

	if _failures.is_empty():
		print("PASS: categorized Building menu")
		quit(0)
		return
	printerr("FAIL: categorized Building menu (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
