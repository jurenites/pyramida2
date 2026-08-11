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

	var stamp := game.find_child("BuildStamp", true, false) as Label
	_check(stamp != null, "Version stamp was not created")
	if stamp != null:
		_check(stamp.get_theme_color("font_color") == Color.WHITE, "Version stamp is not pure white")
		_check(stamp.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "Version stamp is not right aligned")
		_check(is_equal_approx(stamp.anchor_right, 1.0), "Version stamp is not anchored to the right edge")
		_check(is_equal_approx(stamp.anchor_bottom, 1.0), "Version stamp is not anchored to the bottom edge")
		_check(
			is_equal_approx(absf(stamp.offset_right), absf(stamp.offset_bottom)),
			"Version stamp does not use equal right and bottom edge spacing"
		)
		_check(is_equal_approx(stamp.offset_right, -11.0), "Version stamp right gap is not 11 pixels")
		_check(is_equal_approx(stamp.offset_bottom, -11.0), "Version stamp bottom gap changed")

	if _failures.is_empty():
		print("PASS: build stamp layout")
		quit(0)
		return
	printerr("FAIL: build stamp layout (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
