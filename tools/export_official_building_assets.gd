extends SceneTree

const BuildingBlueprintScript = preload("res://scripts/building_blueprint.gd")
const ObjExporter = preload("res://scripts/building_blueprint_obj_exporter.gd")

const OFFICIAL_BUILDINGS: Array[String] = [
	"four_log_support",
	"platform",
	"sawmill",
	"pile",
]


func _initialize() -> void:
	var failed := false
	for building_id in OFFICIAL_BUILDINGS:
		var source_path := "res://data/buildings/%s.pyrbuilding" % building_id
		var blueprint := BuildingBlueprintScript.load_from_file(source_path)
		if not blueprint.last_error.is_empty():
			printerr("Unable to load %s: %s" % [source_path, blueprint.last_error])
			failed = true
			continue
		var destination_path := "res://data/buildings/exports/%s.obj" % building_id
		var export_error := ObjExporter.export_to_file(blueprint, destination_path)
		if export_error != OK:
			printerr("Unable to export %s: %s" % [destination_path, error_string(export_error)])
			failed = true
		else:
			print("Exported %s" % destination_path)
	quit(1 if failed else 0)
