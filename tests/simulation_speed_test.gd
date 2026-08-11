extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var normal_citizen := Citizen.new()
	root.add_child(normal_citizen)
	normal_citizen.assign_task(Vector3(100.0, 0.0, 0.0), {"kind": "move"})
	normal_citizen.set_simulation_speed(1.0)
	normal_citizen.call("_process", 0.05)

	var fast_citizen := Citizen.new()
	root.add_child(fast_citizen)
	fast_citizen.assign_task(Vector3(100.0, 0.0, 0.0), {"kind": "move"})
	fast_citizen.set_simulation_speed(4.0)
	fast_citizen.call("_process", 0.05)

	var normal_distance := normal_citizen.global_position.x
	var fast_distance := fast_citizen.global_position.x
	if not is_equal_approx(fast_distance, normal_distance * 4.0):
		printerr(
			"FAIL: x4 simulation moved %.3f units after x1 moved %.3f"
			% [fast_distance, normal_distance]
		)
		normal_citizen.free()
		fast_citizen.free()
		quit(1)
		return

	print("PASS: simulation speed")
	normal_citizen.free()
	fast_citizen.free()
	quit(0)
