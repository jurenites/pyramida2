class_name BuildingBlueprintInstance
extends Node3D

const BuildingBlueprintScript = preload("res://scripts/building_blueprint.gd")
const MaterialCatalog = preload("res://scripts/building_material_catalog.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")

var blueprint: BuildingBlueprint
var editor_gray_mode := false
var _parts_root: Node3D


func _ready() -> void:
	_rebuild()


func set_blueprint(new_blueprint: BuildingBlueprint) -> void:
	blueprint = new_blueprint
	_rebuild()


func set_editor_gray_mode(enabled: bool) -> void:
	editor_gray_mode = enabled
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_parts_root):
		_parts_root.queue_free()
	_parts_root = Node3D.new()
	_parts_root.name = "BlueprintParts"
	add_child(_parts_root)
	if blueprint == null:
		return
	for blueprint_part in blueprint.parts:
		var rendered_part := _render_part(blueprint_part)
		if rendered_part != null:
			_parts_root.add_child(rendered_part)


func _render_part(blueprint_part: Dictionary) -> MeshInstance3D:
	var part_kind := str(blueprint_part.get("kind", "block"))
	var geometry: Dictionary = blueprint_part.get("geometry", {})
	var material_id := str(blueprint_part.get("material", "wood"))
	var visual_variant := posmod(int(blueprint_part.get("visual_variant", 0)), 3)
	var part_colour := Color("#8A8A8A") if editor_gray_mode else MaterialCatalog.colour(material_id)
	if part_kind == "log":
		return _render_log(geometry, part_colour, visual_variant)
	return _render_box(geometry, part_colour, visual_variant)


func _render_log(
	geometry: Dictionary,
	part_colour: Color,
	visual_variant: int
) -> MeshInstance3D:
	var start_point := BuildingBlueprintScript.vector3_from_value(geometry.get("start", []))
	var end_point := BuildingBlueprintScript.vector3_from_value(geometry.get("end", []), Vector3.UP * 0.5)
	if start_point.is_equal_approx(end_point):
		return null
	var middle_point := start_point.lerp(end_point, 0.5)
	if visual_variant == 1:
		middle_point += Vector3(0.018, 0.0, -0.012)
	elif visual_variant == 2:
		middle_point += Vector3(-0.014, 0.0, 0.02)
	var start_radius := float(geometry.get("start_radius", 0.085))
	var end_radius := float(geometry.get("end_radius", 0.075))
	var middle_radius := lerpf(start_radius, end_radius, 0.5)
	var side_count := clampi(int(geometry.get("sides", 6)), 3, 12)
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	WoodVisual.append_tapered_segment(
		surface_tool,
		start_point,
		middle_point,
		start_radius,
		middle_radius,
		true,
		false,
		side_count
	)
	WoodVisual.append_tapered_segment(
		surface_tool,
		middle_point,
		end_point,
		middle_radius,
		end_radius,
		false,
		true,
		side_count
	)
	surface_tool.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.material_override = _part_material(part_colour)
	return mesh_instance


func _render_box(
	geometry: Dictionary,
	part_colour: Color,
	visual_variant: int
) -> MeshInstance3D:
	var box_mesh := BoxMesh.new()
	box_mesh.size = BuildingBlueprintScript.vector3_from_value(
		geometry.get("size", []),
		Vector3(0.46, 0.46, 0.46)
	)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = box_mesh
	mesh_instance.position = BuildingBlueprintScript.vector3_from_value(geometry.get("centre", []))
	var rotation_degrees := BuildingBlueprintScript.vector3_from_value(geometry.get("rotation_degrees", []))
	rotation_degrees.y += [-1.5, 0.0, 1.5][visual_variant]
	mesh_instance.rotation_degrees = rotation_degrees
	mesh_instance.material_override = _part_material(part_colour)
	return mesh_instance


func _part_material(part_colour: Color) -> StandardMaterial3D:
	var part_material := StandardMaterial3D.new()
	part_material.albedo_color = part_colour
	part_material.roughness = 0.92
	part_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return part_material
