class_name WorldStreamer
extends RefCounted

const DeterministicRandomScript = preload("res://scripts/deterministic_random.gd")
const WorldGenerationProfileScript = preload("res://scripts/world_generation_profile.gd")

const CHUNK_SIZE := 16
const PRESENTATION_RADIUS_CHUNKS := 2
const GENERATOR_VERSION := WorldGenerationProfileScript.CURRENT_GENERATOR_VERSION
const WORLD_SEED := WorldGenerationProfileScript.DEFAULT_WORLD_SEED
const ORIGIN_FIXTURE_HALF_EXTENT := 32


static func chunk_for_world_position(world_position: Vector3) -> Vector2i:
	return chunk_for_world_unit(Vector2i(floori(world_position.x), floori(world_position.z)))


static func chunk_for_world_unit(world_unit: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(world_unit.x) / float(CHUNK_SIZE)),
		floori(float(world_unit.y) / float(CHUNK_SIZE))
	)


static func chunk_origin(chunk_coordinate: Vector2i) -> Vector2i:
	return chunk_coordinate * CHUNK_SIZE


static func chunk_world_bounds(chunk_coordinate: Vector2i) -> Rect2i:
	return Rect2i(chunk_origin(chunk_coordinate), Vector2i(CHUNK_SIZE, CHUNK_SIZE))


static func required_chunks(anchor_positions: Array[Vector3], radius_chunks: int) -> Dictionary:
	var required: Dictionary = {}
	for anchor_position in anchor_positions:
		var anchor_chunk := chunk_for_world_position(anchor_position)
		for offset_x in range(-radius_chunks, radius_chunks + 1):
			for offset_z in range(-radius_chunks, radius_chunks + 1):
				required[anchor_chunk + Vector2i(offset_x, offset_z)] = true
	return required


static func is_origin_fixture_chunk(chunk_coordinate: Vector2i) -> bool:
	var bounds := chunk_world_bounds(chunk_coordinate)
	return (
		bounds.position.x >= -ORIGIN_FIXTURE_HALF_EXTENT
		and bounds.position.y >= -ORIGIN_FIXTURE_HALF_EXTENT
		and bounds.end.x <= ORIGIN_FIXTURE_HALF_EXTENT
		and bounds.end.y <= ORIGIN_FIXTURE_HALF_EXTENT
	)


static func generated_surface_entities(
	chunk_coordinate: Vector2i,
	world_seed := WORLD_SEED,
	generator_version := GENERATOR_VERSION
) -> Array[Dictionary]:
	var entities: Array[Dictionary] = []
	if is_origin_fixture_chunk(chunk_coordinate):
		return entities
	var origin := chunk_origin(chunk_coordinate)
	for local_x in CHUNK_SIZE:
		for local_z in CHUNK_SIZE:
			var world_unit := origin + Vector2i(local_x, local_z)
			var moisture := DeterministicRandomScript.habitat_noise(
				world_unit.x, world_unit.y, world_seed, generator_version * 101 + 1, 13
			)
			var fertility := DeterministicRandomScript.habitat_noise(
				world_unit.x, world_unit.y, world_seed, generator_version * 101 + 2, 29
			)
			var distribution_roll := DeterministicRandomScript.world_fraction(
				world_unit.x, world_unit.y, world_seed, generator_version * 101 + 3
			)
			var tree_density := 0.012 + moisture * fertility * 0.042
			var dead_tree_density := 0.003 + (1.0 - moisture) * 0.006
			var bush_density := 0.004 + moisture * 0.014
			var stone_density := 0.008
			var cactus_density := 0.002 + (1.0 - moisture) * 0.012
			var palm_density := 0.002 + moisture * (1.0 - fertility) * 0.006
			var item_kind := _kind_for_distribution_roll(distribution_roll, [
				["tree", tree_density],
				["dead_tree", dead_tree_density],
				["bush", bush_density],
				["stone", stone_density],
				["cactus", cactus_density],
				["palm_tree", palm_density],
			])
			if item_kind.is_empty():
				continue
			var detail_seed := DeterministicRandomScript.world_coordinate_seed(
				world_unit.x,
				world_unit.y,
				world_seed,
				generator_version * 101 + 4
			)
			entities.append({
				"id": "g%d:%d:%d:%s" % [generator_version, world_unit.x, world_unit.y, item_kind],
				"kind": item_kind,
				"world_unit": world_unit,
				"detail_seed": detail_seed,
			})
	return entities


static func _kind_for_distribution_roll(distribution_roll: float, weighted_kinds: Array) -> String:
	var threshold := 0.0
	for weighted_kind_value in weighted_kinds:
		var weighted_kind := weighted_kind_value as Array
		threshold += float(weighted_kind[1])
		if distribution_roll < threshold:
			return str(weighted_kind[0])
	return ""
