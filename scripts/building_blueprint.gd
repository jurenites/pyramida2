class_name BuildingBlueprint
extends RefCounted

const MaterialCatalog = preload("res://scripts/building_material_catalog.gd")

const FORMAT_ID := "pyramida-building"
const FORMAT_VERSION := 2
const SUPPORTED_FORMAT_VERSIONS: Array[int] = [1, 2]
const FILE_EXTENSION := "pyrbuilding"
const SUPPORTED_PART_KINDS: Array[String] = ["block", "log", "plank"]
const SUPPORTED_ORIENTATIONS: Array[String] = ["x", "y", "z"]
const SUPPORTED_PRIMITIVES: Array[String] = ["box", "log", "sphere"]

var blueprint_id := "developer_world_unit"
var display_name := "Developer World Unit"
var source_format_version := FORMAT_VERSION
var bounds_world_units := Vector3i.ONE
var parts: Array[Dictionary] = []
var recipe_mode := "derived"
var explicit_recipe: Dictionary = {}
var workshop_recipes: Array[Dictionary] = []
var last_error := ""


static func create_empty(
	new_blueprint_id := "developer_world_unit",
	new_display_name := "Developer World Unit"
) -> BuildingBlueprint:
	var blueprint := BuildingBlueprint.new()
	blueprint.blueprint_id = _safe_identifier(new_blueprint_id)
	blueprint.display_name = new_display_name.strip_edges()
	return blueprint


func duplicate_blueprint() -> BuildingBlueprint:
	var duplicate_value := BuildingBlueprint.new()
	duplicate_value.blueprint_id = blueprint_id
	duplicate_value.display_name = display_name
	duplicate_value.source_format_version = source_format_version
	duplicate_value.bounds_world_units = bounds_world_units
	duplicate_value.parts = parts.duplicate(true)
	duplicate_value.recipe_mode = recipe_mode
	duplicate_value.explicit_recipe = explicit_recipe.duplicate(true)
	duplicate_value.workshop_recipes = workshop_recipes.duplicate(true)
	return duplicate_value


func to_dictionary() -> Dictionary:
	var result := {
		"format": FORMAT_ID,
		"format_version": FORMAT_VERSION,
		"id": blueprint_id,
		"display_name": display_name,
		"bounds_world_units": _vector3i_to_array(bounds_world_units),
		"parts": parts.duplicate(true),
	}
	result["recipe_mode"] = recipe_mode
	if recipe_mode == "explicit":
		result["recipe"] = explicit_recipe.duplicate(true)
	if not workshop_recipes.is_empty():
		result["workshop_recipes"] = workshop_recipes.duplicate(true)
	return result


func to_text() -> String:
	return JSON.stringify(to_dictionary(), "\t", true, true) + "\n"


func load_dictionary(source: Dictionary) -> bool:
	last_error = _validate_dictionary(source)
	if not last_error.is_empty():
		return false
	blueprint_id = _safe_identifier(str(source.get("id", "building")))
	display_name = str(source.get("display_name", blueprint_id)).strip_edges()
	bounds_world_units = _array_to_vector3i(source.get("bounds_world_units", [1, 1, 1]))
	var source_version := int(source.get("format_version", 1))
	source_format_version = source_version
	recipe_mode = str(source.get("recipe_mode", "derived")) if source_version >= 2 else "derived"
	explicit_recipe = _canonical_resource_counts(source.get("recipe", {}))
	workshop_recipes.clear()
	for workshop_recipe_value in source.get("workshop_recipes", []):
		workshop_recipes.append(_canonical_workshop_recipe(workshop_recipe_value as Dictionary))
	parts.clear()
	for source_part in source.get("parts", []):
		parts.append(_canonical_part(source_part as Dictionary))
	return true


func save_to_file(file_path: String) -> Error:
	last_error = ""
	var validation_error := _validate_dictionary(to_dictionary())
	if not validation_error.is_empty():
		last_error = validation_error
		return ERR_INVALID_DATA
	var absolute_path := ProjectSettings.globalize_path(file_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		last_error = "Unable to create blueprint directory: %s" % error_string(directory_error)
		return directory_error
	var blueprint_file := FileAccess.open(file_path, FileAccess.WRITE)
	if blueprint_file == null:
		var open_error := FileAccess.get_open_error()
		last_error = "Unable to save blueprint: %s" % error_string(open_error)
		return open_error
	blueprint_file.store_string(to_text())
	return OK


static func load_from_file(file_path: String) -> BuildingBlueprint:
	var blueprint_file := FileAccess.open(file_path, FileAccess.READ)
	if blueprint_file == null:
		var unreadable := BuildingBlueprint.new()
		unreadable.last_error = "Unable to open blueprint: %s" % error_string(FileAccess.get_open_error())
		return unreadable
	var json := JSON.new()
	var parse_error := json.parse(blueprint_file.get_as_text())
	if parse_error != OK or not json.data is Dictionary:
		var invalid_json := BuildingBlueprint.new()
		invalid_json.last_error = "Invalid blueprint JSON at line %d: %s" % [
			json.get_error_line(),
			json.get_error_message(),
		]
		return invalid_json
	var loaded_blueprint := BuildingBlueprint.new()
	loaded_blueprint.load_dictionary(json.data as Dictionary)
	return loaded_blueprint


func part_at_sub_unit(sub_unit: Vector3i) -> Dictionary:
	for blueprint_part in parts:
		if _array_to_vector3i(blueprint_part.get("sub_unit", [-1, -1, -1])) == sub_unit:
			return blueprint_part
	return {}


func replace_part_at_sub_unit(sub_unit: Vector3i, blueprint_part: Dictionary) -> void:
	remove_part_at_sub_unit(sub_unit)
	parts.append(blueprint_part.duplicate(true))


func remove_part_at_sub_unit(sub_unit: Vector3i) -> bool:
	for part_index in range(parts.size() - 1, -1, -1):
		if _array_to_vector3i(parts[part_index].get("sub_unit", [-1, -1, -1])) == sub_unit:
			parts.remove_at(part_index)
			return true
	return false


func clear_parts() -> void:
	parts.clear()


func recipe() -> Dictionary:
	if recipe_mode == "explicit":
		return explicit_recipe.duplicate(true)
	var required_resources := {}
	for blueprint_part in parts:
		if bool(blueprint_part.get("decorative", false)):
			continue
		var resource_id := MaterialCatalog.resource_for_part(
			str(blueprint_part.get("kind", "")),
			str(blueprint_part.get("material", ""))
		)
		required_resources[resource_id] = int(required_resources.get(resource_id, 0)) + 1
	return required_resources


static func make_sub_unit_part(
	part_kind: String,
	sub_unit: Vector3i,
	orientation: String,
	material_id: String,
	visual_variant: int
) -> Dictionary:
	var centre := Vector3(
		-0.25 + 0.5 * float(sub_unit.x),
		0.25 + 0.5 * float(sub_unit.y),
		-0.25 + 0.5 * float(sub_unit.z)
	)
	var geometry := {}
	match part_kind:
		"log":
			var axis := _orientation_axis(orientation)
			geometry = {
				"start": _vector3_to_array(centre - axis * 0.22),
				"end": _vector3_to_array(centre + axis * 0.22),
				"start_radius": 0.085,
				"end_radius": 0.075,
				"sides": 6,
			}
		"plank":
			var plank_size := Vector3(0.46, 0.10, 0.36)
			if orientation == "y":
				plank_size = Vector3(0.10, 0.46, 0.36)
			elif orientation == "z":
				plank_size = Vector3(0.36, 0.10, 0.46)
			geometry = {
				"centre": _vector3_to_array(centre),
				"size": _vector3_to_array(plank_size),
				"rotation_degrees": [0.0, 0.0, 0.0],
			}
		_:
			geometry = {
				"centre": _vector3_to_array(centre),
				"size": [0.46, 0.46, 0.46],
				"rotation_degrees": [0.0, 0.0, 0.0],
			}
	return {
		"id": "part_%s_%s_%s_%s" % [sub_unit.x, sub_unit.y, sub_unit.z, part_kind],
		"kind": part_kind,
		"material": material_id,
		"resource": MaterialCatalog.resource_for_part(part_kind, material_id),
		"sub_unit": _vector3i_to_array(sub_unit),
		"orientation": orientation,
		"visual_variant": posmod(visual_variant, 3),
		"decorative": false,
		"geometry": geometry,
	}


static func vector3_from_value(value: Variant, fallback := Vector3.ZERO) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback


static func _validate_dictionary(source: Dictionary) -> String:
	if str(source.get("format", "")) != FORMAT_ID:
		return "Unsupported blueprint format"
	var source_version := int(source.get("format_version", 0))
	if source_version not in SUPPORTED_FORMAT_VERSIONS:
		return "Unsupported blueprint format version"
	var source_id := str(source.get("id", "")).strip_edges()
	if source_id.is_empty() or source_id != _safe_identifier(source_id):
		return "Blueprint ID must use lowercase letters numbers underscores or hyphens"
	var source_bounds := _array_to_vector3i(source.get("bounds_world_units", []))
	if source_bounds.x <= 0 or source_bounds.y <= 0 or source_bounds.z <= 0:
		return "Blueprint bounds must contain positive World Unit dimensions"
	if source_version == 1 and source_bounds != Vector3i.ONE:
		return "Version 1 supports exactly one World Unit"
	var source_parts: Variant = source.get("parts", [])
	if not source_parts is Array:
		return "Blueprint parts must be an array"
	var used_ids := {}
	var used_sub_units := {}
	for part_value in source_parts:
		if not part_value is Dictionary:
			return "Every blueprint part must be an object"
		var blueprint_part := part_value as Dictionary
		var part_id := str(blueprint_part.get("id", "")).strip_edges()
		if part_id.is_empty() or used_ids.has(part_id):
			return "Blueprint part IDs must be present and unique"
		used_ids[part_id] = true
		var part_kind := str(blueprint_part.get("kind", ""))
		if not SUPPORTED_PART_KINDS.has(part_kind):
			return "Unsupported blueprint part kind: %s" % part_kind
		var material_id := str(blueprint_part.get("material", ""))
		if not MaterialCatalog.MATERIAL_IDS.has(material_id):
			return "Unsupported building material: %s" % material_id
		var orientation := str(blueprint_part.get("orientation", ""))
		if not SUPPORTED_ORIENTATIONS.has(orientation):
			return "Unsupported part orientation: %s" % orientation
		var visual_variant := int(blueprint_part.get("visual_variant", -1))
		if visual_variant < 0 or visual_variant > 2:
			return "Visual variant must be 0 1 or 2"
		var sub_unit := _array_to_vector3i(blueprint_part.get("sub_unit", []))
		if not _is_valid_sub_unit(sub_unit, source_bounds):
			return "Part lies outside the editable World Unit"
		var sub_unit_key := "%d,%d,%d" % [sub_unit.x, sub_unit.y, sub_unit.z]
		if source_version == 1 and used_sub_units.has(sub_unit_key):
			return "Version 1 permits one editable part per Sub-Unit"
		used_sub_units[sub_unit_key] = true
		var decorative := bool(blueprint_part.get("decorative", false))
		var expected_resource := MaterialCatalog.resource_for_part(part_kind, material_id)
		if decorative:
			if not str(blueprint_part.get("resource", "")).is_empty():
				return "Decorative parts cannot consume a construction resource"
		elif str(blueprint_part.get("resource", "")) != expected_resource:
			return "Part resource does not match its kind and material"
		var geometry_value: Variant = blueprint_part.get("geometry", {})
		if not geometry_value is Dictionary:
			return "Blueprint part geometry must be an object"
		var geometry := geometry_value as Dictionary
		var default_primitive := "log" if part_kind == "log" else "box"
		if str(geometry.get("primitive", default_primitive)) not in SUPPORTED_PRIMITIVES:
			return "Unsupported geometry primitive"
	if source_version >= 2:
		var source_recipe_mode := str(source.get("recipe_mode", "derived"))
		if source_recipe_mode not in ["derived", "explicit"]:
			return "Recipe mode must be derived or explicit"
		if source_recipe_mode == "explicit" and not source.get("recipe", {}) is Dictionary:
			return "Explicit recipe must be an object"
		var workshop_value: Variant = source.get("workshop_recipes", [])
		if not workshop_value is Array:
			return "Workshop recipes must be an array"
		for workshop_recipe_value in workshop_value:
			if not workshop_recipe_value is Dictionary:
				return "Every workshop recipe must be an object"
			var workshop_recipe := workshop_recipe_value as Dictionary
			if (
				not workshop_recipe.get("input", {}) is Dictionary
				or not workshop_recipe.get("output", {}) is Dictionary
				or float(workshop_recipe.get("work_seconds", 0.0)) <= 0.0
			):
				return "Workshop recipes require input output and positive work_seconds"
	return ""


static func _canonical_part(source_part: Dictionary) -> Dictionary:
	var result := source_part.duplicate(true)
	result["sub_unit"] = _vector3i_to_array(_array_to_vector3i(source_part.get("sub_unit", [])))
	result["visual_variant"] = int(source_part.get("visual_variant", 0))
	result["decorative"] = bool(source_part.get("decorative", false))
	var geometry: Dictionary = (source_part.get("geometry", {}) as Dictionary).duplicate(true)
	for vector_key in ["start", "end", "centre", "size", "rotation_degrees", "scale"]:
		if geometry.get(vector_key) is Array and geometry[vector_key].size() == 3:
			geometry[vector_key] = _vector3_to_array(vector3_from_value(geometry[vector_key]))
	for float_key in ["start_radius", "end_radius", "radius", "height"]:
		if geometry.has(float_key):
			geometry[float_key] = float(geometry[float_key])
	if geometry.has("sides"):
		geometry["sides"] = int(geometry["sides"])
	result["geometry"] = geometry
	return result


static func _canonical_resource_counts(value: Variant) -> Dictionary:
	var result := {}
	if not value is Dictionary:
		return result
	for resource_kind_value in value:
		result[str(resource_kind_value)] = int(value[resource_kind_value])
	return result


static func _canonical_workshop_recipe(source: Dictionary) -> Dictionary:
	return {
		"id": str(source.get("id", "process")),
		"input": _canonical_resource_counts(source.get("input", {})),
		"output": _canonical_resource_counts(source.get("output", {})),
		"work_seconds": float(source.get("work_seconds", 0.0)),
	}


static func _orientation_axis(orientation: String) -> Vector3:
	match orientation:
		"y":
			return Vector3.UP
		"z":
			return Vector3.FORWARD
		_:
			return Vector3.RIGHT


static func _is_valid_sub_unit(sub_unit: Vector3i, bounds := Vector3i.ONE) -> bool:
	return (
		sub_unit.x >= 0 and sub_unit.x < bounds.x * 2
		and sub_unit.y >= 0 and sub_unit.y < bounds.y * 2
		and sub_unit.z >= 0 and sub_unit.z < bounds.z * 2
	)


static func _safe_identifier(source_id: String) -> String:
	var normalised := source_id.strip_edges().to_lower().replace(" ", "_")
	var valid_character := RegEx.create_from_string("[^a-z0-9_-]")
	normalised = valid_character.sub(normalised, "", true)
	return normalised if not normalised.is_empty() else "building"


static func _vector3_to_array(vector_value: Vector3) -> Array:
	return [vector_value.x, vector_value.y, vector_value.z]


static func _vector3i_to_array(vector_value: Vector3i) -> Array:
	return [vector_value.x, vector_value.y, vector_value.z]


static func _array_to_vector3i(value: Variant) -> Vector3i:
	if value is Array and value.size() == 3:
		return Vector3i(int(value[0]), int(value[1]), int(value[2]))
	return Vector3i(-1, -1, -1)
