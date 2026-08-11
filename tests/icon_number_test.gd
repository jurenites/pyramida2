extends SceneTree

const IconNumberScript = preload("res://scripts/icon_number.gd")
const ToolbarIcons = preload("res://scripts/toolbar_icon_renderer.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var full_scale := IconNumberScript.new() as IconNumber
	full_scale.configure(
		ToolbarIcons.create_resource_icon("log", 40),
		null,
		2,
		IconNumber.ScaleMode.FULL_SCALE,
		Vector2(40.0, 40.0),
		22
	)
	root.add_child(full_scale)
	var fixed_font_size := full_scale.number_label().get_theme_font_size("font_size")
	_check(full_scale.current_icon_size() == Vector2(40.0, 40.0), "Full Scale icon does not begin at 1x")
	full_scale.apply_camera_zoom(17.0, 17.0, 34.0)
	_check(full_scale.current_icon_size() == Vector2(80.0, 80.0), "Full Scale icon does not reach 2x at close zoom")
	_check(
		full_scale.number_label().get_theme_font_size("font_size") == fixed_font_size,
		"Full Scale camera zoom changed the number font size"
	)
	full_scale.apply_camera_zoom(34.0, 17.0, 34.0)
	_check(full_scale.current_icon_size() == Vector2(40.0, 40.0), "Full Scale icon does not return to 1x")
	full_scale.set_number(17)
	_check(full_scale.number_label().text == "17", "Icon Number did not update its integer")
	full_scale.set_fraction(1, 4)
	_check(full_scale.number_label().text == "1/4", "Icon Number did not display an installed/required fraction")

	var compact := IconNumberScript.new() as IconNumber
	compact.configure(
		ToolbarIcons.create_resource_icon("log", 10),
		null,
		6,
		IconNumber.ScaleMode.COMPACT,
		Vector2(10.0, 10.0),
		14
	)
	root.add_child(compact)
	compact.apply_camera_zoom(17.0, 17.0, 34.0)
	_check(compact.current_icon_size() == Vector2(10.0, 10.0), "Compact icon incorrectly follows camera zoom")

	var standard := IconNumberScript.new() as IconNumber
	standard.configure(
		ToolbarIcons.create_icon("population"),
		null,
		2,
		IconNumber.ScaleMode.STANDARD,
		Vector2(44.0, 44.0),
		22
	)
	root.add_child(standard)
	standard.apply_camera_zoom(17.0, 17.0, 34.0)
	_check(
		standard.current_icon_size() == Vector2(44.0, 44.0),
		"Standard Icon Number incorrectly follows camera zoom"
	)

	if _failures.is_empty():
		print("PASS: Icon Number scale and typography contracts")
		quit(0)
		return
	printerr("FAIL: Icon Number contracts (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
