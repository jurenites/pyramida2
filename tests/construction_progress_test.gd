extends SceneTree

const ConstructionProgressScript = preload("res://scripts/construction_progress.gd")
const LabourProgressBarScript = preload("res://scripts/labour_progress_bar.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var recipe := {"hay": 2, "stone": 3}
	var seconds_by_resource := {"hay": 2.0, "stone": 4.0}
	var total_seconds := ConstructionProgressScript.total_required_seconds(
		recipe,
		seconds_by_resource
	)
	_check(
		is_equal_approx(total_seconds, 16.0),
		"Two Hay at two seconds plus three Stone at four seconds must total sixteen seconds"
	)
	var progress_bar := LabourProgressBarScript.new() as LabourProgressBar
	progress_bar.configure(total_seconds, 2.0, Color.WHITE)
	root.add_child(progress_bar)
	_check(
		is_equal_approx(progress_bar.size.x, 128.0),
		"Sixteen seconds does not produce the expected 128-pixel bar"
	)
	_check(
		is_equal_approx(
			ConstructionProgressScript.installed_seconds(
				{"hay": 1, "stone": 1},
				seconds_by_resource
			),
			6.0
		),
		"Installed mixed materials do not contribute their individual labour times"
	)

	if _failures.is_empty():
		print("PASS: mixed-material construction progress")
		quit(0)
		return
	printerr("FAIL: mixed-material construction progress (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
