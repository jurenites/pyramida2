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

	game.call("_ensure_support_placement_preview")
	var preview := game.get("_support_placement_preview") as Node3D
	_check(preview != null, "Support placement preview was not created")
	if preview != null:
		_check(
			preview.find_children("*", "Label3D", true, false).is_empty(),
			"Support placement still creates a world-space explanation label"
		)

	var invalid_placement := game.call(
		"_support_placement_evaluation",
		Vector3(-100000.0, 0.0, -100000.0)
	) as Dictionary
	_check(not bool(invalid_placement.get("valid", true)), "Outside placement was accepted")
	_check(
		not invalid_placement.has("reason_text"),
		"Placement evaluation still exposes removed explanation text"
	)

	if _failures.is_empty():
		print("PASS: support placement uses colour feedback without explanation text")
		quit(0)
		return
	printerr("FAIL: support placement feedback (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
