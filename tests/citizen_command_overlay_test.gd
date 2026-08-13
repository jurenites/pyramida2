extends SceneTree

const CitizenCommandOverlayScript = preload("res://scripts/citizen_command_overlay.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var overlay := CitizenCommandOverlayScript.new()
	var camera := Camera3D.new()
	overlay.configure(camera)
	overlay._ensure_route_item(0)
	overlay._ensure_selection_item(0)
	_expect(overlay.layer == 90, "Citizen command overlay must retain its render layer")
	_expect(
		is_equal_approx((overlay.get_node("ContinuousRouteLine1") as Line2D).width, 2.0),
		"Citizen routes must retain their two-pixel width"
	)
	_expect(
		is_equal_approx((overlay.get_node("CitizenSelectionCircle1") as Line2D).width, 2.0),
		"Citizen selection circles must retain their two-pixel width"
	)
	_expect(
		is_equal_approx(
			CitizenCommandOverlayScript.SELECTION_RADIUS_WORLD,
			0.3168 * Citizen.CITIZEN_SCALE
		),
		"Citizen selection circle did not scale with the one-World-Unit body"
	)
	_expect(
		(overlay.get_node("RouteTargetDot1") as Polygon2D).polygon.size() == 12,
		"Citizen route targets must retain their twelve-point dot"
	)
	overlay.free()
	camera.free()
	if _failures.is_empty():
		print("PASS: citizen command overlay")
		quit(0)
		return
	printerr("FAIL: citizen command overlay (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)
