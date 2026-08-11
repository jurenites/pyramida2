class_name WorldGenerationProfile
extends RefCounted

const PROFILE_FORMAT_VERSION := 1
const CURRENT_GENERATOR_VERSION := 2
const CURRENT_ALGORITHM := "sha256-habitat-v2"
const DEFAULT_WORLD_SEED := 824633
const DEFAULT_CHUNK_SIZE := 16

var world_seed := DEFAULT_WORLD_SEED
var generator_version := CURRENT_GENERATOR_VERSION
var generator_algorithm := CURRENT_ALGORITHM
var chunk_size := DEFAULT_CHUNK_SIZE


static func create_default() -> WorldGenerationProfile:
	return WorldGenerationProfile.new()


static func from_dictionary(data: Dictionary) -> WorldGenerationProfile:
	var profile := WorldGenerationProfile.new()
	profile.world_seed = int(data.get("world_seed", DEFAULT_WORLD_SEED))
	profile.generator_version = int(data.get("generator_version", CURRENT_GENERATOR_VERSION))
	profile.generator_algorithm = str(data.get("generator_algorithm", CURRENT_ALGORITHM))
	profile.chunk_size = int(data.get("chunk_size", DEFAULT_CHUNK_SIZE))
	return profile


static func load_from_path(path: String) -> WorldGenerationProfile:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return null
	var data := parsed as Dictionary
	var profile := from_dictionary(data)
	if not profile.is_supported():
		return null
	if str(data.get("world_fingerprint", "")) != profile.world_fingerprint():
		return null
	return profile


func is_supported() -> bool:
	return (
		generator_version == CURRENT_GENERATOR_VERSION
		and generator_algorithm == CURRENT_ALGORITHM
		and chunk_size == DEFAULT_CHUNK_SIZE
	)


func identity_dictionary() -> Dictionary:
	return {
		"profile_format_version": PROFILE_FORMAT_VERSION,
		"world_seed": world_seed,
		"generator_version": generator_version,
		"generator_algorithm": generator_algorithm,
		"chunk_size": chunk_size,
	}


func world_fingerprint() -> String:
	var identity := "%d|%d|%s|%d" % [
		world_seed,
		generator_version,
		generator_algorithm,
		chunk_size,
	]
	return identity.sha256_text().substr(0, 16)


func save_to_path(path: String) -> Error:
	var record := identity_dictionary()
	record["world_fingerprint"] = world_fingerprint()
	var temporary_path := "%s.tmp" % path
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(record, "\t") + "\n")
	file.flush()
	file.close()
	var absolute_temporary_path := ProjectSettings.globalize_path(temporary_path)
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			return remove_error
	return DirAccess.rename_absolute(absolute_temporary_path, absolute_path)
