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
	var first_citizen := citizens[0] as Citizen
	var second_citizen := citizens[1] as Citizen
	var population_indicator := game.find_child("PopulationIndicator", true, false) as IconNumber
	var building_button := game.find_child("BuildingModeButton", true, false) as Button
	var quit_button := game.find_child("SaveQuitButton", true, false) as Button
	var population_font_size := population_indicator.number_label().get_theme_font_size("font_size")
	_check(
		population_indicator.scale_mode() == IconNumber.ScaleMode.STANDARD,
		"Population does not use Standard Icon Number"
	)
	_check(
		population_indicator.current_icon_size() == Vector2(44.0, 44.0),
		"Population icon does not use the standard toolbar size"
	)
	_check(
		population_indicator.current_icon_size() == building_button.custom_minimum_size,
		"Population icon is not the same size as the Building button"
	)
	_check(
		population_indicator.current_icon_size() == quit_button.custom_minimum_size,
		"Population icon is not the same size as the Quit button"
	)
	var preserved_yaw := 1.17
	var preserved_pitch := 0.61
	game.set("_camera_yaw", preserved_yaw)
	game.set("_camera_pitch", preserved_pitch)
	game.call("_update_camera_transform")

	_check(
		is_equal_approx(float(game.call("_citizen_camera_transition_duration", 0.0)), 0.1),
		"Nearby Citizen transition does not use the 0.1-second minimum"
	)
	_check(
		is_equal_approx(float(game.call("_citizen_camera_transition_duration", 100000.0)), 0.5),
		"Far Citizen transition does not use the 0.5-second maximum"
	)

	game.call("_focus_next_citizen_from_population")
	await create_timer(0.16).timeout
	_check(
		(game.get("_camera_focus") as Vector3).is_equal_approx(first_citizen.global_position),
		"First Population click did not focus the first Citizen"
	)
	_check(is_equal_approx(float(game.get("_camera_size")), 17.0), "Population focus did not use maximum zoom")
	_check(
		population_indicator.current_icon_size() == Vector2(44.0, 44.0),
		"Population icon changed size at maximum zoom-in"
	)
	_check(
		population_indicator.number_label().get_theme_font_size("font_size") == population_font_size,
		"Population zoom changed the number font size"
	)
	_check(is_equal_approx(float(game.get("_camera_yaw")), preserved_yaw), "Population focus changed camera rotation")
	_check(is_equal_approx(float(game.get("_camera_pitch")), preserved_pitch), "Population focus changed camera angle")

	game.call("_focus_next_citizen_from_population")
	await create_timer(0.2).timeout
	_check(
		(game.get("_camera_focus") as Vector3).is_equal_approx(second_citizen.global_position),
		"Second Population click did not focus the second Citizen"
	)
	game.call("_focus_next_citizen_from_population")
	await create_timer(0.2).timeout
	_check(
		(game.get("_camera_focus") as Vector3).is_equal_approx(first_citizen.global_position),
		"Population cycle did not wrap from the last Citizen to the first"
	)

	if _failures.is_empty():
		print("PASS: Population camera cycle")
		quit(0)
		return
	printerr("FAIL: Population camera cycle (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
