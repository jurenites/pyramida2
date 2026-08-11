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

	var catalog_row := game.find_child("ConstructionCatalogRow", true, false) as HBoxContainer
	_check(is_instance_valid(catalog_row), "Construction catalog row was not created")
	if is_instance_valid(catalog_row):
		_check(
			catalog_row.get_child_count() == 2,
			"Building menu must contain Support followed by Remove building"
		)
		if catalog_row.get_child_count() == 2:
			var support_button := catalog_row.get_child(0) as Button
			_check(support_button.name == "PlaceSupportButton", "First Building entry is not Support")
			var support_image := support_button.icon.get_image()
			_check(
				_count_exact_colour(support_image, Palette.SAND_SURFACE) >= 300,
				"Support thumbnail does not contain a full Sand World Unit"
			)
			_check(
				_count_exact_colour(support_image, Palette.ROOF_LOG) >= 30,
				"Support thumbnail does not visibly contain four completed Logs"
			)
			var remove_button := catalog_row.get_child(1) as Button
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

	if _failures.is_empty():
		print("PASS: Support and Remove building menu")
		quit(0)
		return
	printerr("FAIL: Support and Remove building menu (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
