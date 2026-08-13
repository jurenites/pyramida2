class_name BuildingBlueprintInstance
extends Node3D

const BuildingBlueprintScript = preload("res://scripts/building_blueprint.gd")
const MaterialCatalog = preload("res://scripts/building_material_catalog.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")
const ObjAssetScript = preload("res://scripts/obj_asset.gd")

var blueprint: BuildingBlueprint
var editor_gray_mode := false
var preview_alpha := 1.0
var _parts_root: Node3D
var _obj_part_meshes: Dictionary = {}


func _ready() -> void:
	_rebuild()


func set_blueprint(new_blueprint: BuildingBlueprint) -> void:
	blueprint = new_blueprint
	_rebuild()


func set_editor_gray_mode(enabled: bool) -> void:
	editor_gray_mode = enabled
	_rebuild()


func selection_outline_local_boxes() -> Array[AABB]:
	var occupied_boxes: Array[AABB] = []
	if blueprint == null:
		return occupied_boxes
	var occupied_sub_units := {}
	for blueprint_part in blueprint.parts:
		var sub_unit_value: Variant = blueprint_part.get("sub_unit", [])
		if not sub_unit_value is Array or sub_unit_value.size() != 3:
			continue
		var sub_unit := Vector3i(
			int(sub_unit_value[0]),
			int(sub_unit_value[1]),
			int(sub_unit_value[2])
		)
		var sub_unit_key := "%d,%d,%d" % [sub_unit.x, sub_unit.y, sub_unit.z]
		if occupied_sub_units.has(sub_unit_key):
			continue
		occupied_sub_units[sub_unit_key] = true
		occupied_boxes.append(AABB(
			Vector3(
				-0.5 + 0.5 * float(sub_unit.x),
				0.5 * float(sub_unit.y),
				-0.5 + 0.5 * float(sub_unit.z)
			),
			Vector3.ONE * 0.5
		))
	return occupied_boxes


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
	_obj_part_meshes = _load_obj_part_meshes()
	for blueprint_part in blueprint.parts:
		var rendered_part := _render_part(blueprint_part)
		if rendered_part != null:
			_parts_root.add_child(rendered_part)


func _render_part(blueprint_part: Dictionary) -> MeshInstance3D:
	var part_kind := str(blueprint_part.get("kind", "block"))
	var geometry: Dictionary = blueprint_part.get("geometry", {})
	var material_id := str(blueprint_part.get("material", "wood"))
	var visual_variant := posmod(int(blueprint_part.get("visual_variant", 0)), 3)
	var part_colour := Color("#808080") if editor_gray_mode else MaterialCatalog.colour(material_id)
	part_colour.a = clampf(preview_alpha, 0.0, 1.0)
	var primitive := str(geometry.get("primitive", "log" if part_kind == "log" else "box"))
	var rendered_part: MeshInstance3D
	var part_id := str(blueprint_part.get("id", "part"))
	if _obj_part_meshes.has(part_id):
		rendered_part = MeshInstance3D.new()
		rendered_part.name = part_id
		rendered_part.mesh = _obj_part_meshes[part_id] as Mesh
		rendered_part.material_override = _part_material(part_colour)
	elif primitive == "log":
		rendered_part = _render_log(geometry, part_colour, visual_variant)
	elif primitive == "sphere":
		rendered_part = _render_sphere(geometry, part_colour, visual_variant)
	else:
		rendered_part = _render_box(geometry, part_colour, visual_variant)
	if rendered_part != null:
		rendered_part.set_meta("blueprint_part_id", str(blueprint_part.get("id", "part")))
		rendered_part.set_meta("resource_kind", str(blueprint_part.get("resource", "")))
		rendered_part.set_meta("decorative", bool(blueprint_part.get("decorative", false)))
	return rendered_part


func _load_obj_part_meshes() -> Dictionary:
	if blueprint == null or blueprint.source_path.is_empty():
		return {}
	var obj_path := blueprint.source_path.get_basename() + ".obj"
	if not FileAccess.file_exists(obj_path):
		return {}
	return ObjAssetScript.load_objects(obj_path)


func _render_sphere(
	geometry: Dictionary,
	part_colour: Color,
	visual_variant: int
) -> MeshInstance3D:
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = float(geometry.get("radius", 0.11))
	sphere_mesh.height = float(geometry.get("height", sphere_mesh.radius * 1.5))
	sphere_mesh.radial_segments = clampi(int(geometry.get("sides", 7)), 4, 12)
	sphere_mesh.rings = 3
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = BuildingBlueprintScript.vector3_from_value(geometry.get("centre", []))
	mesh_instance.rotation_degrees = BuildingBlueprintScript.vector3_from_value(
		geometry.get("rotation_degrees", [])
	)
	mesh_instance.rotation_degrees.y += float(visual_variant) * 11.0
	mesh_instance.scale = BuildingBlueprintScript.vector3_from_value(
		geometry.get("scale", []),
		Vector3.ONE
	)
	mesh_instance.material_override = _part_material(part_colour)
	return mesh_instance


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
	if part_colour.a < 1.0:
		part_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return part_material
