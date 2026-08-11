class_name WorldItem
extends Node3D

const LIMESTONE_SHADER := preload("res://shaders/limestone.gdshader")

const Palette = preload("res://scripts/game_palette.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")
const DeterministicRandomScript = preload("res://scripts/deterministic_random.gd")
const CitizenNavigationPolicyScript = preload("res://scripts/citizen_navigation_policy.gd")

const TREE_SEGMENT_HEIGHT := 1.0
const LOOSE_LOG_LENGTH := WoodVisual.LOG_LENGTH
const TREE_INITIAL_LOG_MINIMUM := 2
const TREE_INITIAL_LOG_VARIATION := 2
const TREE_MAX_LOG_COUNT := 3
const TREE_GROWTH_INTERVAL_DAYS := 3
const SIMULATION_DAY_SECONDS := 360.0
const TREE_GROWTH_INTERVAL := SIMULATION_DAY_SECONDS * TREE_GROWTH_INTERVAL_DAYS
const TREE_GROWTH_STEP_HEIGHT := 1.0
const BUSH_REGROWTH_SECONDS := 720.0
const TREE_SIDE_COUNT := 6
const TREE_ROOT_SIDE_COUNT := 4
const TREE_BRANCH_SIDE_COUNT := 4
const TREE_CROWN_SIDE_COUNT := 8
const TREE_CROWN_RING_COUNT := 4

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
var _bush_material: StandardMaterial3D
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
	if item_kind == "tree":
		_build_tree(tree_top_present)
	elif item_kind == "dead_tree":
		_build_tree(false)
	elif item_kind == "palm_tree":
		_build_palm_tree()
	elif item_kind == "bush":
		_build_bush()
	elif item_kind == "cactus":
		_build_cactus()
	elif item_kind == "stone":
		_build_stone()
	elif item_kind == "stump":
		_build_stump()
	else:
		_build_log()


func _build_tree(has_foliage: bool) -> void:
	# One tapered trunk segment represents one physical log and rises through
	# one World Unit. The connected endpoints make upper logs inherit the tilt
	# of the logs below without turning the tree into a straight pole.
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_tree_roots(surface_tool)
	var segment_start := Vector3.ZERO
	for segment_index in tree_log_count:
		var visible_segment_height := minf(1.0, tree_growth_height - float(segment_index))
		if visible_segment_height <= 0.0:
			continue
		var bottom_weight := float(segment_index) / float(TREE_MAX_LOG_COUNT)
		var top_weight := float(segment_index + 1) / float(TREE_MAX_LOG_COUNT)
		var bottom_radius := lerpf(0.16, 0.075, bottom_weight)
		var top_radius := lerpf(0.16, 0.075, top_weight)
		var segment_end := segment_start + Vector3(
			_seed_signed(segment_index, 11) * 0.065,
			TREE_SEGMENT_HEIGHT * visible_segment_height,
			_seed_signed(segment_index, 17) * 0.065
		)
		_append_tapered_cylinder(
			surface_tool,
			segment_start,
			segment_end,
			bottom_radius,
			top_radius,
			segment_index == 0,
			segment_index == tree_log_count - 1
		)
		# The trunk stays visually clean below the crown. Branches and their
		# smaller twigs grow only from the current top log segment.
		if segment_index == tree_log_count - 1 and tree_top_present:
			_append_tree_branches(surface_tool, segment_start, segment_end, segment_index, top_radius)
		segment_start = segment_end

	surface_tool.generate_normals()
	var tree_mesh := surface_tool.commit()
	_visual_root = Node3D.new()
	_visual_root.name = "ConnectedTreeVisual"
	add_child(_visual_root)
	var tree_instance := MeshInstance3D.new()
	tree_instance.mesh = tree_mesh
	tree_instance.material_override = _binary_wood_material(Palette.ROOF_LOG)
	tree_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_visual_root.add_child(tree_instance)

	if has_foliage and tree_top_present:
		# Several faceted ellipsoids form one combined crown mesh. They remain one
		# solid palette colour while their overlapping silhouettes make the tree
		# read as a living tree rather than a pole with a single sphere on it.
		var foliage_tool := SurfaceTool.new()
		foliage_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		_append_tree_crown(foliage_tool, segment_start)
		foliage_tool.generate_normals()
		var foliage_mesh := foliage_tool.commit()
		var foliage_instance := MeshInstance3D.new()
		foliage_instance.mesh = foliage_mesh
		foliage_instance.material_override = _material(_greenery_colour(211), true)
		_visual_root.add_child(foliage_instance)

	var collision_height := tree_growth_height * TREE_SEGMENT_HEIGHT + 0.45
	_add_collision(
		Vector3(1.2, collision_height, 1.2),
		Vector3(0.0, collision_height * 0.5, 0.0)
	)


func _build_stump() -> void:
	var stump_tool := SurfaceTool.new()
	stump_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_tree_roots(stump_tool)
	_append_tapered_cylinder(
		stump_tool,
		Vector3(0.0, 0.03, 0.0),
		Vector3(_seed_signed(0, 197) * 0.025, 0.19, _seed_signed(0, 199) * 0.025),
		0.155,
		0.115,
		true,
		true
	)
	stump_tool.generate_normals()
	var stump_instance := MeshInstance3D.new()
	stump_instance.name = "TreeStump"
	stump_instance.mesh = stump_tool.commit()
	var stump_colour := Palette.PALM_TRUNK if _stump_uses_palm_colour else Palette.ROOF_LOG
	stump_instance.material_override = _binary_wood_material(stump_colour)
	stump_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(stump_instance)
	_add_collision(Vector3(0.48, 0.22, 0.48), Vector3(0.0, 0.11, 0.0))


func _append_tree_branches(
	surface_tool: SurfaceTool,
	segment_start: Vector3,
	segment_end: Vector3,
	segment_index: int,
	trunk_radius: float
) -> void:
	var branch_count := 3 + int(_seed_fraction(segment_index, 23) > 0.55)
	for branch_index in branch_count:
		var branch_seed_index := segment_index * 5 + branch_index
		var height_weight := 0.38 + _seed_fraction(branch_seed_index, 29) * 0.46
		var branch_start := segment_start.lerp(segment_end, height_weight)
		var angle := _seed_fraction(branch_seed_index, 31) * TAU
		var branch_length := 0.31 + _seed_fraction(branch_seed_index, 37) * 0.22
		var branch_rise := 0.1 + _seed_fraction(branch_seed_index, 41) * 0.16
		var branch_end := branch_start + Vector3(
			cos(angle) * branch_length,
			branch_rise,
			sin(angle) * branch_length
		)
		var branch_radius := maxf(0.035, trunk_radius * (0.52 - float(segment_index) * 0.015))
		_append_tapered_cylinder(
			surface_tool, branch_start, branch_end,
			branch_radius, branch_radius * 0.42,
			true, true, TREE_BRANCH_SIDE_COUNT
		)
		_append_branch_twigs(surface_tool, branch_start, branch_end, branch_seed_index, angle, branch_radius)


func _append_branch_twigs(
	surface_tool: SurfaceTool,
	branch_start: Vector3,
	branch_end: Vector3,
	branch_seed_index: int,
	branch_angle: float,
	branch_radius: float
) -> void:
	var twig_count := 2 + int(_seed_fraction(branch_seed_index, 43) > 0.56)
	for twig_index in twig_count:
		var twig_seed_index := branch_seed_index * 3 + twig_index
		var twig_start_weight := 0.42 + _seed_fraction(twig_seed_index, 47) * 0.38
		var twig_start := branch_start.lerp(branch_end, twig_start_weight)
		var twig_angle := branch_angle + _seed_signed(twig_seed_index, 53) * 1.15
		var twig_length := 0.12 + _seed_fraction(twig_seed_index, 59) * 0.13
		var twig_end := twig_start + Vector3(
			cos(twig_angle) * twig_length,
			0.045 + _seed_fraction(twig_seed_index, 61) * 0.09,
			sin(twig_angle) * twig_length
		)
		var twig_radius := maxf(0.013, branch_radius * 0.46)
		_append_tapered_cylinder(
			surface_tool, twig_start, twig_end,
			twig_radius, 0.009,
			true, true, TREE_BRANCH_SIDE_COUNT
		)


func _append_tree_crown(surface_tool: SurfaceTool, tree_top: Vector3) -> void:
	var crown_count := 5 + maxi(0, tree_log_count - 1) * 2
	for crown_index in crown_count:
		var angle := _seed_fraction(crown_index, 67) * TAU
		var radial_distance := 0.0 if crown_index == 0 else 0.14 + _seed_fraction(crown_index, 71) * 0.22
		var centre_height := 0.1 if crown_index == 0 else -0.13 + _seed_fraction(crown_index, 73) * 0.3
		var crown_centre := tree_top + Vector3(
			cos(angle) * radial_distance,
			centre_height,
			sin(angle) * radial_distance
		)
		var horizontal_radius := 0.24 + _seed_fraction(crown_index, 79) * 0.12
		var crown_radii := Vector3(
			horizontal_radius,
			0.24 + _seed_fraction(crown_index, 83) * 0.11,
			horizontal_radius * (0.88 + _seed_fraction(crown_index, 89) * 0.24)
		)
		_append_ellipsoid(surface_tool, crown_centre, crown_radii)


func _append_ellipsoid(surface_tool: SurfaceTool, centre: Vector3, radii: Vector3) -> void:
	for ring_index in TREE_CROWN_RING_COUNT:
		var latitude_a := -PI * 0.5 + PI * float(ring_index) / float(TREE_CROWN_RING_COUNT)
		var latitude_b := -PI * 0.5 + PI * float(ring_index + 1) / float(TREE_CROWN_RING_COUNT)
		for side_index in TREE_CROWN_SIDE_COUNT:
			var longitude_a := TAU * float(side_index) / float(TREE_CROWN_SIDE_COUNT)
			var longitude_b := TAU * float(side_index + 1) / float(TREE_CROWN_SIDE_COUNT)
			var point_aa := _ellipsoid_point(centre, radii, latitude_a, longitude_a)
			var point_ba := _ellipsoid_point(centre, radii, latitude_b, longitude_a)
			var point_bb := _ellipsoid_point(centre, radii, latitude_b, longitude_b)
			var point_ab := _ellipsoid_point(centre, radii, latitude_a, longitude_b)
			_add_triangle(surface_tool, point_aa, point_ba, point_bb)
			_add_triangle(surface_tool, point_aa, point_bb, point_ab)


func _ellipsoid_point(centre: Vector3, radii: Vector3, latitude: float, longitude: float) -> Vector3:
	var latitude_radius := cos(latitude)
	return centre + Vector3(
		latitude_radius * cos(longitude) * radii.x,
		sin(latitude) * radii.y,
		latitude_radius * sin(longitude) * radii.z
	)


func _append_tree_roots(surface_tool: SurfaceTool) -> void:
	# Three thicker four-sided roots read more clearly than the former cluster of
	# four thin six-sided cylinders and use substantially fewer surfaces.
	for root_index in 3:
		var angle := TAU * float(root_index) / 3.0 + _seed_signed(root_index, 109) * 0.2
		var root_start := Vector3(cos(angle) * 0.045, 0.075, sin(angle) * 0.045)
		var root_length := 0.22 + _seed_fraction(root_index, 111) * 0.13
		var root_end := Vector3(cos(angle) * root_length, 0.018, sin(angle) * root_length)
		_append_tapered_cylinder(
			surface_tool, root_start, root_end,
			0.105, 0.024,
			true, true, TREE_ROOT_SIDE_COUNT
		)


func _append_tapered_cylinder(
	surface_tool: SurfaceTool,
	start_point: Vector3,
	end_point: Vector3,
	start_radius: float,
	end_radius: float,
	cap_start := true,
	cap_end := true,
	side_count := TREE_SIDE_COUNT
) -> void:
	WoodVisual.append_tapered_segment(
		surface_tool, start_point, end_point, start_radius, end_radius,
		cap_start, cap_end, side_count
	)


func _add_triangle(surface_tool: SurfaceTool, point_a: Vector3, point_b: Vector3, point_c: Vector3) -> void:
	surface_tool.set_smooth_group(-1)
	surface_tool.add_vertex(point_a)
	surface_tool.add_vertex(point_b)
	surface_tool.add_vertex(point_c)


func _seed_fraction(index: int, salt: int) -> float:
	return DeterministicRandomScript.detail_fraction(permanent_detail_seed, index, salt)


func _seed_signed(index: int, salt: int) -> float:
	return _seed_fraction(index, salt) * 2.0 - 1.0


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


func _build_palm_tree() -> void:
	var trunk_tool := SurfaceTool.new()
	trunk_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_tree_roots(trunk_tool)
	var lean_angle := _seed_fraction(0, 127) * TAU
	var segment_start := Vector3.ZERO
	for segment_index in tree_log_count:
		var bottom_weight := float(segment_index) / float(TREE_MAX_LOG_COUNT)
		var top_weight := float(segment_index + 1) / float(TREE_MAX_LOG_COUNT)
		var bottom_radius := lerpf(0.15, 0.075, bottom_weight)
		var top_radius := lerpf(0.15, 0.075, top_weight)
		var bend_amount := 0.07 + float(segment_index) * 0.025
		var segment_end := segment_start + Vector3(
			cos(lean_angle) * bend_amount,
			TREE_SEGMENT_HEIGHT,
			sin(lean_angle) * bend_amount
		)
		_append_tapered_cylinder(
			trunk_tool,
			segment_start,
			segment_end,
			bottom_radius,
			top_radius,
			segment_index == 0,
			segment_index == tree_log_count - 1
		)
		segment_start = segment_end
	trunk_tool.generate_normals()

	_visual_root = Node3D.new()
	_visual_root.name = "ConnectedPalmVisual"
	add_child(_visual_root)
	var trunk_instance := MeshInstance3D.new()
	trunk_instance.mesh = trunk_tool.commit()
	trunk_instance.material_override = _material(Palette.PALM_TRUNK, true)
	_visual_root.add_child(trunk_instance)

	if tree_top_present:
		var light_leaf_tool := SurfaceTool.new()
		light_leaf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var dark_leaf_tool := SurfaceTool.new()
		dark_leaf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for leaf_index in 5:
			var angle := TAU * float(leaf_index) / 5.0 + _seed_signed(leaf_index, 131) * 0.19
			_append_palm_leaf(
				light_leaf_tool,
				segment_start + Vector3.UP * (0.09 + _seed_signed(leaf_index, 137) * 0.035),
				angle,
				0.8 + _seed_signed(leaf_index, 139) * 0.09,
				0.19 + _seed_signed(leaf_index, 149) * 0.025,
				0.2 + _seed_fraction(leaf_index, 151) * 0.15,
				_seed_signed(leaf_index, 157) * 0.09
			)
			_append_palm_leaf(
				dark_leaf_tool,
				segment_start + Vector3.UP * (_seed_signed(leaf_index, 163) * 0.025),
				angle + 0.27 + _seed_signed(leaf_index, 167) * 0.12,
				0.73 + _seed_signed(leaf_index, 173) * 0.1,
				0.17 + _seed_signed(leaf_index, 179) * 0.025,
				0.3 + _seed_fraction(leaf_index, 181) * 0.18,
				_seed_signed(leaf_index, 191) * 0.11
			)
		light_leaf_tool.generate_normals()
		dark_leaf_tool.generate_normals()
		var light_leaves := MeshInstance3D.new()
		light_leaves.mesh = light_leaf_tool.commit()
		light_leaves.material_override = _material(Palette.PALM_LEAF_LIGHT, true)
		_visual_root.add_child(light_leaves)
		var dark_leaves := MeshInstance3D.new()
		dark_leaves.mesh = dark_leaf_tool.commit()
		dark_leaves.material_override = _material(Palette.PALM_LEAF_DARK, true)
		_visual_root.add_child(dark_leaves)

	var collision_height := float(tree_log_count) * TREE_SEGMENT_HEIGHT + 0.25
	_add_collision(Vector3(1.35, collision_height, 1.35), Vector3(0.0, collision_height * 0.5, 0.0))


func _append_palm_leaf(
	surface_tool: SurfaceTool,
	leaf_start: Vector3,
	angle: float,
	length: float,
	width: float,
	sag: float,
	side_curve: float
) -> void:
	var direction := Vector3(cos(angle), 0.0, sin(angle))
	var sideways := Vector3(-direction.z, 0.0, direction.x)
	const LEAF_SEGMENT_COUNT := 5
	for segment_index in LEAF_SEGMENT_COUNT:
		var start_weight := float(segment_index) / float(LEAF_SEGMENT_COUNT)
		var end_weight := float(segment_index + 1) / float(LEAF_SEGMENT_COUNT)
		var start_width := width * (0.08 + sin(PI * start_weight) * 0.92)
		var end_width := width * (0.08 + sin(PI * end_weight) * 0.92)
		var start_centre := leaf_start + direction * (length * start_weight)
		start_centre += sideways * side_curve * sin(PI * start_weight)
		start_centre.y += 0.06 * sin(PI * start_weight) - sag * start_weight * start_weight
		var end_centre := leaf_start + direction * (length * end_weight)
		end_centre += sideways * side_curve * sin(PI * end_weight)
		end_centre.y += 0.06 * sin(PI * end_weight) - sag * end_weight * end_weight
		var start_left := start_centre + sideways * start_width
		var start_right := start_centre - sideways * start_width
		var end_left := end_centre + sideways * end_width
		var end_right := end_centre - sideways * end_width
		_add_triangle(surface_tool, start_left, end_left, end_right)
		_add_triangle(surface_tool, start_left, end_right, start_right)
		_add_triangle(surface_tool, start_left, end_right, end_left)
		_add_triangle(surface_tool, start_left, start_right, end_right)


func _build_cactus() -> void:
	var cactus_material := _material(Palette.CACTUS, true)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.14
	trunk.bottom_radius = 0.17
	trunk.height = 1.42
	trunk.radial_segments = 6
	trunk.rings = 1
	var trunk_instance := MeshInstance3D.new()
	trunk_instance.mesh = trunk
	trunk_instance.position.y = 0.71
	trunk_instance.material_override = cactus_material
	add_child(trunk_instance)
	for arm_index in 2:
		var side := -1.0 if arm_index == 0 else 1.0
		var horizontal := CylinderMesh.new()
		horizontal.top_radius = 0.075
		horizontal.bottom_radius = 0.09
		horizontal.height = 0.34
		horizontal.radial_segments = 6
		var horizontal_instance := MeshInstance3D.new()
		horizontal_instance.mesh = horizontal
		horizontal_instance.position = Vector3(side * 0.17, 0.68 + float(arm_index) * 0.16, 0.0)
		horizontal_instance.rotation_degrees.z = 90.0
		horizontal_instance.material_override = cactus_material
		add_child(horizontal_instance)
		var upright := CylinderMesh.new()
		upright.top_radius = 0.065
		upright.bottom_radius = 0.08
		upright.height = 0.38
		upright.radial_segments = 6
		var upright_instance := MeshInstance3D.new()
		upright_instance.mesh = upright
		upright_instance.position = Vector3(side * 0.33, 0.85 + float(arm_index) * 0.16, 0.0)
		upright_instance.material_override = cactus_material
		add_child(upright_instance)
	_add_collision(Vector3(0.8, 1.45, 0.5), Vector3(0.0, 0.725, 0.0))


func _build_stone() -> void:
	var stone_height := 1.0 + float(permanent_detail_seed % 3)
	var stone_width := 0.48 + _seed_fraction(0, 137) * 0.34
	var stone_depth := 0.46 + _seed_fraction(0, 139) * 0.3
	var stone_mesh := BoxMesh.new()
	stone_mesh.size = Vector3(stone_width, stone_height, stone_depth)
	var stone_instance := MeshInstance3D.new()
	stone_instance.mesh = stone_mesh
	stone_instance.position = Vector3(0.0, stone_height * 0.5, 0.0)
	_limestone_material = _limestone_surface_material()
	stone_instance.material_override = _limestone_material
	add_child(stone_instance)
	stone_instance.rotation.y = round(_seed_fraction(0, 149) * 3.0) * PI * 0.5
	_add_collision(Vector3(stone_width, stone_height, stone_depth), Vector3(0.0, stone_height * 0.5, 0.0))


func _limestone_surface_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = LIMESTONE_SHADER
	material.set_shader_parameter("top_color", Palette.SAND_SURFACE)
	material.set_shader_parameter("side_color", Palette.LIMESTONE_SIDE)
	material.set_shader_parameter("daylight", 1.0)
	return material


func _build_bush() -> void:
	_bush_material = _material(_greenery_colour(223), true)
	var lobe_centres: Array[Vector3] = [
		Vector3(_seed_signed(0, 151) * 0.035, 0.36, -0.12 + _seed_signed(0, 153) * 0.025),
		Vector3(-0.29 + _seed_signed(1, 151) * 0.035, 0.31, 0.08 + _seed_signed(1, 153) * 0.035),
		Vector3(0.29 + _seed_signed(2, 151) * 0.035, 0.32, 0.1 + _seed_signed(2, 153) * 0.035),
	]
	for lobe_index in lobe_centres.size():
		var lobe := SphereMesh.new()
		lobe.radius = 0.35 + _seed_signed(lobe_index, 157) * 0.018
		lobe.height = 0.64 + _seed_signed(lobe_index, 163) * 0.035
		lobe.radial_segments = 8
		lobe.rings = 4
		var lobe_instance := MeshInstance3D.new()
		lobe_instance.name = "BushLobe_%d" % lobe_index
		lobe_instance.mesh = lobe
		lobe_instance.position = lobe_centres[lobe_index]
		lobe_instance.material_override = _bush_material
		add_child(lobe_instance)

	_build_batched_berry_dots(lobe_centres)
	_add_collision(Vector3(1.28, 0.7, 0.9), Vector3(0.0, 0.35, 0.02))


func _build_batched_berry_dots(lobe_centres: Array[Vector3]) -> void:
	var berry_quad := QuadMesh.new()
	berry_quad.size = Vector2(0.105, 0.105)
	var berry_material := StandardMaterial3D.new()
	berry_material.albedo_color = Color.WHITE
	berry_material.albedo_texture = _create_berry_dot_texture()
	berry_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	berry_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	berry_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	berry_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	berry_quad.material = berry_material

	var berry_multimesh := MultiMesh.new()
	berry_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	berry_multimesh.mesh = berry_quad
	berry_multimesh.instance_count = 10
	for berry_index in 10:
		var lobe_index := berry_index % lobe_centres.size()
		var berry_angle := _seed_fraction(berry_index, 101) * TAU
		var elevation := -0.12 + _seed_fraction(berry_index, 107) * 1.08
		var horizontal_radius := 0.355
		var berry_position := lobe_centres[lobe_index] + Vector3(
			cos(berry_angle) * cos(elevation) * horizontal_radius,
			sin(elevation) * 0.315,
			sin(berry_angle) * cos(elevation) * horizontal_radius
		)
		berry_multimesh.set_instance_transform(berry_index, Transform3D(Basis.IDENTITY, berry_position))

	_berries_visual = MultiMeshInstance3D.new()
	_berries_visual.name = "BatchedBerryDots"
	_berries_visual.multimesh = berry_multimesh
	_berries_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_berries_visual.visible = _cooldown <= 0.0
	add_child(_berries_visual)


func _create_berry_dot_texture() -> ImageTexture:
	var berry_image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	berry_image.fill(Color.TRANSPARENT)
	for pixel_x in 8:
		for pixel_y in 8:
			var distance_from_centre := Vector2(float(pixel_x) - 3.5, float(pixel_y) - 3.5).length()
			if distance_from_centre <= 3.45:
				berry_image.set_pixel(pixel_x, pixel_y, Palette.WOODEN_ROOF)
	return ImageTexture.create_from_image(berry_image)


func _build_log() -> void:
	# Reuse the same six-sided tapered geometry builder as standing trunks so a
	# dropped Log reads as the removed tree segment rather than a smooth cylinder.
	var log_tool := SurfaceTool.new()
	log_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A loose Log rests level on the ground at its full physical size. Its seeded
	# WorldItem rotation still chooses either cardinal horizontal direction.
	var log_start := Vector3(-LOOSE_LOG_LENGTH * 0.5, WoodVisual.LOG_START_RADIUS, 0.0)
	var log_end := Vector3(LOOSE_LOG_LENGTH * 0.5, WoodVisual.LOG_START_RADIUS, 0.0)
	_append_tapered_cylinder(
		log_tool,
		log_start,
		log_end,
		WoodVisual.LOG_START_RADIUS,
		WoodVisual.LOG_END_RADIUS
	)
	log_tool.generate_normals()
	var log_instance := MeshInstance3D.new()
	log_instance.mesh = log_tool.commit()
	log_instance.material_override = _binary_wood_material(Palette.ROOF_LOG)
	log_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(log_instance)
	_add_collision(Vector3(LOOSE_LOG_LENGTH, 0.28, 0.32), Vector3(0.0, 0.14, 0.0))


func _add_mesh(mesh: Mesh, color: Color, local_position: Vector3, unshaded := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = _material(color, unshaded)
	add_child(instance)
	return instance


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
