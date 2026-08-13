extends SceneTree

const ObjAssetScript = preload("res://scripts/obj_asset.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var support_asset_path := "res://data/buildings/support_construction_site.obj"
	var offsets := ObjAssetScript.object_centres_xz(support_asset_path, "placement_quadrant_")
	_check(offsets.size() == 4, "Support OBJ must own exactly four placement quadrants")
	_check(
		offsets == [
			Vector2(-0.25, -0.25), Vector2(0.25, -0.25),
			Vector2(0.25, 0.25), Vector2(-0.25, 0.25),
		],
		"Support placement offsets no longer come from the approved OBJ centres"
	)
	var support_objects := ObjAssetScript.load_objects(support_asset_path)
	for branch_index in 4:
		_check(
			support_objects.has("assignment_branch_%02d" % (branch_index + 1)),
			"Support OBJ is missing assignment branch %d" % (branch_index + 1)
		)

	var prop_assets := DirAccess.get_files_at("res://data/props")
	var prop_obj_count := 0
	for file_name in prop_assets:
		if not file_name.ends_with(".obj"):
			continue
		prop_obj_count += 1
		var prop_asset_path := "res://data/props/%s" % file_name
		_check(
			not ObjAssetScript.load_objects(prop_asset_path).is_empty(),
			"Prop OBJ has no named mesh objects: %s" % prop_asset_path
		)
	_check(prop_obj_count == 72, "Expected 72 staged prop OBJ assets, found %d" % prop_obj_count)

	var support_blueprint := BuildingBlueprint.load_from_file(
		"res://data/buildings/four_log_support.pyrbuilding"
	)
	var support_instance := BuildingBlueprintInstance.new()
	support_instance.blueprint = support_blueprint
	root.add_child(support_instance)
	await process_frame
	var support_part_meshes := ObjAssetScript.load_objects(
		"res://data/buildings/four_log_support.obj"
	)
	for support_part_value in support_blueprint.parts:
		var support_part: Dictionary = support_part_value
		var part_id := str(support_part.get("id", ""))
		var rendered_part := support_instance.get_node_or_null("BlueprintParts/%s" % part_id) as MeshInstance3D
		_check(rendered_part != null, "Official Building did not render OBJ part: %s" % part_id)
		_check(
			rendered_part != null and rendered_part.mesh == support_part_meshes.get(part_id),
			"Official Building part did not use its neighboring OBJ mesh: %s" % part_id
		)
	support_instance.queue_free()
	await process_frame

	for kind in ["tree", "dead_tree", "palm_tree", "bush", "cactus", "stone", "stump", "log"]:
		var item := WorldItem.new()
		item.configure(kind, 17)
		root.add_child(item)
		await process_frame
		var asset_path := str(item.call("_prop_asset_path"))
		_check(FileAccess.file_exists(asset_path), "%s has no OBJ asset: %s" % [kind, asset_path])
		var obj_visual := item.get_node_or_null("ObjVisual") as Node3D
		_check(obj_visual != null, "%s did not instantiate an ObjVisual" % kind)
		_check(
			obj_visual != null and not obj_visual.find_children("*", "MeshInstance3D", true, false).is_empty(),
			"%s OBJ instantiated no editable mesh parts" % kind
		)
		if kind == "bush":
			var berries := item.get_node_or_null("BatchedBerryDots") as MultiMeshInstance3D
			_check(berries != null and berries.visible, "Bush OBJ berries are not visible before harvest")
			item.harvest()
			_check(berries != null and not berries.visible, "Bush OBJ berries remain visible after harvest")
		item.queue_free()
		await process_frame

	if _failures.is_empty():
		print("PASS: OBJ assets drive Support placement and physical world props")
		quit(0)
		return
	printerr("FAIL: OBJ asset runtime (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
