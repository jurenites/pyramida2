extends SceneTree

const DeterministicRandomScript = preload("res://scripts/deterministic_random.gd")
const WorldGenerationProfileScript = preload("res://scripts/world_generation_profile.gd")
const WorldStreamerScript = preload("res://scripts/world_streamer.gd")

const TEST_PROFILE_PATH := "user://world_generation_profile_test.json"

var _failures: Array[String] = []


func _initialize() -> void:
	var profile = WorldGenerationProfileScript.create_default()
	var first_chunk := WorldStreamerScript.generated_surface_entities(
		Vector2i(62, -19), profile.world_seed, profile.generator_version
	)
	var repeated_chunk := WorldStreamerScript.generated_surface_entities(
		Vector2i(62, -19), profile.world_seed, profile.generator_version
	)
	_check(first_chunk == repeated_chunk, "The same world identity produced different entities")

	var reverse_order_chunks: Dictionary = {}
	for chunk in [Vector2i(64, -19), Vector2i(63, -19), Vector2i(62, -19)]:
		reverse_order_chunks[chunk] = WorldStreamerScript.generated_surface_entities(
			chunk, profile.world_seed, profile.generator_version
		)
	_check(
		first_chunk == reverse_order_chunks[Vector2i(62, -19)],
		"Chunk generation depends on visit order"
	)

	var other_seed_chunk := WorldStreamerScript.generated_surface_entities(
		Vector2i(62, -19), profile.world_seed + 1, profile.generator_version
	)
	_check(first_chunk != other_seed_chunk, "Changing the world seed did not change generated entities")

	var adjacent_hash_deltas: Dictionary = {}
	var previous_hash := DeterministicRandomScript.world_coordinate_seed(0, 400, profile.world_seed, 7)
	for x_coordinate in range(1, 65):
		var next_hash := DeterministicRandomScript.world_coordinate_seed(
			x_coordinate, 400, profile.world_seed, 7
		)
		adjacent_hash_deltas[next_hash - previous_hash] = true
		previous_hash = next_hash
	_check(
		adjacent_hash_deltas.size() >= 60,
		"Coordinate hashing still advances in a repeating linear pattern"
	)

	var chunk_signatures: Dictionary = {}
	for chunk_x in range(50, 62):
		var entities := WorldStreamerScript.generated_surface_entities(
			Vector2i(chunk_x, 11), profile.world_seed, profile.generator_version
		)
		var local_signature: Array[String] = []
		for entity in entities:
			var world_unit: Vector2i = entity["world_unit"]
			local_signature.append("%d,%d:%s" % [
				posmod(world_unit.x, WorldStreamerScript.CHUNK_SIZE),
				posmod(world_unit.y, WorldStreamerScript.CHUNK_SIZE),
				str(entity["kind"]),
			])
		var signature := ";".join(local_signature)
		_check(not chunk_signatures.has(signature), "Adjacent chunks repeat the same plant layout")
		chunk_signatures[signature] = true

	if FileAccess.file_exists(TEST_PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PROFILE_PATH))
	var save_error: Error = profile.save_to_path(TEST_PROFILE_PATH)
	_check(save_error == OK, "World identity profile could not be written")
	var loaded_profile = WorldGenerationProfileScript.load_from_path(TEST_PROFILE_PATH)
	_check(loaded_profile != null, "Written world identity profile could not be loaded")
	if loaded_profile != null:
		_check(loaded_profile.world_seed == profile.world_seed, "Persisted world seed changed")
		_check(
			loaded_profile.generator_version == profile.generator_version,
			"Persisted generator version changed"
		)
		_check(
			loaded_profile.world_fingerprint() == profile.world_fingerprint(),
			"Persisted world fingerprint changed"
		)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PROFILE_PATH))

	if _failures.is_empty():
		print("PASS: deterministic world generation profile")
		quit(0)
		return
	print("FAIL: deterministic world generation profile (%d failures)" % _failures.size())
	for failure in _failures:
		print("- %s" % failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
