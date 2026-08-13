class_name WorldItem
extends Node3D

const GameplaySettingsScript = preload("res://scripts/gameplay_settings.gd")

const LIMESTONE_SHADER := preload("res://shaders/limestone.gdshader")

const Palette = preload("res://scripts/game_palette.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")
const DeterministicRandomScript = preload("res://scripts/deterministic_random.gd")
const CitizenNavigationPolicyScript = preload("res://scripts/citizen_navigation_policy.gd")
const ObjAssetScript = preload("res://scripts/obj_asset.gd")

const PROP_ASSET_DIRECTORY := "res://data/props"

const TREE_SEGMENT_HEIGHT := 1.0
const LOOSE_LOG_LENGTH := WoodVisual.LOG_LENGTH
const TREE_INITIAL_LOG_MINIMUM := 2
const TREE_INITIAL_LOG_VARIATION := 2
const TREE_MAX_LOG_COUNT := 3
const TREE_GROWTH_INTERVAL_DAYS := 3
static var SIMULATION_DAY_SECONDS := GameplaySettingsScript.SIMULATION_DAY_SECONDS
static var TREE_GROWTH_INTERVAL := SIMULATION_DAY_SECONDS * TREE_GROWTH_INTERVAL_DAYS
const TREE_GROWTH_STEP_HEIGHT := 1.0
static var BUSH_REGROWTH_SECONDS := GameplaySettingsScript.BUSH_REGROWTH_SECONDS

signal calories_harvested(amount: int)

var item_kind := "tree"
var is_carried := false
var permanent_detail_seed := 1
var tree_log_count := 0
var tree_growth_height := 0.0
var tree_top_present := true
var water_stored := 0
var _cooldown := 0.0
var _tree_growth_remaining := TREE_GROWTH_INTERVAL
var _sway_elapsed := 0.0
var _body: StaticBody3D
var _berries_visual: MultiMeshInstance3D
var _limestone_material: ShaderMaterial
var _visual_root: Node3D
var _stump_uses_palm_colour := false
var _simulation_speed := 1.0


func configure(next_kind: String, detail_seed := 1) -> void:
	item_kind = next_kind
	permanent_detail_seed = maxi(1, detail_seed)
	if _is_tree_kind() and tree_log_count == 0:
		tree_top_present = true
		if item_kind == "tree":
			var growth_stages: Array[float] = [1.0, 1.5, 2.0, 2.5, 3.0]
			tree_growth_height = growth_stages[permanent_detail_seed % growth_stages.size()]
			tree_log_count = ceili(tree_growth_height)
		else:
			tree_log_count = TREE_INITIAL_LOG_MINIMUM + permanent_detail_seed % TREE_INITIAL_LOG_VARIATION
			tree_growth_height = float(tree_log_count)
		_tree_growth_remaining = TREE_GROWTH_INTERVAL
	water_stored = 1 if item_kind == "cactus" else 0
	# Loose Logs may face either horizontal cardinal axis, but never settle at an
	# arbitrary diagonal. Rotating the WorldItem keeps its mesh and collision
	# aligned together.
	rotation.y = float(permanent_detail_seed % 2) * PI * 0.5 if item_kind == "log" else 0.0
	if is_inside_tree():
		_rebuild_visual()


func set_simulation_speed(next_speed: float) -> void:
	_simulation_speed = maxf(0.0, next_speed)


func _ready() -> void:
	_rebuild_visual()


func is_available_log() -> bool:
	return item_kind == "log" and not is_carried


func _is_tree_kind() -> bool:
	return item_kind == "tree" or item_kind == "dead_tree" or item_kind == "palm_tree"


func cut_top_log() -> Dictionary:
	if not _is_tree_kind() or tree_log_count <= 0:
		return {}
	var was_palm := item_kind == "palm_tree"
	var removed_log_index := tree_log_count
	var fall_angle := _seed_fraction(removed_log_index, 73) * TAU
	var fall_distance := 0.54 + _seed_fraction(removed_log_index, 79) * 0.2
	var drop_offset := Vector3(cos(fall_angle) * fall_distance, 0.0, sin(fall_angle) * fall_distance)
	var log_axis := 1 if absf(sin(fall_angle)) > absf(cos(fall_angle)) else 0
	tree_growth_height = maxf(0.0, tree_growth_height - TREE_SEGMENT_HEIGHT)
	tree_log_count = ceili(tree_growth_height)
	tree_top_present = false
	_tree_growth_remaining = TREE_GROWTH_INTERVAL
	if tree_log_count <= 0:
		_stump_uses_palm_colour = was_palm
		item_kind = "stump"
		tree_log_count = 0
		tree_growth_height = 0.0
	_rebuild_visual()
	return {
		"drop_position": global_position + drop_offset,
		"log_detail_seed": permanent_detail_seed * 8 + removed_log_index * 2 + log_axis,
		"remaining_logs": tree_log_count,
	}


func collect_water() -> int:
	if item_kind != "cactus" or water_stored <= 0:
		return 0
	var collected_water := water_stored
	water_stored = 0
	queue_free()
	return collected_water


func has_collectable_water() -> bool:
	return item_kind == "cactus" and water_stored > 0


func harvest() -> bool:
	if item_kind != "bush" or _cooldown > 0.0:
		return false
	_cooldown = BUSH_REGROWTH_SECONDS
	if is_instance_valid(_berries_visual):
		_berries_visual.visible = false
	calories_harvested.emit(1)
	return true


func can_harvest() -> bool:
	return item_kind == "bush" and _cooldown <= 0.0


func stream_state() -> Dictionary:
	return {
		"kind": item_kind,
		"detail_seed": permanent_detail_seed,
		"tree_log_count": tree_log_count,
		"tree_growth_height": tree_growth_height,
		"tree_top_present": tree_top_present,
		"water_stored": water_stored,
		"cooldown": _cooldown,
		"tree_growth_remaining": _tree_growth_remaining,
		"stump_uses_palm_colour": _stump_uses_palm_colour,
		"rotation_y": rotation.y,
	}


func restore_stream_state(state: Dictionary) -> void:
	item_kind = str(state.get("kind", item_kind))
	permanent_detail_seed = int(state.get("detail_seed", permanent_detail_seed))
	tree_log_count = int(state.get("tree_log_count", tree_log_count))
	tree_growth_height = float(state.get("tree_growth_height", tree_growth_height))
	tree_top_present = bool(state.get("tree_top_present", tree_top_present))
	water_stored = int(state.get("water_stored", water_stored))
	_cooldown = float(state.get("cooldown", _cooldown))
	_tree_growth_remaining = float(state.get("tree_growth_remaining", _tree_growth_remaining))
	_stump_uses_palm_colour = bool(state.get("stump_uses_palm_colour", _stump_uses_palm_colour))
	rotation.y = float(state.get("rotation_y", rotation.y))
	if is_inside_tree():
		_rebuild_visual()


func advance_generated_age(age_seconds: float) -> void:
	_advance_tree_growth(age_seconds)


func advance_stream_time(elapsed_seconds: float) -> void:
	if elapsed_seconds <= 0.0:
		return
	if item_kind == "bush" and _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - elapsed_seconds)
		if is_instance_valid(_berries_visual):
			_berries_visual.visible = _cooldown <= 0.0
	elif _can_grow_tree():
		_advance_tree_growth(elapsed_seconds)


func set_limestone_cycle(daylight: float, surface_colour: Color, sun_direction: Vector3) -> void:
	if item_kind != "stone" or not is_instance_valid(_limestone_material):
		return
	_limestone_material.set_shader_parameter("top_color", surface_colour)
	_limestone_material.set_shader_parameter("daylight", daylight)
	_limestone_material.set_shader_parameter("sun_direction_world", sun_direction)


func take_for_carry() -> bool:
	if not is_available_log():
		return false
	is_carried = true
	visible = false
	if _body != null:
		_body.collision_layer = 0
	return true


func release_from_carry(world_position: Vector3) -> void:
	if item_kind != "log" or not is_carried:
		return
	is_carried = false
	global_position = world_position
	visible = true
	if _body != null:
		_body.collision_layer = CitizenNavigationPolicyScript.world_item_collision_layer(item_kind)


func _process(delta: float) -> void:
	_sway_elapsed += delta
	var simulation_delta := delta * _simulation_speed
	if item_kind == "bush" and _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - simulation_delta)
		if _cooldown <= 0.0 and is_instance_valid(_berries_visual):
			_berries_visual.visible = true
	if is_instance_valid(_visual_root) and _is_tree_kind():
		var phase := _seed_fraction(0, 113) * TAU
		var sway := sin(_sway_elapsed * 0.72 + phase)
		var cross_sway := cos(_sway_elapsed * 0.53 + phase * 0.7)
		_visual_root.rotation.x = sway * 0.014
		_visual_root.rotation.z = cross_sway * 0.018

	if _can_grow_tree():
		_advance_tree_growth(simulation_delta)


func _can_grow_tree() -> bool:
	if item_kind == "stump":
		return true
	return (
		item_kind in ["tree", "palm_tree"]
		and tree_top_present
		and tree_growth_height < float(TREE_MAX_LOG_COUNT)
	)


func _advance_tree_growth(elapsed_seconds: float) -> void:
	if elapsed_seconds <= 0.0 or not _can_grow_tree():
		return
	var remaining_age := elapsed_seconds
	var visual_changed := false
	while _can_grow_tree() and remaining_age >= _tree_growth_remaining:
		remaining_age -= _tree_growth_remaining
		if item_kind == "stump":
			item_kind = "palm_tree" if _stump_uses_palm_colour else "tree"
			tree_growth_height = TREE_GROWTH_STEP_HEIGHT
			tree_log_count = 1
			tree_top_present = true
		else:
			tree_growth_height = minf(
				float(TREE_MAX_LOG_COUNT),
				tree_growth_height + TREE_GROWTH_STEP_HEIGHT
			)
			tree_log_count = ceili(tree_growth_height)
		_tree_growth_remaining = TREE_GROWTH_INTERVAL
		visual_changed = true
	if _can_grow_tree():
		_tree_growth_remaining = maxf(0.0, _tree_growth_remaining - remaining_age)
	if visual_changed and is_inside_tree():
		_rebuild_visual()


func _rebuild_visual() -> void:
	for child in get_children():
		child.queue_free()
	_body = null
	_visual_root = null
	_berries_visual = null
	_build_obj_visual()


func _build_obj_visual() -> void:
	var asset_path := _prop_asset_path()
	_visual_root = ObjAssetScript.instantiate(
		asset_path,
		Callable(self, "_prop_material_for_part"),
		true
	)
	_visual_root.name = "ObjVisual"
	add_child(_visual_root)
	if item_kind == "bush":
		var berry_nodes := _visual_root.find_children("BatchedBerryDots*", "MeshInstance3D", true, false)
		_berries_visual = _make_berry_multimesh(berry_nodes)
		for berry_node_value in berry_nodes:
			(berry_node_value as MeshInstance3D).visible = false
		_add_collision(Vector3(1.28, 0.7, 0.9), Vector3(0.0, 0.35, 0.02))
	elif item_kind == "cactus":
		_add_collision(Vector3(0.8, 1.45, 0.5), Vector3(0.0, 0.725, 0.0))
	elif item_kind == "stone":
		var asset_bounds := _node_visual_bounds(_visual_root)
		_add_collision(asset_bounds.size, asset_bounds.get_center())
	elif item_kind == "stump":
		_add_collision(Vector3(0.48, 0.22, 0.48), Vector3(0.0, 0.11, 0.0))
	elif item_kind == "log":
		_add_collision(Vector3(LOOSE_LOG_LENGTH, 0.28, 0.32), Vector3(0.0, 0.14, 0.0))
	elif item_kind == "palm_tree":
		var palm_height := float(tree_log_count) * TREE_SEGMENT_HEIGHT + 0.25
		_add_collision(Vector3(1.35, palm_height, 1.35), Vector3(0.0, palm_height * 0.5, 0.0))
	else:
		var tree_height := tree_growth_height * TREE_SEGMENT_HEIGHT + 0.45
		_add_collision(Vector3(1.2, tree_height, 1.2), Vector3(0.0, tree_height * 0.5, 0.0))


func _prop_asset_path() -> String:
	var variant := posmod(permanent_detail_seed - 17, 3) + 1
	if item_kind == "tree":
		var height_step := clampi(roundi(tree_growth_height * 10.0), 10, 30)
		if not tree_top_present:
			height_step = clampi(roundi(tree_growth_height), 1, 3)
		var bare_infix := "_bare" if not tree_top_present else ""
		return "%s/tree%s_%d_v%d.obj" % [PROP_ASSET_DIRECTORY, bare_infix, height_step, variant]
	if item_kind == "dead_tree":
		return "%s/dead_tree_%d_v%d.obj" % [PROP_ASSET_DIRECTORY, clampi(tree_log_count, 1, 3), variant]
	if item_kind == "palm_tree":
		var bare_infix := "_bare" if not tree_top_present else ""
		return "%s/palm_tree%s_%d_v%d.obj" % [
			PROP_ASSET_DIRECTORY, bare_infix, clampi(tree_log_count, 1, 3), variant
		]
	if item_kind == "stone":
		return "%s/limestone_%d_v%d.obj" % [
			PROP_ASSET_DIRECTORY, 1 + posmod(permanent_detail_seed, 3), variant
		]
	return "%s/%s_v%d.obj" % [PROP_ASSET_DIRECTORY, item_kind, variant]


func _prop_material_for_part(part_name: String) -> Material:
	if item_kind == "stone":
		_limestone_material = _limestone_surface_material()
		return _limestone_material
	if part_name.begins_with("BatchedBerryDots"):
		return _material(Palette.WOODEN_ROOF, true)
	if part_name.begins_with("BushLobe") or part_name == "TreeFoliage":
		return _material(_greenery_colour(223), true)
	if part_name == "PalmLightLeaves":
		return _material(Palette.PALM_LEAF_LIGHT, true)
	if part_name == "PalmDarkLeaves":
		return _material(Palette.PALM_LEAF_DARK, true)
	if part_name == "PalmTrunk" or (_stump_uses_palm_colour and part_name == "TreeStump"):
		return _material(Palette.PALM_TRUNK, true)
	if item_kind == "cactus":
		return _material(Palette.CACTUS, true)
	return _binary_wood_material(Palette.ROOF_LOG)


func _make_berry_multimesh(berry_nodes: Array[Node]) -> MultiMeshInstance3D:
	var berry_multimesh_instance := MultiMeshInstance3D.new()
	berry_multimesh_instance.name = "BatchedBerryDots"
	if berry_nodes.is_empty():
		add_child(berry_multimesh_instance)
		return berry_multimesh_instance
	var berry_multimesh := MultiMesh.new()
	berry_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var combined_berry_tool := SurfaceTool.new()
	combined_berry_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for berry_node_value in berry_nodes:
		var berry_node := berry_node_value as MeshInstance3D
		var arrays := berry_node.mesh.surface_get_arrays(0)
		var berry_vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for berry_vertex in berry_vertices:
			combined_berry_tool.add_vertex(berry_node.transform * berry_vertex)
	combined_berry_tool.generate_normals()
	berry_multimesh.mesh = combined_berry_tool.commit()
	berry_multimesh.instance_count = 1
	berry_multimesh.set_instance_transform(0, Transform3D.IDENTITY)
	berry_multimesh_instance.multimesh = berry_multimesh
	berry_multimesh_instance.material_override = _material(Palette.WOODEN_ROOF, true)
	berry_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	berry_multimesh_instance.visible = _cooldown <= 0.0
	add_child(berry_multimesh_instance)
	return berry_multimesh_instance


func _node_visual_bounds(root_node: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for mesh_node_value in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := mesh_node_value as MeshInstance3D
		var mesh_bounds := mesh_node.transform * mesh_node.get_aabb()
		bounds = bounds.merge(mesh_bounds) if has_bounds else mesh_bounds
		has_bounds = true
	return bounds


func _seed_fraction(index: int, salt: int) -> float:
	return DeterministicRandomScript.detail_fraction(permanent_detail_seed, index, salt)


func _greenery_colour(salt: int) -> Color:
	# The permanent detail seed makes the choice stable across visual rebuilds
	# and save/load. One flat colour belongs to the complete crown or Bush.
	var variant_count: int = Palette.GREENERY_VARIANTS.size()
	var variant_index := clampi(
		floori(_seed_fraction(0, salt) * float(variant_count)),
		0,
		variant_count - 1
	)
	return Palette.GREENERY_VARIANTS[variant_index]


func _limestone_surface_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = LIMESTONE_SHADER
	material.set_shader_parameter("top_color", Palette.SAND_SURFACE)
	material.set_shader_parameter("side_color", Palette.LIMESTONE_SIDE)
	material.set_shader_parameter("daylight", 1.0)
	return material


func _add_collision(size: Vector3, local_position: Vector3) -> void:
	_body = StaticBody3D.new()
	_body.collision_layer = CitizenNavigationPolicyScript.world_item_collision_layer(item_kind)
	_body.set_meta("world_object", self)
	# This body keeps the WorldItem clickable. Citizen routing reads the separate
	# navigation policy, so a Tree can be passable without losing interaction.
	_body.set_meta(
		"citizen_navigation_mode",
		CitizenNavigationPolicyScript.world_item_mode(item_kind)
	)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = local_position
	_body.add_child(shape)
	add_child(_body)


func _material(color: Color, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _binary_wood_material(base_colour: Color) -> ShaderMaterial:
	return WoodVisual.binary_material(base_colour)
