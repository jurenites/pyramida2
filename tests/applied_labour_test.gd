extends SceneTree

const AppliedLabourScript = preload("res://scripts/applied_labour.gd")
const LabourProgressBarScript = preload("res://scripts/labour_progress_bar.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_test_interrupted_labour_resumes_from_applied_time()
	_test_another_actor_can_continue_the_same_labour()
	_test_bar_width_scales_with_required_seconds()
	if _failures.is_empty():
		print("PASS: applied labour")
		quit(0)
		return
	printerr("FAIL: applied labour (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _test_interrupted_labour_resumes_from_applied_time() -> void:
	var labour := AppliedLabourScript.new(3.0)
	_expect(not labour.apply(1, 1.0), "One second must not complete three seconds of labour")
	_expect(is_equal_approx(labour.applied_seconds, 1.0), "Applied labour must retain one second")
	_expect(is_equal_approx(labour.remaining_seconds(), 2.0), "Two seconds must remain")
	labour.interrupt(1)
	labour.update_interruption(1.9)
	_expect(labour.should_be_visible(), "Interrupted labour must remain visible during its grace time")
	labour.update_interruption(0.2)
	_expect(not labour.should_be_visible(), "Interrupted labour must hide after its grace time")
	_expect(is_equal_approx(labour.applied_seconds, 1.0), "Hidden labour must retain applied time")
	_expect(labour.apply(1, 2.0), "Resumed labour must finish from its remaining time")
	_expect(is_equal_approx(labour.progress_ratio(), 1.0), "Completed labour must report full progress")


func _test_another_actor_can_continue_the_same_labour() -> void:
	var labour := AppliedLabourScript.new(3.0)
	labour.apply(10, 1.0)
	labour.interrupt(10)
	_expect(not labour.apply(20, 1.0), "A replacement actor must continue without prematurely completing")
	_expect(is_equal_approx(labour.applied_seconds, 2.0), "Applied time must belong to the job, not its actor")
	_expect(labour.is_being_applied(), "The replacement actor must activate the labour job")


func _test_bar_width_scales_with_required_seconds() -> void:
	var three_second_bar := LabourProgressBarScript.new()
	three_second_bar.configure(3.0, 2.0, Color.RED)
	var six_second_bar := LabourProgressBarScript.new()
	six_second_bar.configure(6.0, 2.0, Color.RED)
	_expect(is_equal_approx(three_second_bar.size.x, 24.0), "Three-second labour bar must be 24 pixels wide")
	_expect(
		is_equal_approx(three_second_bar.size.y, 8.0),
		"Labour bar must be 8 pixels high; resolved height is %.3f" % three_second_bar.size.y
	)
	_expect(is_equal_approx(six_second_bar.size.x, 48.0), "Six-second labour bar must be 48 pixels wide")
	_expect(
		is_equal_approx(six_second_bar.size.x, three_second_bar.size.x * 2.0),
		"Six-second labour bar must be twice as wide as three-second labour"
	)
	_expect(
		is_equal_approx(three_second_bar.outline_pixels(), 2.0),
		"Applied labour must use the shared two-pixel outline"
	)
	_expect(three_second_bar.corner_radius_pixels() == 3, "Labour bar corners must be rounded")
	_expect(three_second_bar.pivot_offset == three_second_bar.size * 0.5, "Labour bar must tilt around its centre")
	three_second_bar.set_sun_screen_side(1.0)
	_expect(is_equal_approx(three_second_bar.rotation_degrees, 2.0), "Right-side sun must tilt the bar right")
	three_second_bar.set_sun_screen_side(-1.0)
	_expect(is_equal_approx(three_second_bar.rotation_degrees, -2.0), "Left-side sun must tilt the bar left")
	three_second_bar.set_sun_screen_side(0.0)
	_expect(is_zero_approx(three_second_bar.rotation_degrees), "Centred sun must not tilt the bar")
	var interior := three_second_bar.inner_rect()
	_expect(interior.position == Vector2(2.0, 2.0), "Labour fill must begin inside the outline")
	_expect(is_equal_approx(interior.size.y, 4.0), "Labour fill interior must be four pixels high")
	three_second_bar.set_progress_ratio(1.0 / 3.0)
	_expect(
		absf(three_second_bar.progress_ratio() - 1.0 / 3.0) < 0.002,
		"One applied second must fill one third of a three-second bar"
	)
	six_second_bar.set_progress_ratio(1.0 / 6.0)
	_expect(
		three_second_bar.filled_rect().position == Vector2(2.0, 2.0),
		"Three-second fill must remain behind and inside the outline"
	)
	_expect(
		is_equal_approx(three_second_bar.filled_rect().size.y, 4.0),
		"Three-second fill must not cover either horizontal outline"
	)
	_expect(
		six_second_bar.filled_rect().position == Vector2(2.0, 2.0),
		"Six-second fill must remain behind and inside the outline"
	)
	_expect(
		six_second_bar.filled_rect().end.x <= six_second_bar.size.x - 2.0,
		"Labour fill must never extend across the right outline"
	)
	six_second_bar.set_progress_ratio(1.0)
	_expect(
		is_equal_approx(six_second_bar.filled_rect().end.x, six_second_bar.size.x - 2.0),
		"Completed labour must stop at the inside edge of the right outline"
	)
	three_second_bar.free()
	six_second_bar.free()


func _expect(condition: bool, failure: String) -> void:
	if not condition:
		_failures.append(failure)
