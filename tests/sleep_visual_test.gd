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
		var contact_shadow := citizen.get_node("CitizenContactShadow") as MeshInstance3D
		var selection_shape := citizen.find_child(
			"CitizenSelectionShape", true, false
		) as CollisionShape3D
		var expected_colour := (
			Palette.WOMAN_CLOTHING
			if visual_variant == "woman"
			else Palette.HAY_FIELD
		)
		var standing_minimum_y := INF
		var standing_maximum_y := -INF
		for body_mesh_value in (citizen.get("_visual") as Node3D).find_children(
			"*", "MeshInstance3D", true, false
		):
			var body_mesh := body_mesh_value as MeshInstance3D
			if not body_mesh.is_visible_in_tree():
				continue
			var world_bounds := body_mesh.global_transform * body_mesh.get_aabb()
			standing_minimum_y = minf(standing_minimum_y, world_bounds.position.y)
			standing_maximum_y = maxf(standing_maximum_y, world_bounds.end.y)
		_check(
			standing_maximum_y - standing_minimum_y <= Citizen.WORLD_UNIT_HEIGHT + 0.001,
			"%s Citizen is taller than one World Unit" % visual_variant
		)
		_check(
			standing_maximum_y >= Citizen.WORLD_UNIT_HEIGHT - 0.001,
			"%s Citizen does not fill the intended one-World-Unit height" % visual_variant
		)

		_check(not bedding.visible, "%s sleep bedding is visible while awake" % visual_variant)
		_check(contact_shadow.visible, "%s contact shadow is hidden while awake" % visual_variant)
		_check(
			(contact_shadow.material_override as StandardMaterial3D).albedo_color
			== Palette.FOG_AND_SHADOW,
			"%s contact shadow does not use the shared fog/shadow colour" % visual_variant
		)
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
		_check(not contact_shadow.visible, "%s contact shadow remains visible while asleep" % visual_variant)
		_check(
			is_equal_approx(selection_shape.rotation.z, -PI * 0.5),
			"%s sleeping selection capsule is not horizontal" % visual_variant
		)
		_check(
			selection_shape.position.is_equal_approx(
				Vector3(0.0, Citizen.SLEEPING_SELECTION_CENTRE_HEIGHT, 0.0)
			),
			"%s sleeping selection capsule is not centred on the lying Citizen" % visual_variant
		)
		_check(
			citizen.selection_world_position().is_equal_approx(
				citizen.global_position + Vector3.UP * Citizen.SLEEPING_SELECTION_CENTRE_HEIGHT
			),
			"%s sleeping screen-selection point remains at standing chest height" % visual_variant
		)
		_check(
			is_equal_approx(
				(citizen.get("_visual") as Node3D).position.x,
				Citizen.SLEEPING_VISUAL_CENTRE_OFFSET.x
			),
			"%s sleeping body is not centred over its world position" % visual_variant
		)
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
		_check(contact_shadow.visible, "%s contact shadow did not return after waking" % visual_variant)
		_check(
			(citizen.get("_visual") as Node3D).rotation.is_equal_approx(Vector3.ZERO),
			"%s body remains horizontal immediately after waking" % visual_variant
		)
		_check(
			(citizen.get("_visual") as Node3D).position.is_equal_approx(Vector3.ZERO),
			"%s body remains offset immediately after waking" % visual_variant
		)
		_check(
			selection_shape.rotation.is_equal_approx(Vector3.ZERO),
			"%s selection capsule remains horizontal after waking" % visual_variant
		)
		_check(
			selection_shape.position.is_equal_approx(
				Vector3(0.0, Citizen.STANDING_SELECTION_CENTRE_HEIGHT, 0.0)
			),
			"%s selection capsule did not return to standing position" % visual_variant
		)
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
