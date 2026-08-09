extends Node3D

const DeterministicRandomScript = preload("res://scripts/deterministic_random.gd")

const Palette = preload("res://scripts/game_palette.gd")

const CHUNK_SIZE := 8
const TUFTS_PER_WORLD_UNIT := 6
const MAX_RENDER_DISTANCE := 20.0
const BILLBOARD_CULL_PADDING := 0.5

var _world_half_extent := 0.0
var _fog_cell_size := 0.5
var _tuft_mesh: ArrayMesh
var _grass_material: ShaderMaterial
var _chunk_candidates: Dictionary = {}
var _chunk_instances: Dictionary = {}
var _revealed_fog_cells: Dictionary = {}
var _excluded_world_units: Dictionary = {}


func setup(
	world_half_extent: float,
	fog_cell_size: float,
	excluded_world_units: Dictionary = {}
) -> void:
	_world_half_extent = world_half_extent
	_fog_cell_size = fog_cell_size
	_excluded_world_units = excluded_world_units.duplicate()
	_tuft_mesh = _create_tuft_mesh()
	_grass_material = _create_grass_material()
	_build_chunk_candidates()


func has_grass_in_world_unit(world_unit: Vector2i) -> bool:
	return _world_unit_has_grass(world_unit.x, world_unit.y)


func reveal_fog_cells(newly_revealed_cells: Array[Vector2i]) -> void:
	var affected_chunks: Dictionary = {}
	for fog_cell in newly_revealed_cells:
		if _revealed_fog_cells.has(fog_cell):
			continue
		_revealed_fog_cells[fog_cell] = true
		var world_unit := Vector2i(
			floori(float(fog_cell.x) * _fog_cell_size),
			floori(float(fog_cell.y) * _fog_cell_size)
		)
		affected_chunks[_chunk_coordinate(world_unit)] = true
	for chunk_coordinate in affected_chunks:
		_rebuild_chunk(chunk_coordinate)


func update_viewer_position(viewer_position: Vector3) -> void:
	var viewer_2d := Vector2(viewer_position.x, viewer_position.z)
	for chunk_coordinate in _chunk_instances:
		var grass_chunk := _chunk_instances[chunk_coordinate] as MultiMeshInstance3D
		if not is_instance_valid(grass_chunk):
			continue
		var chunk_centre := Vector2(
			(chunk_coordinate.x + 0.5) * CHUNK_SIZE,
			(chunk_coordinate.y + 0.5) * CHUNK_SIZE
		)
		var distance := viewer_2d.distance_to(chunk_centre)
		grass_chunk.visible = distance <= MAX_RENDER_DISTANCE
		grass_chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_chunk_candidates() -> void:
	for world_x in range(-int(_world_half_extent), int(_world_half_extent)):
		for world_z in range(-int(_world_half_extent), int(_world_half_extent)):
			if not _world_unit_has_grass(world_x, world_z):
				continue
			var world_unit := Vector2i(world_x, world_z)
			var chunk_coordinate := _chunk_coordinate(world_unit)
			if not _chunk_candidates.has(chunk_coordinate):
				_chunk_candidates[chunk_coordinate] = []
			var candidates: Array = _chunk_candidates[chunk_coordinate]
			# A scrambled Halton set gives every occupied World Unit even coverage
			# without the rows and diagonal bands produced by independent hashes.
			# Per-tile shifts, permutation, mirroring, and axis swaps prevent the same
			# six-point silhouette from repeating across neighbouring tiles.
			var tile_seed := _coordinate_seed(world_x, world_z, 193)
			var sequence_offset := tile_seed % TUFTS_PER_WORLD_UNIT
			var shift_x := _seed_fraction(tile_seed + 211)
			var shift_z := _seed_fraction(tile_seed + 227)
			var swap_axes := tile_seed % 2 == 0
			var mirror_x := tile_seed % 3 == 0
			var mirror_z := tile_seed % 5 == 0
			for tuft_index in TUFTS_PER_WORLD_UNIT:
				var seed_value := _coordinate_seed(world_x, world_z, tuft_index)
				var sequence_index := 1 + (tuft_index + sequence_offset) % TUFTS_PER_WORLD_UNIT
				var low_discrepancy_point := Vector2(
					_radical_inverse(sequence_index, 2),
					_radical_inverse(sequence_index, 3)
				)
				if swap_axes:
					low_discrepancy_point = Vector2(low_discrepancy_point.y, low_discrepancy_point.x)
				if mirror_x:
					low_discrepancy_point.x = 1.0 - low_discrepancy_point.x
				if mirror_z:
					low_discrepancy_point.y = 1.0 - low_discrepancy_point.y
				low_discrepancy_point.x = fposmod(low_discrepancy_point.x + shift_x, 1.0)
				low_discrepancy_point.y = fposmod(low_discrepancy_point.y + shift_z, 1.0)
				var local_x := 0.07 + low_discrepancy_point.x * 0.86
				var local_z := 0.07 + low_discrepancy_point.y * 0.86
				var scale_value := 0.78 + _seed_fraction(seed_value + 131) * 0.42
				var origin := Vector3(world_x + local_x, 0.012, world_z + local_z)
				var tuft_basis := Basis.IDENTITY.scaled(Vector3(scale_value, scale_value, scale_value))
				candidates.append(Transform3D(tuft_basis, origin))


func _rebuild_chunk(chunk_coordinate: Vector2i) -> void:
	var candidates: Array = _chunk_candidates.get(chunk_coordinate, [])
	var visible_transforms: Array[Transform3D] = []
	for candidate: Transform3D in candidates:
		var fog_cell := Vector2i(
			floori(candidate.origin.x / _fog_cell_size),
			floori(candidate.origin.z / _fog_cell_size)
		)
		if _revealed_fog_cells.has(fog_cell):
			visible_transforms.append(candidate)

	if visible_transforms.is_empty():
		if _chunk_instances.has(chunk_coordinate):
			var empty_chunk := _chunk_instances[chunk_coordinate] as MultiMeshInstance3D
			if is_instance_valid(empty_chunk):
				empty_chunk.visible = false
		return

	var grass_chunk: MultiMeshInstance3D
	if _chunk_instances.has(chunk_coordinate):
		grass_chunk = _chunk_instances[chunk_coordinate] as MultiMeshInstance3D
	else:
		grass_chunk = MultiMeshInstance3D.new()
		grass_chunk.name = "GrassChunk_%d_%d" % [chunk_coordinate.x, chunk_coordinate.y]
		grass_chunk.material_override = _grass_material
		grass_chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(grass_chunk)
		_chunk_instances[chunk_coordinate] = grass_chunk

	var grass_multimesh := MultiMesh.new()
	grass_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	grass_multimesh.mesh = _tuft_mesh
	grass_multimesh.instance_count = visible_transforms.size()
	grass_multimesh.custom_aabb = AABB(
		Vector3(
			chunk_coordinate.x * CHUNK_SIZE - BILLBOARD_CULL_PADDING,
			0.0,
			chunk_coordinate.y * CHUNK_SIZE - BILLBOARD_CULL_PADDING
		),
		Vector3(
			CHUNK_SIZE + BILLBOARD_CULL_PADDING * 2.0,
			1.2,
			CHUNK_SIZE + BILLBOARD_CULL_PADDING * 2.0
		)
	)
	for instance_index in visible_transforms.size():
		grass_multimesh.set_instance_transform(instance_index, visible_transforms[instance_index])
	grass_chunk.multimesh = grass_multimesh
	grass_chunk.visible = true


func _create_tuft_mesh() -> ArrayMesh:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_billboard_vertex(surface_tool, Vector3(-0.3, 0.0, 0.0), Vector2(0.0, 0.0))
	_add_billboard_vertex(surface_tool, Vector3(0.3, 0.0, 0.0), Vector2(1.0, 0.0))
	_add_billboard_vertex(surface_tool, Vector3(0.3, 0.82, 0.0), Vector2(1.0, 1.0))
	_add_billboard_vertex(surface_tool, Vector3(-0.3, 0.0, 0.0), Vector2(0.0, 0.0))
	_add_billboard_vertex(surface_tool, Vector3(0.3, 0.82, 0.0), Vector2(1.0, 1.0))
	_add_billboard_vertex(surface_tool, Vector3(-0.3, 0.82, 0.0), Vector2(0.0, 1.0))
	return surface_tool.commit()


func _add_billboard_vertex(surface_tool: SurfaceTool, position: Vector3, uv: Vector2) -> void:
	surface_tool.set_uv(uv)
	surface_tool.add_vertex(position)


func _create_grass_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque, unshaded;

uniform vec4 grass_color : source_color;
uniform float wind_strength = 0.022;
uniform float wind_speed = 1.15;

varying float instance_seed;

float grass_hash(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	vec3 instance_origin = MODEL_MATRIX[3].xyz;
	instance_seed = grass_hash(instance_origin.xz);
	float height_variation = mix(0.82, 1.18, grass_hash(instance_origin.xz + vec2(19.7)));
	float width_variation = mix(0.8, 1.16, grass_hash(instance_origin.zx + vec2(31.3)));
	VERTEX.y *= height_variation;
	VERTEX.x *= width_variation;

	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	float scale_z = length(MODEL_MATRIX[2].xyz);
	vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 world_up = vec3(0.0, 1.0, 0.0);
	vec3 camera_forward = normalize(cross(camera_right, world_up));
	mat4 billboard_model = mat4(
		vec4(camera_right * scale_x, 0.0),
		vec4(world_up * scale_y, 0.0),
		vec4(camera_forward * scale_z, 0.0),
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_model;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float blade_mask(vec2 uv, float centre, float lean, float height, float base_width, float tip_width, float wind) {
	if (uv.y > height) {
		return 0.0;
	}
	float blade_height = clamp(uv.y / height, 0.0, 1.0);
	float blade_centre = centre + lean * blade_height + wind * blade_height * blade_height;
	float half_width = mix(base_width, tip_width, smoothstep(0.0, 1.0, blade_height));
	return step(abs(uv.x - blade_centre), half_width);
}

void fragment() {
	float wave = sin(TIME * wind_speed + instance_seed * 12.0) * wind_strength;
	float silhouette = 0.0;
	silhouette = max(silhouette, blade_mask(UV, 0.2, -0.08, 0.62, 0.105, 0.026, wave));
	silhouette = max(silhouette, blade_mask(UV, 0.4, -0.025, 0.9, 0.115, 0.026, wave));
	silhouette = max(silhouette, blade_mask(UV, 0.61, 0.035, 0.76, 0.11, 0.025, wave));
	silhouette = max(silhouette, blade_mask(UV, 0.79, 0.075, 0.57, 0.1, 0.024, wave));
	if (silhouette < 0.5) {
		discard;
	}
	ALBEDO = grass_color.rgb;
	ROUGHNESS = 0.92;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("grass_color", Palette.GRASS)
	return material


func _world_unit_has_grass(world_x: int, world_z: int) -> bool:
	if _excluded_world_units.has(Vector2i(world_x, world_z)):
		return false
	if abs(world_x) <= 3 and abs(world_z) <= 3:
		return true
	var patch_value := (
		sin(float(world_x) * 0.37)
		+ cos(float(world_z) * 0.31)
		+ sin(float(world_x + world_z) * 0.17)
	)
	return patch_value > 1.05


func _chunk_coordinate(world_unit: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(world_unit.x) / CHUNK_SIZE),
		floori(float(world_unit.y) / CHUNK_SIZE)
	)


func _coordinate_seed(x_coordinate: int, z_coordinate: int, salt: int) -> int:
	return DeterministicRandomScript.coordinate_seed(x_coordinate, z_coordinate, salt)


func _seed_fraction(seed_value: int) -> float:
	return DeterministicRandomScript.fraction(seed_value)


func _radical_inverse(sequence_index: int, base: int) -> float:
	var result := 0.0
	var inverse_base := 1.0 / float(base)
	var fraction := inverse_base
	var remaining := sequence_index
	while remaining > 0:
		result += float(remaining % base) * fraction
		remaining /= base
		fraction *= inverse_base
	return result
