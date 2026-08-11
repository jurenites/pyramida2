class_name SupportConstructionSite
extends Node3D

const Palette = preload("res://scripts/game_palette.gd")
const UIText = preload("res://scripts/ui_text_catalog.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")

const REQUIRED_LOGS := 4
const LOG_INSTALLATION_SECONDS := 3.0
const CORNERS := [
	Vector3(-0.36, 0.0, -0.36),
	Vector3(0.36, 0.0, -0.36),
	Vector3(0.36, 0.0, 0.36),
	Vector3(-0.36, 0.0, 0.36),
]

var delivered_logs := 0
var _assignment_branches: Array[MeshInstance3D] = []
var _planned_posts: Array[MeshInstance3D] = []
var _body: StaticBody3D
var _planning_visible := true
var _reserved_log_contributors: Dictionary = {}


func _ready() -> void:
	_create_preview()


func needs_log() -> bool:
	return delivered_logs + _reserved_log_contributors.size() < REQUIRED_LOGS


func reserve_log(contributor_id: int) -> int:
	if _reserved_log_contributors.has(contributor_id):
		return int(_reserved_log_contributors[contributor_id])
	if not needs_log():
		return -1
	var reservation_slot := 0
	var used_slots := _reserved_log_contributors.values()
	while used_slots.has(reservation_slot):
		reservation_slot += 1
	_reserved_log_contributors[contributor_id] = reservation_slot
	return reservation_slot


func has_log_reservation(contributor_id: int) -> bool:
	return _reserved_log_contributors.has(contributor_id)


func release_log_reservation(contributor_id: int) -> void:
	_reserved_log_contributors.erase(contributor_id)


func apply_reserved_log(contributor_id: int) -> bool:
	if not has_log_reservation(contributor_id):
		return false
	_reserved_log_contributors.erase(contributor_id)
	return deliver_log()


func is_planned() -> bool:
	return delivered_logs < REQUIRED_LOGS


func is_complete() -> bool:
	return not is_planned()


func set_planning_visible(planning_is_visible: bool) -> void:
	_planning_visible = planning_is_visible
	# The four footprint branches are permanent physical assignment handles.
	# They appear as soon as the site exists, independently of Build Mode.
	for branch in _assignment_branches:
		if is_instance_valid(branch):
			branch.visible = is_planned()
	for post_index in _planned_posts.size():
		var planned_post := _planned_posts[post_index]
		if is_instance_valid(planned_post):
			planned_post.visible = (
				_planning_visible
				and is_planned()
				and post_index >= delivered_logs
			)
	if is_instance_valid(_body):
		_body.collision_layer = 1


func deliver_log() -> bool:
	if delivered_logs >= REQUIRED_LOGS:
		return false
	_add_support_post(CORNERS[delivered_logs])
	delivered_logs += 1
	set_planning_visible(_planning_visible)
	return true


func _create_preview() -> void:
	for corner_index in CORNERS.size():
		var corner: Vector3 = CORNERS[corner_index]
		var outward := Vector3(corner.x, 0.0, corner.z).normalized()
		var branch_base := outward * 0.74 + Vector3.UP * 0.025
		var branch_tip := outward * 0.88 + Vector3.UP * 0.34
		var branch_tool := SurfaceTool.new()
		branch_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		WoodVisual.append_tapered_segment(
			branch_tool,
			branch_base,
			branch_tip,
			0.055,
			0.032,
			true,
			true,
			4
		)
		branch_tool.generate_normals()
		var branch := MeshInstance3D.new()
		branch.name = "AssignmentBranch%d" % (corner_index + 1)
		branch.mesh = branch_tool.commit()
		branch.material_override = WoodVisual.binary_material(Palette.ROOF_LOG)
		branch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(branch)
		_assignment_branches.append(branch)

	var planned_material := StandardMaterial3D.new()
	planned_material.albedo_color = Color(
		Palette.PLACEMENT_ALLOWED.r,
		Palette.PLACEMENT_ALLOWED.g,
		Palette.PLACEMENT_ALLOWED.b,
		0.5
	)
	planned_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	planned_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	planned_material.roughness = 1.0
	for post_index in CORNERS.size():
		var planned_post := MeshInstance3D.new()
		planned_post.name = "PlannedSupportPost%d" % (post_index + 1)
		planned_post.mesh = _support_post_mesh(CORNERS[post_index], post_index)
		planned_post.material_override = planned_material
		planned_post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(planned_post)
		_planned_posts.append(planned_post)

	_create_collision()
	set_planning_visible(_planning_visible)


func speech_anchor_world_position() -> Vector3:
	return global_position + Vector3.UP * 1.55


func speech_actor_kind() -> String:
	return "building"


func planned_component_count() -> int:
	return REQUIRED_LOGS - delivered_logs


func construction_recipe() -> Dictionary:
	return {"log": REQUIRED_LOGS}


func installed_resource_counts() -> Dictionary:
	return {"log": delivered_logs}


func labour_seconds_by_resource() -> Dictionary:
	return {"log": LOG_INSTALLATION_SECONDS}


func deconstruction_resource_snapshot() -> Dictionary:
	# Only installed Logs belong to the Building. Reserved or carried Logs are
	# returned by the Citizen task-cancellation path instead.
	return {"log": delivered_logs} if delivered_logs > 0 else {}


func hover_text() -> String:
	if is_planned():
		return UIText.text(
			UIText.SUPPORT_MATERIAL_PROGRESS_TEXT,
			[delivered_logs, REQUIRED_LOGS]
		)
	return UIText.text(UIText.SUPPORT_NAME_TEXT)


func _add_support_post(corner: Vector3) -> void:
	var post_index := delivered_logs
	var post := MeshInstance3D.new()
	post.name = "FacetedSupportPost%d" % (post_index + 1)
	post.mesh = _support_post_mesh(corner, post_index)
	post.material_override = WoodVisual.binary_material(Palette.ROOF_LOG)
	post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(post)


func _support_post_mesh(corner: Vector3, post_index: int) -> ArrayMesh:
	var post_tool := SurfaceTool.new()
	post_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var post_end := corner + Vector3(
		0.025 if post_index % 2 == 0 else -0.018,
		1.25,
		-0.02 if post_index < 2 else 0.024
	)
	WoodVisual.append_tapered_segment(
		post_tool,
		corner + Vector3.UP * 0.025,
		post_end,
		0.13,
		0.09,
		true,
		true,
		6
	)
	post_tool.generate_normals()
	return post_tool.commit()


func _create_collision() -> void:
	_body = StaticBody3D.new()
	_body.set_meta("world_object", self)
	var collision_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.3, 1.0)
	collision_shape.shape = box
	collision_shape.position.y = 0.65
	_body.add_child(collision_shape)
	add_child(_body)


func _add_mesh(mesh: Mesh, color: Color, local_position: Vector3, unshaded: bool) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = local_position
	instance.material_override = material
	add_child(instance)
	return instance
