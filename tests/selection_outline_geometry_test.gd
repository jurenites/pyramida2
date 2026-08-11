extends SceneTree

const BuildingBlueprintScript = preload("res://scripts/building_blueprint.gd")
const BlueprintInstanceScript = preload("res://scripts/building_blueprint_instance.gd")
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

	var support := SupportConstructionSite.new()
	game.add_child(support)
	support.global_position = Vector3(3.5, 0.0, 3.5)
	game.call("_select_building", support)
	game.call("_update_world_selection_outline")
	await process_frame
	var outline := game.get("_selection_outline_root") as MultiMeshInstance3D
	_check(outline.multimesh.instance_count == 12, "Support does not use all twelve exact cube edges")
	var support_box := support.selection_outline_local_boxes()[0]
	var line_width := 0.04
	var original_transforms: Array[Transform3D] = game.call(
		"_contained_box_edge_transforms",
		support_box,
		support.global_transform,
		line_width,
		true
	)
	_check(
		_outline_is_inside_local_box(
			original_transforms,
			support.global_transform,
			support_box,
			line_width
		),
		"Support outline extends outside its occupied World Unit shape"
	)
	var original_local_origins := _outline_local_origins(original_transforms, support.global_transform)
	support.rotation.y = PI * 0.25
	var rotated_transforms: Array[Transform3D] = game.call(
		"_contained_box_edge_transforms",
		support_box,
		support.global_transform,
		line_width,
		true
	)
	var rotated_local_origins := _outline_local_origins(rotated_transforms, support.global_transform)
	_check(
		_vector_arrays_are_equal(original_local_origins, rotated_local_origins),
		"Support outline changes size or shape when the Building rotates"
	)

	var pile := PileStorage.new()
	pile.configure_footprint(PileStorage.DEFAULT_FOOTPRINT)
	_check(
		pile.selection_outline_local_boxes().size() == 4,
		"Pile outline does not preserve its four occupied World Units"
	)

	var blueprint := BuildingBlueprintScript.create_empty("outline_test", "Outline Test")
	blueprint.parts.append(BuildingBlueprintScript.make_sub_unit_part(
		"block", Vector3i(1, 0, 0), "x", "limestone", 0
	))
	var blueprint_instance := BlueprintInstanceScript.new() as BuildingBlueprintInstance
	blueprint_instance.blueprint = blueprint
	var sub_unit_boxes := blueprint_instance.selection_outline_local_boxes()
	_check(sub_unit_boxes.size() == 1, "Blueprint part has no occupied Sub-Unit outline box")
	if sub_unit_boxes.size() == 1:
		_check(
			sub_unit_boxes[0].size.is_equal_approx(Vector3.ONE * 0.5),
			"Blueprint part outline is not exactly one half-size Sub-Unit"
		)
		var sub_unit_transforms: Array[Transform3D] = game.call(
			"_contained_box_edge_transforms",
			sub_unit_boxes[0],
			Transform3D.IDENTITY,
			line_width,
			true
		)
		_check(
			_outline_is_inside_local_box(
				sub_unit_transforms,
				Transform3D.IDENTITY,
				sub_unit_boxes[0],
				line_width
			),
			"White edge prisms overhang a half-size Sub-Unit"
		)

	if _failures.is_empty():
		print("PASS: Selection outlines stay inside exact rotated occupancy boxes")
		quit(0)
		return
	printerr("FAIL: Selection outline geometry (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _outline_local_origins(
	transforms: Array[Transform3D],
	object_transform: Transform3D
) -> Array[Vector3]:
	var origins: Array[Vector3] = []
	var to_local := object_transform.affine_inverse()
	for edge_transform in transforms:
		origins.append(to_local * edge_transform.origin)
	return origins


func _vector_arrays_are_equal(first: Array[Vector3], second: Array[Vector3]) -> bool:
	if first.size() != second.size():
		return false
	for value_index in first.size():
		if not first[value_index].is_equal_approx(second[value_index]):
			return false
	return true


func _outline_is_inside_local_box(
	transforms: Array[Transform3D],
	object_transform: Transform3D,
	occupied_box: AABB,
	line_width: float
) -> bool:
	var to_local := object_transform.affine_inverse()
	for edge_transform in transforms:
		for x_side in 2:
			for y_side in 2:
				for z_side in 2:
					var mesh_corner := Vector3(
						-line_width * 0.5 if x_side == 0 else line_width * 0.5,
						-line_width * 0.5 if y_side == 0 else line_width * 0.5,
						-0.5 if z_side == 0 else 0.5
					)
					var local_corner := to_local * (edge_transform * mesh_corner)
					if not occupied_box.grow(0.0001).has_point(local_corner):
						return false
	return true
