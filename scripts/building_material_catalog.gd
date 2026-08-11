class_name BuildingMaterialCatalog
extends RefCounted

const Palette = preload("res://scripts/game_palette.gd")

const MATERIAL_IDS: Array[String] = ["wood", "limestone", "marble", "concrete"]


static func colour(material_id: String) -> Color:
	match material_id:
		"wood":
			return Palette.ROOF_LOG
		"limestone":
			return Palette.LIMESTONE_SIDE
		"marble":
			return Palette.MARBLE
		"concrete":
			return Palette.CONCRETE
		_:
			return Palette.PLACEMENT_ALLOWED


static func display_name(material_id: String) -> String:
	return material_id.capitalize()


static func resource_for_part(part_kind: String, material_id: String) -> String:
	match part_kind:
		"log":
			return "log"
		"plank":
			return "plank"
		"block":
			return "%s_block" % material_id
		_:
			return material_id
