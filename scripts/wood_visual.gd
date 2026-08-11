class_name WoodVisual
extends RefCounted

const DEFAULT_SIDE_COUNT := 6
const LOG_LENGTH := 0.92
const LOG_START_RADIUS := 0.145
const LOG_END_RADIUS := 0.105
const BINARY_WOOD_SHADER := preload("res://shaders/binary_wood.gdshader")


static func binary_material(base_colour: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = BINARY_WOOD_SHADER
	material.set_shader_parameter("bright_color", base_colour)
	material.set_shader_parameter("dark_color", base_colour.darkened(0.28))
	return material


static func append_tapered_segment(
	surface_tool: SurfaceTool,
	start_point: Vector3,
	end_point: Vector3,
	start_radius: float,
	end_radius: float,
	cap_start := true,
	cap_end := true,
	side_count := DEFAULT_SIDE_COUNT
) -> void:
	var direction := (end_point - start_point).normalized()
	var reference_axis := Vector3.UP if absf(direction.dot(Vector3.UP)) < 0.94 else Vector3.RIGHT
	var radial_x := direction.cross(reference_axis).normalized()
	var radial_z := radial_x.cross(direction).normalized()
	for side_index in side_count:
		var next_side_index := (side_index + 1) % side_count
		var angle_a := TAU * float(side_index) / float(side_count)
		var angle_b := TAU * float(next_side_index) / float(side_count)
		var radial_a := radial_x * cos(angle_a) + radial_z * sin(angle_a)
		var radial_b := radial_x * cos(angle_b) + radial_z * sin(angle_b)
		var start_a := start_point + radial_a * start_radius
		var start_b := start_point + radial_b * start_radius
		var end_a := end_point + radial_a * end_radius
		var end_b := end_point + radial_b * end_radius

		_add_triangle(surface_tool, start_a, end_a, end_b)
		_add_triangle(surface_tool, start_a, end_b, start_b)
		if cap_start:
			_add_triangle(surface_tool, start_point, start_a, start_b)
		if cap_end:
			_add_triangle(surface_tool, end_point, end_b, end_a)


static func _add_triangle(
	surface_tool: SurfaceTool,
	point_a: Vector3,
	point_b: Vector3,
	point_c: Vector3
) -> void:
	surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(point_a)
	surface_tool.add_vertex(point_b)
	surface_tool.add_vertex(point_c)
