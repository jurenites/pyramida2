class_name Citizen
extends Node3D

const Palette = preload("res://scripts/game_palette.gd")
const UIText = preload("res://scripts/ui_text_catalog.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")
const GridNavigationScript = preload("res://scripts/grid_navigation.gd")

signal arrived(citizen: Citizen)

const WALK_SPEED := 2.25
const STRIDE_LENGTH := 0.62
const LEG_LENGTH := 0.78
const WORLD_MOVEMENT_LIMIT := 32.0

var task: Dictionary = {}
var status_text_key := UIText.CITIZEN_IDLE_STATUS_TEXT
var status_text_arguments: Array = []
var visual_variant := "woman"
var _destination := Vector3.ZERO
var _is_walking := false
var _route: Array[Vector3] = []
var _route_preview: Array[Vector3] = []
var _route_index := 0
var _elapsed := 0.0
var _walk_phase := 0.0
var _visual: Node3D
var _carried_log: MeshInstance3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_knee: Node3D
var _right_knee: Node3D
var _left_elbow: Node3D
var _right_elbow: Node3D
var _axe_root: Node3D
var _is_chopping := false
var _chop_progress := 0.0
var _simulation_speed := 1.0


func configure_visual_variant(next_variant: String) -> void:
	visual_variant = next_variant


func set_simulation_speed(next_speed: float) -> void:
	_simulation_speed = maxf(0.0, next_speed)


func _ready() -> void:
	_build_visual()


func assign_task(destination: Vector3, next_task: Dictionary) -> void:
	assign_route(GridNavigationScript.build_direct_route(global_position, destination), next_task)


func assign_route(next_route: Array[Vector3], next_task: Dictionary) -> void:
	_route = next_route.duplicate()
	_route_preview.clear()
	_route_preview.append(global_position)
	_route_preview.append_array(_route)
	_route_index = 0
	_destination = _route[0] if not _route.is_empty() else global_position
	task = next_task
	_is_walking = not _route.is_empty()
	status_text_key = str(task.get("status_text_key", UIText.CITIZEN_WALKING_STATUS_TEXT))
	status_text_arguments = task.get("status_text_arguments", [])
	if not _is_walking:
		arrived.emit(self)


func finish_task(
	next_status_text_key := UIText.CITIZEN_IDLE_STATUS_TEXT,
	next_status_text_arguments: Array = []
) -> void:
	task.clear()
	_is_walking = false
	_route.clear()
	_route_preview.clear()
	_route_index = 0
	status_text_key = next_status_text_key
	status_text_arguments = next_status_text_arguments


func get_status_text() -> String:
	return UIText.text(status_text_key, status_text_arguments)


func speech_anchor_world_position() -> Vector3:
	return global_position + Vector3.UP * 1.88


func speech_actor_kind() -> String:
	return "citizen"


func set_carrying_log(is_carrying: bool) -> void:
	if _carried_log != null:
		_carried_log.visible = is_carrying


func set_chopping(is_chopping: bool, target_position := Vector3.ZERO) -> void:
	_is_chopping = is_chopping
	_chop_progress = 0.0
	if is_instance_valid(_axe_root):
		_axe_root.visible = is_chopping
	if is_chopping:
		var horizontal_target := Vector3(target_position.x, global_position.y, target_position.z)
		if global_position.distance_squared_to(horizontal_target) > 0.001:
			look_at(horizontal_target, Vector3.UP, true)


func set_chop_progress(progress: float) -> void:
	_chop_progress = clampf(progress, 0.0, 1.0)


func is_busy() -> bool:
	return _is_walking or not task.is_empty()


func has_active_route() -> bool:
	return _is_walking


func route_target() -> Vector3:
	return _route[-1] if not _route.is_empty() else global_position


func route_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	if not _is_walking or _route_preview.is_empty():
		return points
	# The visible route begins at the moving Citizen, bends through only the
	# remaining waypoints, and ends at one target dot. Intermediate waypoints do
	# not receive dots or circular caps.
	points.append(global_position)
	for point_index in range(_route_index, _route.size()):
		points.append(_route[point_index])
	return points


func _process(delta: float) -> void:
	_elapsed += delta
	if _is_walking:
		_walk(delta * _simulation_speed)
	elif _is_chopping:
		_animate_chop()
	else:
		_animate_idle()



func _walk(delta: float) -> void:
	var offset := _destination - global_position
	offset.y = 0.0
	var distance := offset.length()
	var maximum_step := WALK_SPEED * delta
	var direction := offset / distance if distance > 0.0 else Vector3.ZERO
	var intended_position := global_position + direction * minf(distance, maximum_step)
	var bounded_position := Vector3(
		clampf(intended_position.x, -WORLD_MOVEMENT_LIMIT, WORLD_MOVEMENT_LIMIT),
		intended_position.y,
		clampf(intended_position.z, -WORLD_MOVEMENT_LIMIT, WORLD_MOVEMENT_LIMIT)
	)
	if not bounded_position.is_equal_approx(intended_position):
		global_position = bounded_position
		_is_walking = false
		_route_index = _route.size()
		_route_preview.clear()
		_animate_idle()
		arrived.emit(self)
		return
	if distance <= maximum_step:
		global_position = intended_position
		_route_index += 1
		if _route_index < _route.size():
			_destination = _route[_route_index]
		else:
			_is_walking = false
			_animate_idle()
			arrived.emit(self)
		return

	global_position = intended_position
	look_at(global_position + direction, Vector3.UP, true)
	_walk_phase += TAU * WALK_SPEED * delta / STRIDE_LENGTH
	_animate_walk()


func _animate_walk() -> void:
	var stride := sin(_walk_phase)
	_left_leg.rotation.x = stride * 0.4
	_right_leg.rotation.x = -stride * 0.4
	_left_arm.rotation.x = -stride * 0.32
	_right_arm.rotation.x = stride * 0.32
	_left_knee.rotation.x = maxf(0.0, -stride) * 0.48
	_right_knee.rotation.x = maxf(0.0, stride) * 0.48
	_left_elbow.rotation.x = 0.1 + maxf(0.0, stride) * 0.2
	_right_elbow.rotation.x = 0.1 + maxf(0.0, -stride) * 0.2
	_visual.position.y = abs(stride) * 0.026


func _animate_idle() -> void:
	var sway := sin(_elapsed * 2.1)
	_left_leg.rotation.x = sway * 0.035
	_right_leg.rotation.x = -sway * 0.035
	_left_arm.rotation.x = -sway * 0.075
	_right_arm.rotation.x = sway * 0.075
	_left_knee.rotation.x = 0.035 + maxf(0.0, sway) * 0.025
	_right_knee.rotation.x = 0.035 + maxf(0.0, -sway) * 0.025
	_left_elbow.rotation.x = 0.1
	_right_elbow.rotation.x = 0.1
	_visual.position.y = sway * 0.018


func _animate_chop() -> void:
	# Three complete raised-to-impact arcs occur during one three-second job.
	var swing_phase := fposmod(_chop_progress * 3.0, 1.0)
	var impact_arc := sin(swing_phase * PI)
	_left_leg.rotation.x = 0.08
	_right_leg.rotation.x = -0.08
	_left_arm.rotation.x = -0.55 + impact_arc * 0.42
	_right_arm.rotation.x = -1.35 + impact_arc * 1.55
	_left_elbow.rotation.x = 0.42
	_right_elbow.rotation.x = 0.25 + impact_arc * 0.75
	_visual.position.y = 0.0


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_build_contact_shadow()

	var body_colour := Palette.CITIZEN_SKIN
	if visual_variant == "woman":
		_build_woman_torso(body_colour)
	else:
		_build_man_torso(body_colour)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.32
	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.position.y = 1.45
	head.material_override = _material(body_colour, true)
	_visual.add_child(head)
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.175
	hair_mesh.height = 0.18
	hair_mesh.radial_segments = 8
	hair_mesh.rings = 3
	var hair := MeshInstance3D.new()
	hair.mesh = hair_mesh
	hair.position = Vector3(0.0, 1.565, 0.0)
	hair.material_override = _material(Palette.HAIR, true)
	_visual.add_child(hair)

	var limb_colour := body_colour
	var left_leg_parts := _create_articulated_limb(Vector3(-0.1, LEG_LENGTH, 0.0), LEG_LENGTH, 0.07, limb_colour, 0.0)
	var right_leg_parts := _create_articulated_limb(Vector3(0.1, LEG_LENGTH, 0.0), LEG_LENGTH, 0.07, limb_colour, 0.0)
	_left_leg = left_leg_parts.get("root") as Node3D
	_right_leg = right_leg_parts.get("root") as Node3D
	_left_knee = left_leg_parts.get("joint") as Node3D
	_right_knee = right_leg_parts.get("joint") as Node3D
	var shoulder_width := 0.195 if visual_variant == "woman" else 0.24
	var left_arm_parts := _create_articulated_limb(Vector3(-shoulder_width, 1.2, 0.0), 0.5, 0.055, limb_colour, 0.14)
	var right_arm_parts := _create_articulated_limb(Vector3(shoulder_width, 1.2, 0.0), 0.5, 0.055, limb_colour, -0.14)
	_left_arm = left_arm_parts.get("root") as Node3D
	_right_arm = right_arm_parts.get("root") as Node3D
	_left_elbow = left_arm_parts.get("joint") as Node3D
	_right_elbow = right_arm_parts.get("joint") as Node3D
	_build_clothing()
	_build_axe()

	var carried_tool := SurfaceTool.new()
	carried_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	WoodVisual.append_tapered_segment(
		carried_tool, Vector3(-0.46, 0.0, 0.0), Vector3(0.46, 0.02, 0.0),
		0.13, 0.1, true, true, 6
	)
	carried_tool.generate_normals()
	_carried_log = MeshInstance3D.new()
	_carried_log.mesh = carried_tool.commit()
	_carried_log.position = Vector3(0.0, 1.0, -0.34)
	_carried_log.material_override = WoodVisual.binary_material(Palette.ROOF_LOG)
	_carried_log.visible = false
	_visual.add_child(_carried_log)

	var collision_body := StaticBody3D.new()
	collision_body.set_meta("world_object", self)
	var collision_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.62
	collision_shape.shape = capsule
	collision_shape.position.y = 0.81
	collision_body.add_child(collision_shape)
	add_child(collision_body)
	# Citizens use the stable contact disc below instead of long dynamic body
	# shadows. This remains readable at sunrise and sunset without stretching.
	for visual_mesh in _visual.find_children("*", "MeshInstance3D", true, false):
		(visual_mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_axe() -> void:
	_axe_root = Node3D.new()
	_axe_root.name = "PocketAxe"
	_axe_root.position = Vector3(0.0, -0.28, 0.0)
	_right_elbow.add_child(_axe_root)
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.026
	handle_mesh.bottom_radius = 0.032
	handle_mesh.height = 0.42
	handle_mesh.radial_segments = 6
	var handle := MeshInstance3D.new()
	handle.mesh = handle_mesh
	handle.position.y = -0.08
	handle.material_override = WoodVisual.binary_material(Palette.ROOF_LOG)
	_axe_root.add_child(handle)
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.22, 0.1, 0.055)
	var axe_head := MeshInstance3D.new()
	axe_head.mesh = head_mesh
	axe_head.position = Vector3(0.065, 0.12, 0.0)
	axe_head.material_override = _material(Palette.FOG_AND_SHADOW, true)
	_axe_root.add_child(axe_head)
	_axe_root.visible = false


func _build_man_torso(body_colour: Color) -> void:
	# A low-poly inverted pear: shoulders wider than the hips.
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.235
	body_mesh.bottom_radius = 0.145
	body_mesh.height = 0.48
	body_mesh.radial_segments = 8
	body_mesh.rings = 1
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.position.y = 1.04
	body.material_override = _material(body_colour, true)
	_visual.add_child(body)


func _build_woman_torso(body_colour: Color) -> void:
	# Three overlapping masses make a symmetric guitar silhouette: broad hips,
	# a narrow waist, and a smaller upper torso. No separate breast geometry is
	# used, avoiding front/back ambiguity when the camera rotates.
	_add_body_ellipsoid(Vector3(0.0, 0.88, 0.0), Vector3(0.235, 0.16, 0.17), body_colour)
	_add_body_ellipsoid(Vector3(0.0, 1.045, 0.0), Vector3(0.135, 0.15, 0.135), body_colour)
	_add_body_ellipsoid(Vector3(0.0, 1.19, 0.0), Vector3(0.19, 0.14, 0.15), body_colour)


func _build_clothing() -> void:
	if visual_variant == "woman":
		var skirt_mesh := CylinderMesh.new()
		skirt_mesh.top_radius = 0.15
		skirt_mesh.bottom_radius = 0.255
		skirt_mesh.height = 0.34
		skirt_mesh.radial_segments = 8
		var skirt := MeshInstance3D.new()
		skirt.mesh = skirt_mesh
		skirt.position.y = 0.82
		skirt.material_override = _material(Palette.WOMAN_CLOTHING, true)
		_visual.add_child(skirt)
	else:
		var shorts_mesh := BoxMesh.new()
		shorts_mesh.size = Vector3(0.34, 0.22, 0.25)
		var shorts := MeshInstance3D.new()
		shorts.mesh = shorts_mesh
		shorts.position.y = 0.79
		shorts.material_override = _material(Palette.HAY_FIELD, true)
		_visual.add_child(shorts)


func _add_body_ellipsoid(local_position: Vector3, radii: Vector3, colour: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var instance := MeshInstance3D.new()
	instance.mesh = sphere
	instance.position = local_position
	instance.scale = radii
	instance.material_override = _material(colour, true)
	_visual.add_child(instance)


func _build_contact_shadow() -> void:
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.23
	shadow_mesh.bottom_radius = 0.23
	shadow_mesh.height = 0.012
	shadow_mesh.radial_segments = 16
	shadow_mesh.rings = 1
	var contact_shadow := MeshInstance3D.new()
	contact_shadow.name = "CitizenContactShadow"
	contact_shadow.mesh = shadow_mesh
	contact_shadow.position.y = 0.018
	contact_shadow.material_override = _material(Palette.FOG_AND_SHADOW.darkened(0.22), true)
	contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(contact_shadow)


func _create_articulated_limb(
	anchor: Vector3,
	length: float,
	radius: float,
	colour: Color,
	base_z_rotation: float
) -> Dictionary:
	var root := Node3D.new()
	root.position = anchor
	root.rotation.z = base_z_rotation
	_visual.add_child(root)
	var upper_length := length * 0.5
	var lower_length := length - upper_length
	_add_limb_segment(root, upper_length, radius, colour)

	var joint := Node3D.new()
	joint.position.y = -upper_length
	root.add_child(joint)
	var joint_mesh := SphereMesh.new()
	joint_mesh.radius = radius * 1.08
	joint_mesh.height = radius * 2.16
	joint_mesh.radial_segments = 6
	joint_mesh.rings = 3
	var joint_instance := MeshInstance3D.new()
	joint_instance.mesh = joint_mesh
	joint_instance.material_override = _material(colour, true)
	joint.add_child(joint_instance)
	_add_limb_segment(joint, lower_length, radius * 0.9, colour)
	return {"root": root, "joint": joint}


func _add_limb_segment(parent: Node3D, length: float, radius: float, colour: Color) -> void:
	var segment_mesh := CylinderMesh.new()
	segment_mesh.top_radius = radius * 0.9
	segment_mesh.bottom_radius = radius
	segment_mesh.height = length
	segment_mesh.radial_segments = 6
	segment_mesh.rings = 1
	var segment := MeshInstance3D.new()
	segment.mesh = segment_mesh
	segment.position.y = -length * 0.5
	segment.material_override = _material(colour, true)
	parent.add_child(segment)


func _material(color: Color, unshaded := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
