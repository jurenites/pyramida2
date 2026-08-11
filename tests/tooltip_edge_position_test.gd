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

	var viewport_size := Vector2(800.0, 600.0)
	var tooltip_size := Vector2(100.0, 30.0)
	var left_position: Vector2 = game.call(
		"_world_tooltip_position", Vector2(5.0, 300.0), tooltip_size, viewport_size
	)
	var right_position: Vector2 = game.call(
		"_world_tooltip_position", Vector2(795.0, 300.0), tooltip_size, viewport_size
	)
	var top_position: Vector2 = game.call(
		"_world_tooltip_position", Vector2(400.0, 5.0), tooltip_size, viewport_size
	)
	var bottom_position: Vector2 = game.call(
		"_world_tooltip_position", Vector2(400.0, 595.0), tooltip_size, viewport_size
	)
	_check(left_position.x > 5.0, "Left-edge world tooltip does not open toward screen centre")
	_check(right_position.x + tooltip_size.x < 795.0, "Right-edge world tooltip does not open toward screen centre")
	_check(top_position.y > 5.0, "Top-edge world tooltip does not open toward screen centre")
	_check(bottom_position.y + tooltip_size.y < 595.0, "Bottom-edge world tooltip does not open toward screen centre")

	var building_menu := game.find_child("BottomConstructionCatalog", true, false) as PanelContainer
	var support_button := game.find_child("PlaceSupportButton", true, false) as Button
	var toolbar_tooltip := game.find_child("ToolbarTooltip", true, false) as PanelContainer
	building_menu.visible = true
	await process_frame
	game.call("_show_toolbar_tooltip", support_button, "Support")
	_check(
		toolbar_tooltip.position.y + toolbar_tooltip.size.y < support_button.get_global_rect().position.y,
		"Bottom Building-menu tooltip is not displayed above its button"
	)

	if _failures.is_empty():
		print("PASS: edge-aware tooltips")
		quit(0)
		return
	printerr("FAIL: edge-aware tooltips (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
