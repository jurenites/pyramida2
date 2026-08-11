extends SceneTree

const Palette = preload("res://scripts/game_palette.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	for visual_variant in ["woman", "man"]:
		var citizen := Citizen.new()
		citizen.configure_visual_variant(visual_variant)
		root.add_child(citizen)
		citizen.set_process(false)
		await process_frame

		var bedding := citizen.get_node("SleepBedding") as Node3D
		var pillow := bedding.get_node("SleepPillow") as MeshInstance3D
		var blanket := bedding.get_node("SleepBlanket") as MeshInstance3D
		var chest := citizen.find_child("BreathingChest", true, false) as MeshInstance3D
		var expected_colour := (
			Palette.WOMAN_CLOTHING
			if visual_variant == "woman"
			else Palette.HAY_FIELD
		)

		_check(not bedding.visible, "%s sleep bedding is visible while awake" % visual_variant)
		_check(
			(pillow.material_override as StandardMaterial3D).albedo_color == expected_colour,
			"%s pillow does not exactly match clothing colour" % visual_variant
		)
		_check(
			(blanket.material_override as StandardMaterial3D).albedo_color == expected_colour,
			"%s blanket does not exactly match clothing colour" % visual_variant
		)

		var awake_chest_scale := chest.scale
		citizen.set_sleeping(true)
		citizen.call("_process", 0.0)
		_check(bedding.visible, "%s sleep bedding did not appear while asleep" % visual_variant)
		var first_chest_scale := chest.scale.x
		var first_blanket_height := blanket.position.y
		citizen.call("_process", PI / 1.8)
		_check(
			chest.scale.x > first_chest_scale,
			"%s chest does not expand during the breathing cycle" % visual_variant
		)
		_check(
			blanket.position.y > first_blanket_height,
			"%s blanket does not rise during the breathing cycle" % visual_variant
		)

		citizen.set_sleeping(false)
		_check(not bedding.visible, "%s sleep bedding remains visible after waking" % visual_variant)
		_check(
			chest.scale.is_equal_approx(awake_chest_scale),
			"%s chest scale was not restored after waking" % visual_variant
		)
		citizen.queue_free()
		await process_frame

	if _failures.is_empty():
		print("PASS: sleep visual")
		quit(0)
		return
	printerr("FAIL: sleep visual (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
