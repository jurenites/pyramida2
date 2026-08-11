class_name UITextCatalog
extends RefCounted

const TEXT_CATALOG_PATH := "res://localization/ui_text.csv"

const PROTOTYPE_TITLE_TEXT := "prototype_title_text"
const PROTOTYPE_INSTRUCTIONS_TEXT := "prototype_instructions_text"
const BUILD_BUTTON_TOOLTIP_TEXT := "build_button_tooltip_text"
const GREENERY_BUTTON_TOOLTIP_TEXT := "greenery_button_tooltip_text"
const LANDSCAPE_BUTTON_TOOLTIP_TEXT := "landscape_button_tooltip_text"
const POPULATION_TOOLTIP_TEXT := "population_tooltip_text"
const SIMULATION_SPEED_TOOLTIP_TEXT := "simulation_speed_tooltip_text"
const REMOVE_BUILDING_TOOLTIP_TEXT := "remove_building_tooltip_text"
const EXCAVATE_TOOL_TOOLTIP_TEXT := "excavate_tool_tooltip_text"
const ADD_SOIL_TOOL_TOOLTIP_TEXT := "add_soil_tool_tooltip_text"
const REMOVE_SOIL_TOOL_TOOLTIP_TEXT := "remove_soil_tool_tooltip_text"
const STRUCTURE_CATEGORY_TEXT := "structure_category_text"
const PATH_CATEGORY_TEXT := "path_category_text"
const STORAGE_CATEGORY_TEXT := "storage_category_text"
const LIVABLE_CATEGORY_TEXT := "livable_category_text"
const ROAD_NAME_TEXT := "road_name_text"
const ROPE_BRIDGE_NAME_TEXT := "rope_bridge_name_text"
const SUSPENSION_BRIDGE_NAME_TEXT := "suspension_bridge_name_text"
const TUNNEL_NAME_TEXT := "tunnel_name_text"
const WAREHOUSE_NAME_TEXT := "warehouse_name_text"
const SMALL_LIVABLE_NAME_TEXT := "small_livable_name_text"
const SUPPORT_PLATFORM_NAME_TEXT := "support_platform_name_text"
const PERGOLA_NAME_TEXT := "pergola_name_text"
const LIVABLE_HOUSE_NAME_TEXT := "livable_house_name_text"
const EXIT_BUTTON_TOOLTIP_TEXT := "exit_button_tooltip_text"
const COMPASS_BUTTON_TOOLTIP_TEXT := "compass_button_tooltip_text"
const BUILDING_ROTATE_HOTKEY_TEXT := "building_rotate_hotkey_text"
const BUILDING_MODE_LABEL_TEXT := "building_mode_label_text"
const GREENERY_MODE_LABEL_TEXT := "greenery_mode_label_text"
const LANDSCAPE_MODE_LABEL_TEXT := "landscape_mode_label_text"
const CITIZEN_MODE_LABEL_TEXT := "citizen_mode_label_text"
const COMMAND_MODE_LABEL_TEXT := "command_mode_label_text"
const DAY_COUNT_TEXT := "day_count_text"
const NO_CITIZEN_SELECTED_TEXT := "no_citizen_selected_text"
const MULTIPLE_CITIZENS_SELECTED_TEXT := "multiple_citizens_selected_text"
const SINGLE_CITIZEN_SELECTED_TEXT := "single_citizen_selected_text"
const RESOURCES_SUMMARY_TEXT := "resources_summary_text"
const ONBOARDING_TITLE_TEXT := "onboarding_title_text"
const ONBOARDING_EXPLANATION_TEXT := "onboarding_explanation_text"
const ONBOARDING_DISMISS_BUTTON_TEXT := "onboarding_dismiss_button_text"
const CITIZEN_NAME_TEXT := "citizen_name_text"
const SUPPORT_NAME_TEXT := "support_name_text"
const EXCAVATION_NAME_TEXT := "excavation_name_text"
const PILE_NAME_TEXT := "pile_name_text"
const TREE_NAME_TEXT := "tree_name_text"
const DEAD_TREE_NAME_TEXT := "dead_tree_name_text"
const PALM_NAME_TEXT := "palm_name_text"
const TREE_RESOURCE_NAME_TEXT := "tree_resource_name_text"
const DEAD_TREE_RESOURCE_NAME_TEXT := "dead_tree_resource_name_text"
const PALM_RESOURCE_NAME_TEXT := "palm_resource_name_text"
const BUSH_NAME_TEXT := "bush_name_text"
const CACTUS_NAME_TEXT := "cactus_name_text"
const LIMESTONE_NAME_TEXT := "limestone_name_text"
const LOG_NAME_TEXT := "log_name_text"
const STUMP_NAME_TEXT := "stump_name_text"
const SAND_NAME_TEXT := "sand_name_text"
const SOIL_BLOCK_NAME_TEXT := "soil_block_name_text"
const CITIZEN_IDLE_STATUS_TEXT := "citizen_idle_status_text"
const CITIZEN_SLEEPING_STATUS_TEXT := "citizen_sleeping_status_text"
const CITIZEN_WALKING_STATUS_TEXT := "citizen_walking_status_text"
const CITIZEN_SELECTED_STATUS_TEXT := "citizen_selected_status_text"
const CITIZEN_NO_ROUTE_STATUS_TEXT := "citizen_no_route_status_text"
const CITIZEN_WALKING_TO_TREE_STATUS_TEXT := "citizen_walking_to_tree_status_text"
const CITIZEN_WALKING_TO_BUSH_STATUS_TEXT := "citizen_walking_to_bush_status_text"
const CITIZEN_WALKING_TO_CACTUS_STATUS_TEXT := "citizen_walking_to_cactus_status_text"
const CITIZEN_SUPPORT_COMPLETE_STATUS_TEXT := "citizen_support_complete_status_text"
const CITIZEN_SUPPORT_NEEDS_LOG_STATUS_TEXT := "citizen_support_needs_log_status_text"
const CITIZEN_FETCHING_LOG_STATUS_TEXT := "citizen_fetching_log_status_text"
const CITIZEN_TREE_UNAVAILABLE_STATUS_TEXT := "citizen_tree_unavailable_status_text"
const CITIZEN_HARVESTED_CALORIE_STATUS_TEXT := "citizen_harvested_calorie_status_text"
const CITIZEN_BUSH_REGROWING_STATUS_TEXT := "citizen_bush_regrowing_status_text"
const CITIZEN_HARVESTING_BUSH_STATUS_TEXT := "citizen_harvesting_bush_status_text"
const CITIZEN_COLLECTED_WATER_STATUS_TEXT := "citizen_collected_water_status_text"
const CITIZEN_CACTUS_UNAVAILABLE_STATUS_TEXT := "citizen_cactus_unavailable_status_text"
const CITIZEN_WATER_NEEDS_VESSEL_STATUS_TEXT := "citizen_water_needs_vessel_status_text"
const CITIZEN_COLLECTING_CACTUS_STATUS_TEXT := "citizen_collecting_cactus_status_text"
const CITIZEN_LOG_UNAVAILABLE_STATUS_TEXT := "citizen_log_unavailable_status_text"
const CITIZEN_CARRYING_LOG_STATUS_TEXT := "citizen_carrying_log_status_text"
const CITIZEN_BUILDING_STATUS_TEXT := "citizen_building_status_text"
const CITIZEN_CARRYING_FOOD_STATUS_TEXT := "citizen_carrying_food_status_text"
const CITIZEN_CONSTRUCTION_SITE_UNAVAILABLE_STATUS_TEXT := "citizen_construction_site_unavailable_status_text"
const CITIZEN_CUTTING_TREE_STATUS_TEXT := "citizen_cutting_tree_status_text"
const CITIZEN_CUT_LOG_STATUS_TEXT := "citizen_cut_log_status_text"
const CITIZEN_WALKING_TO_EXCAVATION_STATUS_TEXT := "citizen_walking_to_excavation_status_text"
const CITIZEN_DIGGING_STATUS_TEXT := "citizen_digging_status_text"
const CITIZEN_EXCAVATION_COMPLETE_STATUS_TEXT := "citizen_excavation_complete_status_text"
const CITIZEN_EXCAVATION_UNAVAILABLE_STATUS_TEXT := "citizen_excavation_unavailable_status_text"
const SUPPORT_MATERIAL_PROGRESS_TEXT := "support_material_progress_text"
const CITIZEN_DEBUG_HOVER_TEXT := "citizen_debug_hover_text"
const SUPPORT_DEBUG_HOVER_TEXT := "support_debug_hover_text"
const WORLD_ITEM_DEBUG_HOVER_TEXT := "world_item_debug_hover_text"
const WORLD_UNIT_DEBUG_HOVER_TEXT := "world_unit_debug_hover_text"
const PILE_DEBUG_HOVER_TEXT := "pile_debug_hover_text"

static var _catalog_entries: Dictionary = {}
static var _catalog_loaded := false


static func text(text_key: String, format_values: Array = []) -> String:
	_ensure_catalog_loaded()
	if not _catalog_entries.has(text_key):
		push_error("Missing UI text key: %s" % text_key)
		return text_key
	var catalog_entry: Dictionary = _catalog_entries[text_key]
	var translated_text := str(TranslationServer.translate(text_key))
	if translated_text == text_key:
		translated_text = str(catalog_entry.get("english_text", text_key))
	var resolved_text: String = translated_text % format_values if not format_values.is_empty() else translated_text
	var character_limit := int(catalog_entry.get("character_limit", 0))
	if character_limit > 0 and resolved_text.length() > character_limit:
		push_warning(
			"UI text exceeds the planned character limit: %s uses %d of %d characters" % [
				text_key,
				resolved_text.length(),
				character_limit,
			]
		)
	return resolved_text


static func _ensure_catalog_loaded() -> void:
	if _catalog_loaded:
		return
	_catalog_loaded = true
	var catalog_file := FileAccess.open(TEXT_CATALOG_PATH, FileAccess.READ)
	if catalog_file == null:
		push_error("Unable to open UI text catalog: %s" % TEXT_CATALOG_PATH)
		return
	var header := catalog_file.get_csv_line()
	var key_column_index := header.find("keys")
	var english_column_index := header.find("en")
	var character_limit_column_index := header.find("_character_limit")
	var interface_location_column_index := header.find("_interface_location")
	var translator_note_column_index := header.find("_translator_note")
	if (
		key_column_index < 0
		or english_column_index < 0
		or character_limit_column_index < 0
		or interface_location_column_index < 0
		or translator_note_column_index < 0
	):
		push_error("UI text catalog has an invalid header")
		return
	while catalog_file.get_position() < catalog_file.get_length():
		var row := catalog_file.get_csv_line()
		if row.is_empty():
			continue
		if row.size() != header.size():
			push_error("UI text catalog row does not match the header: %s" % str(row))
			continue
		if row[key_column_index].strip_edges().is_empty():
			continue
		var text_key := row[key_column_index].strip_edges()
		if text_key.count("_") < 1:
			push_error("UI text keys must contain at least two words: %s" % text_key)
			continue
		if _catalog_entries.has(text_key):
			push_error("Duplicate UI text key: %s" % text_key)
			continue
		var english_text := row[english_column_index].replace("\\n", "\n")
		var character_limit := row[character_limit_column_index].to_int()
		if character_limit <= 0:
			push_error("UI text character limit must be positive: %s" % text_key)
			continue
		if english_text.length() > character_limit:
			push_warning(
				"English UI text exceeds the planned character limit: %s uses %d of %d characters" % [
					text_key,
					english_text.length(),
					character_limit,
				]
			)
		_catalog_entries[text_key] = {
			"english_text": english_text,
			"character_limit": character_limit,
			"interface_location": row[interface_location_column_index],
			"translator_note": row[translator_note_column_index],
		}
