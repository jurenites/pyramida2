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

	var support := SupportConstructionSite.new()
	game.add_child(support)
	support.global_position = Vector3(3.5, 0.0, 3.5)
	game.call("_select_building", support)
	game.call("_update_world_selection_outline")
	await process_frame
	var old_edge_outline := game.get("_selection_outline_root") as MultiMeshInstance3D
	var support_outlines: Array = game.get("_selection_mesh_outlines")
	var support_sources: Array = game.call("_outline_source_meshes", support)
	var visible_support_source_count := 0
	for support_source_value in support_sources:
		if (support_source_value as MeshInstance3D).is_visible_in_tree():
			visible_support_source_count += 1
	_check(not old_edge_outline.visible, "Selected Support kept the old box-edge outline")
	_check(
		support_outlines.size() == visible_support_source_count,
		"Selected Support does not have one hull outline per visible source mesh"
	)
	for outline_value in support_outlines:
		var outline := outline_value as MeshInstance3D
		_check(outline.mesh != null, "Support hull outline has no source Mesh")
		_check(
			outline.material_override is ShaderMaterial,
			"Support hull outline does not use the shared silhouette shader"
		)
		_check(
			bool(outline.get_meta("is_world_object_outline", false)),
			"Support hull is not marked against recursive outlining"
		)

	var tree := WorldItem.new()
	tree.configure("tree", 17)
	game.add_child(tree)
	await process_frame
	game.call("_set_hover_outline_target", tree, tree.global_position, false)
	var tree_outlines: Array = game.get("_hover_mesh_outlines")
	_check(tree_outlines.size() > 1, "Hovered Tree is reduced to one bounding shape")

	var citizen := Citizen.new()
	game.add_child(citizen)
	await process_frame
	game.call("_set_hover_outline_target", citizen, citizen.global_position, false)
	var citizen_outlines: Array = game.get("_hover_mesh_outlines")
	var citizen_sources := citizen.outline_source_meshes()
	_check(
		citizen_outlines.size() == citizen_sources.size(),
		"Citizen hover outline does not follow all body and clothing meshes"
	)
	for outline_value in citizen_outlines:
		var source_id := int((outline_value as MeshInstance3D).get_meta("outline_source_id", 0))
		var source_node := instance_from_id(source_id) as MeshInstance3D
		_check(
			source_node != null and not citizen.get_node("SleepBedding").is_ancestor_of(source_node),
			"Citizen hover outline includes sleep bedding"
		)
	var citizen_selection: Array[Citizen] = [citizen]
	game.call("_set_selected_citizens", citizen_selection)
	game.call("_update_world_selection_outline")
	_check(
		(game.get("_selection_mesh_outlines") as Array).is_empty(),
		"Selected Citizen retained a body outline instead of only the ground circle"
	)

	game.call("_select_ground_tile", Vector3(0.5, 0.0, 0.5))
	game.call("_update_world_selection_outline")
	_check(old_edge_outline.visible, "Ground World Unit lost its rectangular surface outline")
	_check(
		old_edge_outline.multimesh.instance_count == 4,
		"Ground World Unit outline is not its four exact surface edges"
	)

	if _failures.is_empty():
		print("PASS: mesh silhouettes follow hovered and selected object geometry")
		quit(0)
		return
	printerr("FAIL: mesh silhouette geometry (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
