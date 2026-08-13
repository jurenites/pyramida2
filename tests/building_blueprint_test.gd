extends SceneTree

const BuildingBlueprintScript = preload("res://scripts/building_blueprint.gd")
const ObjExporter = preload("res://scripts/building_blueprint_obj_exporter.gd")
const OFFICIAL_BLUEPRINT_PATH := "res://data/buildings/four_log_support.pyrbuilding"
const PLATFORM_BLUEPRINT_PATH := "res://data/buildings/platform.pyrbuilding"
const SAWMILL_BLUEPRINT_PATH := "res://data/buildings/sawmill.pyrbuilding"
const PILE_BLUEPRINT_PATH := "res://data/buildings/pile.pyrbuilding"

var _failures: Array[String] = []


func _initialize() -> void:
	_test_official_blueprint_loads()
	_test_text_round_trip_preserves_logical_parts()
	_test_non_finite_geometry_is_rejected()
	_test_one_part_per_sub_unit_contract()
	_test_new_building_assets_and_export()
	if _failures.is_empty():
		print("PASS: building blueprint contracts")
		quit(0)
		return
	printerr("FAIL: building blueprint contracts (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _test_official_blueprint_loads() -> void:
	var blueprint := BuildingBlueprintScript.load_from_file(OFFICIAL_BLUEPRINT_PATH)
	_expect(blueprint.last_error.is_empty(), blueprint.last_error)
	_expect(blueprint.blueprint_id == "four_log_support", "Official blueprint ID changed")
	_expect(blueprint.parts.size() == 4, "Four Log Support must contain four logical parts")
	_expect(int(blueprint.recipe().get("log", 0)) == 4, "Recipe must derive four Logs")


func _test_text_round_trip_preserves_logical_parts() -> void:
	var source := BuildingBlueprintScript.create_empty("round_trip", "Round Trip")
	source.replace_part_at_sub_unit(
		Vector3i(1, 0, 1),
		BuildingBlueprintScript.make_sub_unit_part(
			"plank", Vector3i(1, 0, 1), "x", "wood", 2
		)
	)
	var json := JSON.new()
	_expect(json.parse(source.to_text()) == OK, "Generated blueprint text must be valid JSON")
	if not json.data is Dictionary:
		return
	var restored := BuildingBlueprintScript.new()
	_expect(restored.load_dictionary(json.data as Dictionary), restored.last_error)
	_expect(restored.parts == source.parts, "Round trip changed logical blueprint parts")
	_expect(int(restored.recipe().get("plank", 0)) == 1, "Recipe must derive one Plank")


func _test_non_finite_geometry_is_rejected() -> void:
	var source := BuildingBlueprintScript.create_empty("non_finite", "Non-finite")
	var invalid_part := BuildingBlueprintScript.make_sub_unit_part(
		"log", Vector3i.ZERO, "y", "wood", 0
	)
	invalid_part["geometry"]["start"][0] = NAN
	var source_dictionary := source.to_dictionary()
	source_dictionary["parts"] = [invalid_part]
	var restored := BuildingBlueprintScript.new()
	_expect(
		not restored.load_dictionary(source_dictionary),
		"Blueprint geometry containing NaN must be rejected"
	)


func _test_one_part_per_sub_unit_contract() -> void:
	var blueprint := BuildingBlueprintScript.create_empty("invalid", "Invalid")
	var duplicate_part := BuildingBlueprintScript.make_sub_unit_part(
		"block", Vector3i.ZERO, "x", "limestone", 0
	)
	var duplicate_with_unique_id := duplicate_part.duplicate(true)
	duplicate_with_unique_id["id"] = "second_part_in_same_sub_unit"
	blueprint.parts = [duplicate_part, duplicate_with_unique_id]
	var legacy_source := blueprint.to_dictionary()
	legacy_source["format_version"] = 1
	legacy_source.erase("recipe_mode")
	var legacy_blueprint := BuildingBlueprintScript.new()
	_expect(
		not legacy_blueprint.load_dictionary(legacy_source),
		"Version 1 must reject two editable parts in one Sub-Unit"
	)
	_expect(
		blueprint.save_to_file("/tmp/pyramida_blueprint_contract_v2_multi_part.pyrbuilding") == OK,
		"Version 2 must allow several logical parts to share one Sub-Unit: %s" % blueprint.last_error
	)


func _test_new_building_assets_and_export() -> void:
	var platform := BuildingBlueprintScript.load_from_file(PLATFORM_BLUEPRINT_PATH)
	_expect(platform.last_error.is_empty(), platform.last_error)
	_expect(platform.recipe() == {"log": 4, "plank": 4}, "Platform asset recipe is not four Logs and four Planks")
	var sawmill := BuildingBlueprintScript.load_from_file(SAWMILL_BLUEPRINT_PATH)
	_expect(sawmill.last_error.is_empty(), sawmill.last_error)
	_expect(sawmill.recipe() == {"log": 10}, "Sawmill asset recipe is not ten Logs")
	_expect(
		not sawmill.workshop_recipes.is_empty()
		and sawmill.workshop_recipes[0].get("input") == {"log": 1}
		and sawmill.workshop_recipes[0].get("output") == {"plank": 1}
		and is_equal_approx(float(sawmill.workshop_recipes[0].get("work_seconds", 0.0)), 3.0),
		"Sawmill asset does not encode the three-second Log-to-Plank process"
	)
	var pile := BuildingBlueprintScript.load_from_file(PILE_BLUEPRINT_PATH)
	_expect(pile.last_error.is_empty(), pile.last_error)
	_expect(pile.bounds_world_units == Vector3i(2, 1, 2), "Pile asset does not occupy its 2x2 footprint")
	_expect(pile.recipe().is_empty(), "Pile asset is not free")
	var export_path := "/tmp/pyramida_building_assets/platform.obj"
	_expect(ObjExporter.export_to_file(platform, export_path) == OK, "Platform OBJ export failed")
	var exported_obj := FileAccess.get_file_as_string(export_path)
	_expect(exported_obj.contains("o post_sw"), "OBJ export lost the Platform Log objects")
	_expect(exported_obj.contains("o deck_4"), "OBJ export lost the Platform Plank objects")
	_expect(exported_obj.contains("mtllib platform.mtl"), "OBJ export has no Blender material library")
	_expect(
		FileAccess.get_file_as_string(export_path.get_basename() + ".mtl").contains("newmtl wood"),
		"Platform material export lost its Wood material"
	)


func _expect(condition: bool, failure_message: String) -> void:
	if not condition:
		_failures.append(failure_message)
