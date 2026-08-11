extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _fog_cell(world_position: Vector3) -> Vector2i:
	return Vector2i(floori(world_position.x / 0.5), floori(world_position.z / 0.5))


func _run() -> void:
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var revealed_cells: Dictionary = game.get("_revealed_fog_cells")
	var revealed_hit := Vector3(100.25, 0.0, 100.25)
	var hidden_hit := Vector3(120.25, 0.0, 120.25)
	revealed_cells[_fog_cell(revealed_hit)] = true

	_check(
		not bool(game.call("_hover_target_is_revealed", {"position": hidden_hit}, null)),
		"Unrevealed ground permits a hover tooltip"
	)
	_check(
		bool(game.call("_hover_target_is_revealed", {"position": revealed_hit}, null)),
		"Revealed ground incorrectly blocks its tooltip"
	)

	var hidden_object := Node3D.new()
	game.add_child(hidden_object)
	hidden_object.global_position = hidden_hit
	_check(
		not bool(game.call("_hover_target_is_revealed", {"position": revealed_hit}, hidden_object)),
		"Hidden object identity leaks through a revealed ray hit"
	)
	hidden_object.global_position = revealed_hit
	_check(
		bool(game.call("_hover_target_is_revealed", {"position": revealed_hit}, hidden_object)),
		"Fully revealed object incorrectly blocks its tooltip"
	)

	var tooltip := game.get("_hover_tooltip") as Label
	tooltip.visible = true
	tooltip.modulate.a = 1.0
	game.set("_hover_alpha", 1.0)
	game.set("_hover_target_visible", true)
	game.call("_hide_hover_tooltip_behind_fog")
	_check(not tooltip.visible, "Previous tooltip remains visible after cursor enters fog")
	_check(is_zero_approx(tooltip.modulate.a), "Fog-hidden tooltip retains visible opacity")
	_check(not bool(game.get("_hover_target_visible")), "Fog-hidden tooltip still targets visibility")

	if _failures.is_empty():
		print("PASS: fog blocks hover tooltip information")
		quit(0)
		return
	printerr("FAIL: fog hover tooltip (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
