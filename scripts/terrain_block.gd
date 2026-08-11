class_name TerrainBlock
extends Node3D

const TERRAIN_BLOCK_SHADER := preload("res://shaders/limestone.gdshader")
const Palette = preload("res://scripts/game_palette.gd")

var block_coordinate := Vector3i.ZERO
var _terrain_material: ShaderMaterial


func configure(next_coordinate: Vector3i) -> void:
	block_coordinate = next_coordinate
	name = "TerrainBlock_%d_%d_%d" % [
		block_coordinate.x,
		block_coordinate.y,
		block_coordinate.z,
	]
	position = Vector3(
		float(block_coordinate.x) + 0.5,
		float(block_coordinate.y) + 0.5,
		float(block_coordinate.z) + 0.5
	)


func _ready() -> void:
	var block_mesh := MeshInstance3D.new()
	block_mesh.name = "SoilCube"
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	block_mesh.mesh = cube
	_terrain_material = ShaderMaterial.new()
	_terrain_material.shader = TERRAIN_BLOCK_SHADER
	_terrain_material.set_shader_parameter("top_color", Palette.SAND_SURFACE)
	_terrain_material.set_shader_parameter("side_color", Palette.LIMESTONE_SIDE)
	_terrain_material.set_shader_parameter("daylight", 1.0)
	_terrain_material.set_shader_parameter("sun_direction_world", Vector3.UP)
	block_mesh.material_override = _terrain_material
	block_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(block_mesh)

	var body := StaticBody3D.new()
	body.name = "TerrainBlockCollision"
	body.set_meta("world_object", self)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func set_day_cycle(daylight: float, surface_colour: Color, sun_direction: Vector3) -> void:
	if not is_instance_valid(_terrain_material):
		return
	_terrain_material.set_shader_parameter("top_color", surface_colour)
	_terrain_material.set_shader_parameter("daylight", daylight)
	_terrain_material.set_shader_parameter("sun_direction_world", sun_direction)


func speech_anchor_world_position() -> Vector3:
	return global_position + Vector3.UP * 0.65


func speech_actor_kind() -> String:
	return "building"
