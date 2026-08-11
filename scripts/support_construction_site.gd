class_name SupportConstructionSite
extends Node3D

const Palette = preload("res://scripts/game_palette.gd")
const UIText = preload("res://scripts/ui_text_catalog.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")
const BuildingBlueprintScript = preload("res://scripts/building_blueprint.gd")
const BlueprintInstanceScript = preload("res://scripts/building_blueprint_instance.gd")
const BuildingCatalogScript = preload("res://scripts/building_catalog.gd")

const REQUIRED_LOGS := 4
const LOG_INSTALLATION_SECONDS := 3.0
const CORNERS := [
	Vector3(-0.36, 0.0, -0.36),
	Vector3(0.36, 0.0, -0.36),
	Vector3(0.36, 0.0, 0.36),
	Vector3(-0.36, 0.0, 0.36),
]

var delivered_logs := 0
var building_id := "support"
var _assignment_branches: Array[MeshInstance3D] = []
var _planned_posts: Array[MeshInstance3D] = []
var _body: StaticBody3D
var _planning_visible := true
var _reserved_log_contributors: Dictionary = {}
var _installed_resources: Dictionary = {}
var _blueprint: BuildingBlueprint
var _completed_asset: BuildingBlueprintInstance
var _planned_asset: BuildingBlueprintInstance


func configure(next_building_id: String) -> void:
	building_id = next_building_id
	if is_inside_tree():
		_load_blueprint_asset()
		_create_blueprint_visuals()


func _ready() -> void:
	_load_blueprint_asset()
	_create_preview()
	_create_blueprint_visuals()


func needs_log() -> bool:
	return needs_resource("log")


func needs_resource(resource_kind: String) -> bool:
	var recipe := construction_recipe()
	var required := int(recipe.get(resource_kind, 0))
	var installed := int(_installed_resources.get(resource_kind, delivered_logs if resource_kind == "log" else 0))
	var reserved := 0
	for reservation_value in _reserved_log_contributors.values():
		var reservation: Dictionary = reservation_value if reservation_value is Dictionary else {"resource": "log"}
		if str(reservation.get("resource", "log")) == resource_kind:
			reserved += 1
	return installed + reserved < required


func next_required_resource() -> String:
	for resource_kind_value in construction_recipe():
		var resource_kind := str(resource_kind_value)
		if needs_resource(resource_kind):
			return resource_kind
	return ""


func reserve_log(contributor_id: int) -> int:
	return reserve_resource(contributor_id, "log")


func reserve_resource(contributor_id: int, resource_kind: String) -> int:
	if _reserved_log_contributors.has(contributor_id):
		var existing: Variant = _reserved_log_contributors[contributor_id]
		return int(existing.get("slot", -1)) if existing is Dictionary else int(existing)
	if not needs_resource(resource_kind):
		return -1
	var reservation_slot := 0
	var used_slots: Array[int] = []
	for reservation_value in _reserved_log_contributors.values():
		used_slots.append(int(reservation_value.get("slot", -1)) if reservation_value is Dictionary else int(reservation_value))
	while reservation_slot in used_slots:
		reservation_slot += 1
	_reserved_log_contributors[contributor_id] = {"slot": reservation_slot, "resource": resource_kind}
	return reservation_slot


func has_log_reservation(contributor_id: int) -> bool:
	return _reserved_log_contributors.has(contributor_id)


func reserved_resource(contributor_id: int) -> String:
	var reservation: Variant = _reserved_log_contributors.get(contributor_id)
	if reservation is Dictionary:
		return str(reservation.get("resource", "log"))
	return "log" if reservation != null else ""


func release_log_reservation(contributor_id: int) -> void:
	_reserved_log_contributors.erase(contributor_id)


func apply_reserved_log(contributor_id: int) -> bool:
	return apply_reserved_resource(contributor_id)


func apply_reserved_resource(contributor_id: int) -> bool:
	if not has_log_reservation(contributor_id):
		return false
	var resource_kind := reserved_resource(contributor_id)
	_reserved_log_contributors.erase(contributor_id)
	return deliver_resource(resource_kind)


func is_planned() -> bool:
	for resource_kind_value in construction_recipe():
		var resource_kind := str(resource_kind_value)
		if int(_installed_resources.get(resource_kind, delivered_logs if resource_kind == "log" else 0)) < int(construction_recipe()[resource_kind]):
			return true
	return false


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
			planned_post.visible = building_id == "support" and _blueprint == null and (
				_planning_visible
				and is_planned()
				and post_index >= delivered_logs
			)
	if is_instance_valid(_body):
		_body.collision_layer = 1
	_refresh_blueprint_part_visibility()


func deliver_log() -> bool:
	return deliver_resource("log")


func deliver_resource(resource_kind: String) -> bool:
	var recipe := construction_recipe()
	var installed := int(_installed_resources.get(resource_kind, delivered_logs if resource_kind == "log" else 0))
	if installed >= int(recipe.get(resource_kind, 0)):
		return false
	if building_id == "support" and resource_kind == "log" and _blueprint == null:
		_add_support_post(CORNERS[delivered_logs])
	installed += 1
	_installed_resources[resource_kind] = installed
	if resource_kind == "log":
		delivered_logs = installed
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

	if _blueprint == null:
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


func selection_outline_local_boxes() -> Array[AABB]:
	# The Support occupies one World Unit horizontally and three stacked
	# Sub-Units vertically. Planning branches are assignment handles, not part of
	# its physical occupancy, so they intentionally do not enlarge this box.
	return [AABB(Vector3(-0.5, 0.0, -0.5), Vector3.ONE)]


func planned_component_count() -> int:
	var remaining := 0
	for resource_kind_value in construction_recipe():
		var resource_kind := str(resource_kind_value)
		remaining += int(construction_recipe()[resource_kind]) - int(
			_installed_resources.get(resource_kind, delivered_logs if resource_kind == "log" else 0)
		)
	return remaining


func construction_recipe() -> Dictionary:
	if _blueprint != null:
		return _blueprint.recipe()
	return {"log": REQUIRED_LOGS}


func installed_resource_counts() -> Dictionary:
	var installed := _installed_resources.duplicate(true)
	if delivered_logs > 0:
		installed["log"] = delivered_logs
	return installed


func labour_seconds_by_resource() -> Dictionary:
	var result := {}
	for resource_kind_value in construction_recipe():
		result[str(resource_kind_value)] = LOG_INSTALLATION_SECONDS
	return result


func deconstruction_resource_snapshot() -> Dictionary:
	# Only installed Logs belong to the Building. Reserved or carried Logs are
	# returned by the Citizen task-cancellation path instead.
	return installed_resource_counts()


func hover_text() -> String:
	if is_planned() and building_id == "support":
		return UIText.text(
			UIText.SUPPORT_MATERIAL_PROGRESS_TEXT,
			[delivered_logs, REQUIRED_LOGS]
		)
	if is_planned():
		var progress_parts: Array[String] = []
		for resource_kind_value in construction_recipe():
			var resource_kind := str(resource_kind_value)
			progress_parts.append("%s %d/%d" % [
				resource_kind.capitalize(),
				int(installed_resource_counts().get(resource_kind, 0)),
				int(construction_recipe()[resource_kind]),
			])
		return "%s · %s" % [display_name(), " · ".join(progress_parts)]
	return display_name()


func display_name() -> String:
	if building_id == "support":
		return UIText.text(UIText.SUPPORT_NAME_TEXT)
	if _blueprint != null:
		return _blueprint.display_name
	return "Support"


func workshop_recipes() -> Array[Dictionary]:
	return _blueprint.workshop_recipes.duplicate(true) if _blueprint != null else []


func is_workshop() -> bool:
	return not workshop_recipes().is_empty()


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
	box.size = Vector3.ONE
	collision_shape.shape = box
	collision_shape.position.y = 0.5
	_body.add_child(collision_shape)
	add_child(_body)


func _load_blueprint_asset() -> void:
	var definition := BuildingCatalogScript.entry(building_id)
	var asset_path := str(definition.get("asset_path", ""))
	if asset_path.is_empty():
		_blueprint = null
		return
	_blueprint = BuildingBlueprintScript.load_from_file(asset_path)
	if not _blueprint.last_error.is_empty():
		push_error("Unable to load Building asset %s: %s" % [asset_path, _blueprint.last_error])
		_blueprint = null


func _create_blueprint_visuals() -> void:
	if is_instance_valid(_completed_asset):
		_completed_asset.queue_free()
	if is_instance_valid(_planned_asset):
		_planned_asset.queue_free()
	if _blueprint == null:
		return
	_completed_asset = BlueprintInstanceScript.new() as BuildingBlueprintInstance
	_completed_asset.name = "CompletedBuildingAsset"
	_completed_asset.blueprint = _blueprint
	add_child(_completed_asset)
	_planned_asset = BlueprintInstanceScript.new() as BuildingBlueprintInstance
	_planned_asset.name = "PlannedBuildingAsset"
	_planned_asset.blueprint = _blueprint
	_planned_asset.editor_gray_mode = true
	_planned_asset.preview_alpha = 0.5
	add_child(_planned_asset)
	if building_id == "support":
		var completed_index := 1
		for completed_mesh_value in _completed_asset.find_children("*", "MeshInstance3D", true, false):
			(completed_mesh_value as MeshInstance3D).name = "FacetedSupportPost%d" % completed_index
			completed_index += 1
		var planned_index := 1
		for planned_mesh_value in _planned_asset.find_children("*", "MeshInstance3D", true, false):
			(planned_mesh_value as MeshInstance3D).name = "PlannedSupportPost%d" % planned_index
			planned_index += 1
	_refresh_blueprint_part_visibility()


func _refresh_blueprint_part_visibility() -> void:
	if not is_instance_valid(_completed_asset) or not is_instance_valid(_planned_asset):
		return
	var installed_remaining := installed_resource_counts()
	var completed_by_id := {}
	for mesh_value in _completed_asset.find_children("*", "MeshInstance3D", true, false):
		var completed_mesh := mesh_value as MeshInstance3D
		completed_by_id[str(completed_mesh.get_meta("blueprint_part_id", ""))] = completed_mesh
	for planned_mesh_value in _planned_asset.find_children("*", "MeshInstance3D", true, false):
		var planned_mesh := planned_mesh_value as MeshInstance3D
		var part_id := str(planned_mesh.get_meta("blueprint_part_id", ""))
		var resource_kind := str(planned_mesh.get_meta("resource_kind", ""))
		var decorative := bool(planned_mesh.get_meta("decorative", false))
		var installed := decorative or int(installed_remaining.get(resource_kind, 0)) > 0
		if not decorative and installed:
			installed_remaining[resource_kind] = int(installed_remaining.get(resource_kind, 0)) - 1
		var completed_mesh := completed_by_id.get(part_id) as MeshInstance3D
		if is_instance_valid(completed_mesh):
			completed_mesh.visible = installed
		planned_mesh.visible = _planning_visible and is_planned() and not installed and not decorative


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
