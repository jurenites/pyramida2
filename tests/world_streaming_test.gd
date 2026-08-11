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

	var loaded_chunks: Dictionary = game.get("_loaded_chunks")
	_check(not loaded_chunks.is_empty(), "Startup created no streamed chunks")
	_check(loaded_chunks.size() <= 36, "Startup allocated more than the local chunk rings")
	_check(loaded_chunks.has(Vector2i.ZERO), "Origin ground chunk is not loaded")
	var origin_root := loaded_chunks.get(Vector2i.ZERO) as Node3D
	_check(is_instance_valid(origin_root), "Origin chunk has no scene root")
	_check(origin_root.get_node_or_null("Ground") != null, "Origin chunk has no ground mesh")
	_check(origin_root.get_node_or_null("Fog") != null, "Origin chunk has no fog mesh")

	var starting_pile := game.get("_starting_pile") as PileStorage
	_check(is_instance_valid(starting_pile), "Starting Pile was not created")
	if is_instance_valid(starting_pile):
		var pile_cells := starting_pile.world_footprint_cells()
		var boundary_stones := starting_pile.find_children("PileBoundaryStone_*", "MeshInstance3D", true, false)
		_check(pile_cells.size() == 4, "Starting Pile does not occupy four World Units")
		_check(boundary_stones.size() == 4, "Pile does not have four boundary stones")
		for boundary_stone_value in boundary_stones:
			var boundary_stone := boundary_stone_value as MeshInstance3D
			var boundary_mesh := boundary_stone.mesh as SphereMesh
			_check(
				boundary_mesh != null and boundary_mesh.radius <= 0.11 and boundary_mesh.height <= 0.16,
				"Pile boundary stone is larger than the small marker size"
			)
		var occupied_cells: Dictionary = game.get("_occupied_static_world_units")
		var excavated_cells: Dictionary = game.get("_excavated_cells")
		var grass_renderer := game.get("_grass_renderer") as Node3D
		for pile_cell in pile_cells:
			_check(occupied_cells.has(pile_cell), "Pile cell is not reserved against surface resources")
			_check(not excavated_cells.has(pile_cell), "Pile was placed on excavated ground")
			for item_value in game.get("_items"):
				var item := item_value as WorldItem
				_check(
					GridNavigation.world_cell(item.global_position) != pile_cell,
					"Surface resource %s overlaps a Pile cell" % item.item_kind
				)
			_check(
				is_instance_valid(grass_renderer)
				and not grass_renderer.call("has_grass_in_world_unit", pile_cell),
				"Grass is generated inside a Pile cell"
			)

	var first_generation := WorldStreamer.generated_surface_entities(Vector2i(62, 0))
	var second_generation := WorldStreamer.generated_surface_entities(Vector2i(62, 0))
	_check(first_generation == second_generation, "Chunk generation changes between identical queries")
	var world_profile = game.get("_world_generation_profile")
	_check(world_profile != null, "World generation identity was not loaded at startup")
	if world_profile != null:
		_check(world_profile.generator_version == 2, "The active world does not use generator version 2")
		_check(not world_profile.world_fingerprint().is_empty(), "World generation identity has no fingerprint")

	var far_position := Vector3(1000.5, 0.0, 0.5)
	var far_chunk := WorldStreamer.chunk_for_world_position(far_position)
	var citizens: Array = game.get("_citizens")
	(citizens[0] as Citizen).global_position = far_position + Vector3(0.0, 150.0, 0.0)
	(citizens[1] as Citizen).global_position = far_position + Vector3(0.0, 255.0, 4.0)
	var low_citizen := Citizen.new()
	game.add_child(low_citizen)
	low_citizen.global_position = far_position + Vector3(0.0, 1.0, 8.0)
	citizens.append(low_citizen)
	game.set("_camera_focus", far_position)
	game.call("_update_world_streaming", true)
	loaded_chunks = game.get("_loaded_chunks")
	_check(loaded_chunks.has(far_chunk), "A Citizen at x=1000 did not stream its chunk")
	_check(not loaded_chunks.has(Vector2i(20, 0)), "Streaming allocated intermediate chunks between origin and x=1000")
	_check(loaded_chunks.size() <= 55, "Distant travel allocated an unbounded chunk rectangle")
	_check(game.call("_is_inside_playable_world", far_position), "Loaded distant ground is treated as outside the world")

	var distant_route: Array[Vector3] = game.call(
		"_build_navigation_route",
		far_position,
		far_position + Vector3(10.0, 0.0, 0.0),
		false
	)
	_check(not distant_route.is_empty(), "Navigation cannot route beyond the former 64x64 boundary")

	game.call("_reveal_world_around_citizens")
	var far_fog_cell := Vector2i(floori(far_position.x / 0.5), floori(far_position.z / 0.5))
	var high_fog_cell := Vector2i(floori(far_position.x / 0.5), floori((far_position.z + 4.0) / 0.5))
	var low_fog_cell := Vector2i(floori(far_position.x / 0.5), floori((far_position.z + 8.0) / 0.5))
	var revealed_fog_cells: Dictionary = game.get("_revealed_fog_cells")
	_check(revealed_fog_cells.has(far_fog_cell), "Citizen at height 150 did not reveal chunk-local fog")
	_check(revealed_fog_cells.has(high_fog_cell), "Citizen at height 255 did not reveal chunk-local fog")
	_check(revealed_fog_cells.has(low_fog_cell), "Citizen at height 1 did not reveal chunk-local fog")
	var discovered_by_chunk: Dictionary = game.get("_discovered_fog_by_chunk")
	_check(discovered_by_chunk.has(far_chunk), "Distant discovery was not partitioned by chunk")

	var streamed_items_by_chunk: Dictionary = game.get("_streamed_items_by_chunk")
	var distant_items: Array = streamed_items_by_chunk.get(far_chunk, [])
	_check(not distant_items.is_empty(), "Distant generated chunk contains no deterministic resources")
	var persistent_item := distant_items[0] as WorldItem
	var persistent_id := str(persistent_item.get_meta("stream_entity_id", ""))
	persistent_item.water_stored = 77
	persistent_item.set_meta("stream_dirty", true)
	var removed_id := ""
	if distant_items.size() > 1:
		var removed_item := distant_items[1] as WorldItem
		removed_id = str(removed_item.get_meta("stream_entity_id", ""))
		game.call("_mark_streamed_entity_removed", removed_item)
		var removed_world_unit := GridNavigation.world_cell(removed_item.global_position)
		var occupied_cells: Dictionary = game.get("_occupied_static_world_units")
		occupied_cells.erase(removed_world_unit)
		var all_items: Array = game.get("_items")
		all_items.erase(removed_item)
		removed_item.queue_free()
		await process_frame

	var origin_position := Vector3(0.5, 0.0, 0.5)
	for citizen_value in citizens:
		(citizen_value as Citizen).global_position = origin_position
	game.set("_camera_focus", origin_position)
	game.call("_update_world_streaming", true)
	loaded_chunks = game.get("_loaded_chunks")
	_check(not loaded_chunks.has(far_chunk), "Distant chunk did not unload after all active anchors left")
	var saved_states: Dictionary = game.get("_streamed_item_states")
	_check(saved_states.has(persistent_id), "Changed generated entity state was not retained on unload")
	_check(saved_states.size() == 1, "Untouched generated entities were copied into the runtime overlay")

	game.set("_camera_focus", far_position)
	game.call("_update_world_streaming", true)
	streamed_items_by_chunk = game.get("_streamed_items_by_chunk")
	var restored_item: WorldItem
	for item_value in streamed_items_by_chunk.get(far_chunk, []):
		var item := item_value as WorldItem
		if str(item.get_meta("stream_entity_id", "")) == persistent_id:
			restored_item = item
			break
	_check(is_instance_valid(restored_item), "Changed generated entity did not return after chunk reload")
	if is_instance_valid(restored_item):
		_check(restored_item.water_stored == 77, "Changed generated entity state was lost across chunk reload")
	if not removed_id.is_empty():
		for item_value in streamed_items_by_chunk.get(far_chunk, []):
			if not is_instance_valid(item_value):
				continue
			var item := item_value as WorldItem
			_check(str(item.get_meta("stream_entity_id", "")) != removed_id, "Removed generated entity respawned after chunk reload")

	var free_citizen := Citizen.new()
	root.add_child(free_citizen)
	free_citizen.global_position = Vector3(1000.5, 0.0, 10.5)
	free_citizen.assign_task(Vector3(1002.5, 0.0, 10.5), {"kind": "move"})
	free_citizen.call("_process", 0.5)
	_check(free_citizen.global_position.x > 1000.5, "Citizen motion still clamps at the former world boundary")
	free_citizen.queue_free()

	if _failures.is_empty():
		print("PASS: world streaming")
		quit(0)
		return
	print("FAIL: world streaming (%d failures)" % _failures.size())
	for failure in _failures:
		print("- %s" % failure)
	quit(1)
