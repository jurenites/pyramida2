class_name BuildingCatalog
extends RefCounted

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
			"recipe": {"log": 4},
			"implemented": true,
		},
	],
	CATEGORY_PATH: [
		{
			"id": "road",
			"label_key": "road_name_text",
			"icon": "road",
			"footprint": Vector3i(1, 1, 1),
			"recipe": {"plank": 4},
			"travel_cost": 1.0,
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
			"recipe": {},
			"resizable_connected_footprint": true,
			"implemented": false,
		},
		{
			"id": "warehouse",
			"label_key": "warehouse_name_text",
			"icon": "warehouse",
			"footprint": Vector3i(1, 1, 1),
			"recipe": {"log": 4, "plank": 4},
			"door_count": 1,
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
			"recipe": {"log": 4, "plank": 8},
			"standalone_roof_recipe": {"log": 4, "hay": 4},
			"door_count": 1,
			"merge_on_facing_door": true,
			"implemented": false,
		},
	],
}


static func entries_for(category_id: String) -> Array:
	return (ENTRIES.get(category_id, []) as Array).duplicate(true)


static func category_label_key(category_id: String) -> String:
	return str(CATEGORY_LABEL_KEYS.get(category_id, ""))


static func entry(building_id: String) -> Dictionary:
	for category_id in CATEGORY_ORDER:
		for entry_value in entries_for(category_id):
			var definition := entry_value as Dictionary
			if str(definition.get("id", "")) == building_id:
				return definition
	return {}
