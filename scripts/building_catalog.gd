class_name BuildingCatalog
extends RefCounted

const GameplaySettingsScript = preload("res://scripts/gameplay_settings.gd")

const CATEGORY_STRUCTURE := "structure"
const CATEGORY_PATH := "path"
const CATEGORY_STORAGE := "storage"
const CATEGORY_LIVABLE := "livable"

const CATEGORY_ORDER: Array[String] = [
	CATEGORY_PATH,
	CATEGORY_STORAGE,
	CATEGORY_LIVABLE,
	CATEGORY_STRUCTURE,
]

const CATEGORY_LABEL_KEYS := {
	CATEGORY_STRUCTURE: "structure_category_text",
	CATEGORY_PATH: "path_category_text",
	CATEGORY_STORAGE: "storage_category_text",
	CATEGORY_LIVABLE: "livable_category_text",
}

const ENTRIES := {
	CATEGORY_STRUCTURE: [
		{
			"id": "support",
			"label_key": "support_name_text",
			"icon": "support_preview",
			"footprint": Vector3i(1, 1, 1),
			"asset_path": "res://data/buildings/four_log_support.pyrbuilding",
			"implemented": true,
		},
		{
			"id": "platform",
			"label_key": "platform_name_text",
			"icon": "platform",
			"footprint": Vector3i(1, 1, 1),
			"asset_path": "res://data/buildings/platform.pyrbuilding",
			"implemented": true,
		},
		{
			"id": "sawmill",
			"label_key": "sawmill_name_text",
			"icon": "sawmill",
			"footprint": Vector3i(1, 1, 1),
			"asset_path": "res://data/buildings/sawmill.pyrbuilding",
			"entry_points": 4,
			"implemented": true,
		},
	],
	CATEGORY_PATH: [
		{
			"id": "road",
			"label_key": "road_name_text",
			"icon": "road",
			"footprint": Vector3i(1, 1, 1),
			"upgrade_when_above": "support",
			"upgrade_result": "support_platform",
			"implemented": false,
		},
		{
			"id": "rope_bridge",
			"label_key": "rope_bridge_name_text",
			"icon": "rope_bridge",
			"minimum_footprint": Vector3i(2, 1, 1),
			"drag_axis": "cardinal",
			"maximum_center_height_offset": -0.5,
			"implemented": false,
		},
		{
			"id": "suspension_bridge",
			"label_key": "suspension_bridge_name_text",
			"icon": "suspension_bridge",
			"minimum_footprint": Vector3i(2, 1, 1),
			"drag_axis": "cardinal",
			"maximum_center_height_offset": 0.125,
			"implemented": false,
		},
		{
			"id": "tunnel",
			"label_key": "tunnel_name_text",
			"icon": "tunnel",
			"minimum_footprint": Vector3i(2, 1, 1),
			"drag_axis": "cardinal",
			"sequence": ["remove_solid", "preserve_void", "install_support", "install_path"],
			"implemented": false,
		},
	],
	CATEGORY_STORAGE: [
		{
			"id": "pile",
			"label_key": "pile_name_text",
			"icon": "pile_building",
			"footprint": Vector3i(2, 1, 2),
			"asset_path": "res://data/buildings/pile.pyrbuilding",
			"resizable_connected_footprint": true,
			"implemented": true,
		},
		{
			"id": "warehouse",
			"label_key": "warehouse_name_text",
			"icon": "warehouse",
			"footprint": Vector3i(1, 1, 1),
			"door_count": 1,
			"citizen_navigation": {"door": "passable", "walls": "hard_block"},
			"merge_on_facing_door": true,
			"implemented": false,
		},
	],
	CATEGORY_LIVABLE: [
		{
			"id": "small_livable",
			"label_key": "small_livable_name_text",
			"icon": "small_livable",
			"footprint": Vector3i(1, 1, 1),
			"door_count": 1,
			"merge_on_facing_door": true,
			"implemented": false,
		},
	],
}


static func entries_for(category_id: String) -> Array:
	var result := (ENTRIES.get(category_id, []) as Array).duplicate(true)
	for definition_value in result:
		_hydrate_gameplay_settings(definition_value as Dictionary)
	return result


static func category_label_key(category_id: String) -> String:
	return str(CATEGORY_LABEL_KEYS.get(category_id, ""))


static func entry(building_id: String) -> Dictionary:
	for category_id in CATEGORY_ORDER:
		for entry_value in entries_for(category_id):
			var definition := entry_value as Dictionary
			if str(definition.get("id", "")) == building_id:
				return definition
	return {}


static func citizen_face_blocks(building_id: String, face_kind: String) -> bool:
	var definition := entry(building_id)
	var navigation := definition.get("citizen_navigation", {}) as Dictionary
	return str(navigation.get(face_kind, "hard_block")) == "hard_block"


static func _hydrate_gameplay_settings(definition: Dictionary) -> void:
	var building_id := str(definition.get("id", ""))
	definition["recipe"] = GameplaySettingsScript.construction_recipe(building_id)
	if building_id == "road":
		definition["travel_cost"] = GameplaySettingsScript.ROAD_TRAVEL_COST
	if building_id == "small_livable":
		definition["standalone_roof_recipe"] = GameplaySettingsScript.SMALL_LIVABLE_STANDALONE_ROOF_RECIPE.duplicate(true)
	if building_id == "sawmill":
		definition["workshop_recipes"] = [{
			"id": "saw_plank",
			"input": GameplaySettingsScript.SAWMILL_PLANK_INPUT.duplicate(true),
			"output": GameplaySettingsScript.SAWMILL_PLANK_OUTPUT.duplicate(true),
			"work_seconds": GameplaySettingsScript.SAWMILL_PLANK_LABOUR_SECONDS,
		}]
