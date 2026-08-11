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

	var construction_site := SupportConstructionSite.new()
	game.add_child(construction_site)
	construction_site.global_position = Vector3(3.5, 0.0, 3.5)
	var construction_sites: Array = game.get("_construction_sites")
	construction_sites.append(construction_site)
	game.call("_select_building", construction_site)
	game.call("_update_building_hotkey_hint")
	var rotation_hint := game.get("_building_hotkey_hint") as Control
	_check(rotation_hint.visible, "Unfinished selected Construction Site has no rotation option")

	game.call("_rotate_selected_building", 1)
	await create_timer(0.2).timeout
	_check(
		int(construction_site.get_meta("rotation_quarters", 0)) == 1,
		"Unfinished Construction Site did not record its quarter-turn"
	)
	_check(
		is_equal_approx(construction_site.rotation.y, PI * 0.5),
		"Unfinished Construction Site did not rotate ninety degrees"
	)

	for _required_log in SupportConstructionSite.REQUIRED_LOGS:
		construction_site.deliver_log()
	game.call("_update_building_hotkey_hint")
	_check(not rotation_hint.visible, "Completed Building still displays the rotation option")
	var locked_quarters := int(construction_site.get_meta("rotation_quarters", 0))
	var locked_rotation := construction_site.rotation.y
	game.call("_rotate_selected_building", 1)
	await create_timer(0.2).timeout
	_check(
		int(construction_site.get_meta("rotation_quarters", 0)) == locked_quarters,
		"Completed Building accepted another quarter-turn"
	)
	_check(
		is_equal_approx(construction_site.rotation.y, locked_rotation),
		"Completed Building changed its locked orientation"
	)

	if _failures.is_empty():
		print("PASS: Building rotation is limited to Construction Site stage")
		quit(0)
		return
	printerr("FAIL: Building rotation stage (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
