extends SceneTree

const BuildingBlueprintScript = preload("res://scripts/building_blueprint.gd")
const OFFICIAL_BLUEPRINT_PATH := "res://data/buildings/four_log_support.pyrbuilding"

var _failures: Array[String] = []


func _initialize() -> void:
	_test_official_blueprint_loads()
	_test_text_round_trip_preserves_logical_parts()
	_test_one_part_per_sub_unit_contract()
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


func _test_one_part_per_sub_unit_contract() -> void:
	var blueprint := BuildingBlueprintScript.create_empty("invalid", "Invalid")
	var duplicate_part := BuildingBlueprintScript.make_sub_unit_part(
		"block", Vector3i.ZERO, "x", "limestone", 0
	)
	blueprint.parts = [duplicate_part, duplicate_part.duplicate(true)]
	_expect(
		blueprint.save_to_file("user://blueprint_contract_invalid.pyrbuilding") == ERR_INVALID_DATA,
		"Version 1 must reject two editable parts in one Sub-Unit"
	)


func _expect(condition: bool, failure_message: String) -> void:
	if not condition:
		_failures.append(failure_message)
