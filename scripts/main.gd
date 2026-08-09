extends Node3D

const Palette = preload("res://scripts/game_palette.gd")
const GrassRendererScript = preload("res://scripts/grass_renderer.gd")
const UIText = preload("res://scripts/ui_text_catalog.gd")
const MessageCatalog = preload("res://scripts/actor_message_catalog.gd")
const ActionCatalog = preload("res://scripts/gameplay_action_catalog.gd")
const ActorMessageBusScript = preload("res://scripts/actor_message_bus.gd")
const SpeechBubbleOverlayScript = preload("res://scripts/speech_bubble_overlay.gd")
const PixelUI = preload("res://scripts/pixel_ui.gd")
const BuildInfo = preload("res://scripts/build_info.gd")
const ExcavationSiteScript = preload("res://scripts/excavation_site.gd")
const DeterministicRandomScript = preload("res://scripts/deterministic_random.gd")
const GridNavigationScript = preload("res://scripts/grid_navigation.gd")
const AppliedLabourScript = preload("res://scripts/applied_labour.gd")
const LabourProgressBarScript = preload("res://scripts/labour_progress_bar.gd")
const WORLD_HALF_EXTENT := 32.0
const BACKGROUND_HALF_EXTENT := 128.0
const FOG_CELL_SIZE := 0.5
const FOG_MASK_RESOLUTION := 128
const REVEAL_RADIUS := 4.0
const CAMERA_OFFSET := Vector3(12.0, 14.0, 12.0)
const CAMERA_PAN_SPEED := 8.0
const CAMERA_FOCUS_LIMIT := WORLD_HALF_EXTENT - 1.0
const CAMERA_ROTATION_SENSITIVITY := 0.008
const CAMERA_TILT_LIMIT := 0.174532925
const DEFAULT_CAMERA_YAW := PI * 0.25
const DEFAULT_CAMERA_PITCH := 0.689775
const CAMERA_DISTANCE := 22.0
const CAMERA_MINIMUM_SIZE := 17.0
const DEFAULT_CAMERA_SIZE := 34.0
const CAMERA_MAXIMUM_SIZE := 48.0
const CAMERA_ZOOM_STEP := 2.0
const SELECTION_DRAG_THRESHOLD := 6.0
const PIXEL_BLOCK_SIZE := 2.0
const SHOW_DEBUG_OVERLAY := false
const HOVER_REFRESH_INTERVAL := 0.08
const HOVER_DELAY_SECONDS := 0.25
const HOVER_FADE_SPEED := 5.0
const DAY_LENGTH_SECONDS := 360.0
const SIMULATION_SPEED_OPTIONS := [1.0, 2.0, 4.0]
const TREE_CUT_WORK_SECONDS := 3.0
const EXCAVATION_WORK_SECONDS := 3.0
const RESOURCE_WORK_SECONDS := 3.0
const UI_OUTLINE_PIXELS := 2.0
const CITIZEN_PATH_LINE_WIDTH_PIXELS := 2.0
const CITIZEN_SELECTION_LINE_WIDTH_PIXELS := 2.0
const CITIZEN_SELECTION_RADIUS_WORLD := 0.3168
const CITIZEN_SELECTION_POINT_COUNT := 16
const BUILDING_ICON_STROKE_PIXELS := 2.0
const COMPASS_DIAMETER_PIXELS := 72
const ONBOARDING_STATE_PATH := "user://onboarding.cfg"

var _camera: Camera3D
var _sun: DirectionalLight3D
var _environment: Environment
var _ground_material: ShaderMaterial
var _path_line: MultiMeshInstance3D
var _path_mesh: BoxMesh
var _path_multimesh: MultiMesh
var _path_joint_line: MultiMeshInstance3D
var _path_joint_mesh: CylinderMesh
var _path_joint_multimesh: MultiMesh
var _path_overlay_layer: CanvasLayer
var _path_screen_lines: Array[Line2D] = []
var _path_screen_targets: Array[Polygon2D] = []
var _citizen_selection_screen_lines: Array[Line2D] = []
var _selected_world_object: Node3D
var _selection_outline_root: MultiMeshInstance3D
var _selection_outline_mesh: BoxMesh
var _selected_ground_cell := Vector2i.ZERO
var _has_selected_ground_cell := false
var _fog_image: Image
var _fog_texture: ImageTexture
var _fog_instance: MeshInstance3D
var _fog_material: ShaderMaterial
var _grass_renderer: Node3D
var _revealed_fog_cells: Dictionary = {}
var _occupied_bush_world_units: Dictionary = {}
var _occupied_static_world_units: Dictionary = {}
var _selected_citizen: Citizen
var _selected_citizens: Array[Citizen] = []
var _citizens: Array[Citizen] = []
var _items: Array[WorldItem] = []
var _construction_sites: Array[SupportConstructionSite] = []
var _excavation_sites: Array[ExcavationSite] = []
var _excavated_cells: Dictionary = {}
var _build_mode := false
var _placing_support := false
var _placing_excavation := false
var _selected_building: SupportConstructionSite
var _support_placement_preview: SupportConstructionSite
var _calories := 0
var _water := 0
var _ui_status: Label
var _ui_resources: Label
var _ui_mode: Label
var _selection_box: Panel
var _rts_count_badge: Label
var _goods_count_badge: Label
var _toolbar_tooltip: PanelContainer
var _toolbar_tooltip_label: Label
var _top_toolbar: HBoxContainer
var _population_count_label: Label
var _building_button: Button
var _simulation_speed_button: Button
var _deconstruct_button: Button
var _build_menu: PanelContainer
var _hover_tooltip: Label
var _cursor_texture: ImageTexture
var _hover_refresh_remaining := 0.0
var _debug_hover_enabled := false
var _hover_candidate_key := ""
var _hover_stable_elapsed := 0.0
var _hover_target_visible := false
var _hover_alpha := 0.0
var _hover_last_mouse_position := Vector2(-1000.0, -1000.0)
var _day_label: Label
var _build_stamp_label: Label
var _building_hotkey_hint: PanelContainer
var _building_hotkey_hint_label: Label
var _building_rotation_tween: Tween
var _day_night_wheel: TextureRect
var _world_progress_layer: CanvasLayer
var _active_work: Dictionary = {}
var _labour_records: Dictionary = {}
var _actor_message_bus: ActorMessageBus
var _speech_bubble_overlay: SpeechBubbleOverlay
var _speech_command_sequence := 0
var _onboarding_layer: CanvasLayer
var _selection_press_active := false
var _selection_drag_start := Vector2.ZERO
var _selection_drag_current := Vector2.ZERO
var _camera_focus := Vector3.ZERO
var _camera_yaw := DEFAULT_CAMERA_YAW
var _camera_pitch := DEFAULT_CAMERA_PITCH
var _camera_size := DEFAULT_CAMERA_SIZE
var _right_drag_active := false
var _right_dragged := false
var _right_drag_start := Vector2.ZERO
var _right_drag_last := Vector2.ZERO
var _clouds_root: Node3D
var _cloud_velocities: Dictionary = {}
var _cloud_shadow_offset := Vector2.ZERO
var _compass_viewport: SubViewport
var _compass_camera: Camera3D
var _compass_glass: MeshInstance3D
var _compass_glass_mesh: QuadMesh
var _compass_hover_outline: MeshInstance3D
var _elapsed := 0.0
var _simulation_speed := 1.0


func _ready() -> void:
	_create_environment()
	_create_ground()
	_create_camera()
	_create_clouds()
	_create_path_preview()
	_create_interface()
	_create_actor_speech_system()
	_create_custom_cursor()
	_create_first_launch_onboarding()
	_create_pixel_filter()
	_seed_world()
	_create_grass_renderer()
	_create_fog_of_war()
	_apply_pixel_font_to_controls(self)
	_update_interface()


func _process(delta: float) -> void:
	var simulation_delta := delta * _simulation_speed
	_elapsed += simulation_delta
	_update_day_night()
	_update_camera_pan(delta)
	_update_clouds(simulation_delta)
	_hover_refresh_remaining -= delta
	if _hover_refresh_remaining <= 0.0:
		_hover_refresh_remaining = HOVER_REFRESH_INTERVAL
		_update_hover_tooltip()
	_update_hover_transition(delta)
	_update_world_selection_outline()
	_update_building_hotkey_hint()
	_update_support_placement_preview()
	if is_instance_valid(_grass_renderer):
		_grass_renderer.update_viewer_position(_camera_focus)
	_reveal_world_around_citizens()
	_update_path_preview()
	_update_labour(simulation_delta)
	_update_interface()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_key_input(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)


func _handle_key_input(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_F1:
		_show_onboarding()
		return
	if is_instance_valid(_onboarding_layer) and _onboarding_layer.visible:
		_complete_onboarding()
		return
	match event.keycode:
		KEY_BACKSPACE:
			_try_delete_selected_object()
		KEY_R:
			_rotate_selected_building(-1 if event.shift_pressed else 1)
		KEY_F3:
			_debug_hover_enabled = not _debug_hover_enabled
			_update_hover_tooltip()
		KEY_B:
			_toggle_build_menu()
		KEY_ESCAPE:
			if is_instance_valid(_build_menu) and _build_menu.visible:
				_build_menu.visible = false
			else:
				_leave_build_mode()
		_:
			pass


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _right_drag_active:
		var drag_delta: Vector2 = event.position - _right_drag_last
		_right_drag_last = event.position
		if _right_drag_start.distance_to(event.position) >= SELECTION_DRAG_THRESHOLD:
			_right_dragged = true
		_camera_yaw -= drag_delta.x * CAMERA_ROTATION_SENSITIVITY
		_camera_pitch = clampf(
			_camera_pitch - drag_delta.y * CAMERA_ROTATION_SENSITIVITY,
			DEFAULT_CAMERA_PITCH - CAMERA_TILT_LIMIT,
			DEFAULT_CAMERA_PITCH + CAMERA_TILT_LIMIT
		)
		_update_camera_transform()
	elif _selection_press_active:
		_selection_drag_current = event.position
		_update_selection_box()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_adjust_camera_zoom(-CAMERA_ZOOM_STEP)
		return
	if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_adjust_camera_zoom(CAMERA_ZOOM_STEP)
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_selection_drag(event.position)
		else:
			_finish_selection_drag(event.position, event.alt_pressed, event.ctrl_pressed)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_mouse_button(event)


func _handle_right_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		_right_drag_active = true
		_right_dragged = false
		_right_drag_start = event.position
		_right_drag_last = event.position
		return
	_right_drag_active = false
	if _right_dragged:
		return
	if _build_mode:
		_leave_build_mode()
	else:
		_handle_command_order(event.position)


func _handle_world_click(screen_position: Vector2, exact_selection := false, keep_placing := false) -> void:
	if not _placing_support and not exact_selection:
		var priority_citizen := _citizen_at_screen_point(screen_position)
		if priority_citizen != null:
			_select_only(priority_citizen)
			priority_citizen.status_text_key = UIText.CITIZEN_SELECTED_STATUS_TEXT
			priority_citizen.status_text_arguments.clear()
			return

	var hit: Dictionary = _raycast(screen_position)
	if hit.is_empty():
		if not _build_mode:
			_set_selected_citizens([])
			_clear_object_selection()
		return
	var collider: Node = hit.get("collider") as Node
	var world_object: Variant = _world_object_for(collider)

	if _placing_support:
		if collider != null and collider.get_meta("world_kind", "") == "ground":
			var construction_site_position := _snap_to_world_unit(hit.position)
			if (
				_is_inside_playable_world(construction_site_position)
				and not _excavated_cells.has(_world_unit_cell(construction_site_position))
			):
				_place_support_construction_site(construction_site_position, keep_placing)
		return
	if _placing_excavation:
		if collider != null and collider.get_meta("world_kind", "") == "ground":
			_place_excavation_site(_world_unit_cell(hit.position), keep_placing)
		return

	if world_object is SupportConstructionSite:
		_select_building(world_object as SupportConstructionSite)
		return
	if world_object is ExcavationSite:
		_set_selected_citizens([])
		_select_world_object(world_object as ExcavationSite)
		return

	if world_object is Citizen:
		_select_only(world_object)
		(world_object as Citizen).status_text_key = UIText.CITIZEN_SELECTED_STATUS_TEXT
		(world_object as Citizen).status_text_arguments.clear()
		return

	if world_object is WorldItem:
		_select_world_object(world_object as Node3D)
		return

	if collider != null and collider.get_meta("world_kind", "") == "ground":
		_set_selected_citizens([])
		_leave_build_mode()
		_select_ground_tile(hit.position)



func _handle_command_order(screen_position: Vector2) -> void:
	if _selected_citizens.is_empty():
		return
	var hit: Dictionary = _raycast(screen_position)
	if hit.is_empty():
		return
	var collider: Node = hit.get("collider") as Node
	var world_object: Variant = _world_object_for(collider)
	var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
	# Fog takes priority over every contextual command. Hidden objects retain
	# collision for navigation, but clicking one must never reveal its identity
	# by assigning work. Discovery also does not mutate this MOVE task later.
	var command_is_revealed := _is_world_position_revealed(hit_position)
	if world_object is Node3D:
		command_is_revealed = command_is_revealed and _is_world_position_revealed(
			(world_object as Node3D).global_position
		)
	if not command_is_revealed:
		_issue_group_move(hit_position)
		return
	if world_object is SupportConstructionSite:
		_continue_build(_selected_citizen, world_object as SupportConstructionSite)
		return
	if world_object is ExcavationSite:
		_order_excavate(_selected_citizen, world_object as ExcavationSite)
		return
	if world_object is WorldItem:
		var item := world_object as WorldItem
		if item.item_kind in ["tree", "dead_tree", "palm_tree"]:
			_order_group_chop(item)
		elif item.item_kind == "bush":
			_order_harvest(_selected_citizen, item)
		elif item.item_kind == "cactus":
			_order_collect_cactus(_selected_citizen, item)
		return
	if collider != null and collider.get_meta("world_kind", "") == "ground":
		_issue_group_move(hit_position)


func _issue_group_move(world_target: Vector3) -> void:
	if _selected_citizens.is_empty():
		return
	var target_cell := _world_unit_cell(world_target)
	var citizen_count := _selected_citizens.size()
	for citizen_index in citizen_count:
		var citizen := _selected_citizens[citizen_index]
		if not is_instance_valid(citizen):
			continue
		# Every selected Citizen converges into the clicked World Unit. Separate
		# compact slots prevent overlap without preserving a parallel formation.
		var target_offset := _group_target_offset(citizen_index, citizen_count)
		var citizen_target := Vector3(
			float(target_cell.x) + 0.5 + target_offset.x,
			0.0,
			float(target_cell.y) + 0.5 + target_offset.y
		)
		_assign_group_navigation_task(citizen, citizen_target, target_offset)
		# Movement is confirmed by the selected Citizen's outlined contact shadow and
		# route preview. Movement orders deliberately produce no speech bubble.


func _group_target_offset(citizen_index: int, citizen_count: int) -> Vector2:
	if citizen_count <= 1:
		return Vector2.ZERO
	var column_count := mini(3, ceili(sqrt(float(citizen_count))))
	var row_count := ceili(float(citizen_count) / float(column_count))
	var spacing := 0.5 if maxi(column_count, row_count) <= 2 else 0.32
	var column := citizen_index % column_count
	var row := citizen_index / column_count
	return Vector2(
		(float(column) - float(column_count - 1) * 0.5) * spacing,
		(float(row) - float(row_count - 1) * 0.5) * spacing
	)


func _assign_group_navigation_task(
	citizen: Citizen,
	target_position: Vector3,
	lane_offset: Vector2
) -> bool:
	_cancel_active_work(citizen)
	target_position = _clamp_to_playable_world(target_position)
	var route := _build_navigation_route(citizen.global_position, target_position, false)
	if route.is_empty():
		citizen.finish_task(UIText.CITIZEN_NO_ROUTE_STATUS_TEXT)
		return false
	# A* owns the World-Unit sequence. The compact lane offset is applied to its
	# intermediate centres so group members do not walk through one coordinate.
	for route_index in maxi(0, route.size() - 1):
		var route_point := route[route_index]
		route[route_index] = _clamp_to_playable_world(Vector3(
			route_point.x + lane_offset.x,
			route_point.y,
			route_point.z + lane_offset.y
		))
	citizen.assign_route(
		route,
		{"kind": ActionCatalog.MOVE, "status_text_key": UIText.CITIZEN_WALKING_STATUS_TEXT}
	)
	return true


func _begin_selection_drag(screen_position: Vector2) -> void:
	_selection_press_active = true
	_selection_drag_start = screen_position
	_selection_drag_current = screen_position
	if _selection_box != null:
		_selection_box.visible = false


func _finish_selection_drag(screen_position: Vector2, exact_selection := false, keep_placing := false) -> void:
	if not _selection_press_active:
		return
	_selection_drag_current = screen_position
	_selection_press_active = false
	var drag_distance := _selection_drag_start.distance_to(_selection_drag_current)
	if _selection_box != null:
		_selection_box.visible = false
	if drag_distance >= SELECTION_DRAG_THRESHOLD and not _build_mode:
		_select_citizens_in_screen_rect(_selection_screen_rect())
	else:
		_handle_world_click(screen_position, exact_selection, keep_placing)


func _update_selection_box() -> void:
	if _selection_box == null:
		return
	if _selection_drag_start.distance_to(_selection_drag_current) < SELECTION_DRAG_THRESHOLD:
		_selection_box.visible = false
		return
	var selection_rect := _selection_screen_rect()
	_selection_box.position = selection_rect.position
	_selection_box.size = selection_rect.size
	_selection_box.visible = not _build_mode


func _selection_screen_rect() -> Rect2:
	var minimum := Vector2(
		minf(_selection_drag_start.x, _selection_drag_current.x),
		minf(_selection_drag_start.y, _selection_drag_current.y)
	)
	var maximum := Vector2(
		maxf(_selection_drag_start.x, _selection_drag_current.x),
		maxf(_selection_drag_start.y, _selection_drag_current.y)
	)
	return Rect2(minimum, maximum - minimum)


func _select_citizens_in_screen_rect(selection_rect: Rect2) -> void:
	var next_selection: Array[Citizen] = []
	for citizen in _citizens:
		if not is_instance_valid(citizen):
			continue
		var selection_point := citizen.global_position + Vector3.UP * 0.8
		if _camera.is_position_behind(selection_point):
			continue
		if selection_rect.has_point(_camera.unproject_position(selection_point)):
			next_selection.append(citizen)
	_set_selected_citizens(next_selection)


func _citizen_at_screen_point(screen_position: Vector2) -> Citizen:
	var closest: Citizen
	var closest_distance := 24.0
	for citizen in _citizens:
		if not is_instance_valid(citizen):
			continue
		var selection_point := citizen.global_position + Vector3.UP * 0.8
		if _camera.is_position_behind(selection_point):
			continue
		var screen_distance := screen_position.distance_to(_camera.unproject_position(selection_point))
		if screen_distance < closest_distance:
			closest = citizen
			closest_distance = screen_distance
	return closest


func _set_selected_citizens(next_selection: Array[Citizen]) -> void:
	_selected_citizens = next_selection.duplicate()
	_selected_citizen = _selected_citizens[0] if not _selected_citizens.is_empty() else null
	if not _selected_citizens.is_empty():
		_clear_object_selection()
		_build_mode = false
		_placing_support = false
		_placing_excavation = false
		_selected_building = null
		if is_instance_valid(_build_menu):
			_build_menu.visible = false
		_refresh_planned_building_visibility()


func _select_only(citizen: Citizen) -> void:
	var next_selection: Array[Citizen] = [citizen]
	_set_selected_citizens(next_selection)


func _select_building(building: SupportConstructionSite) -> void:
	_set_selected_citizens([])
	_selected_building = building
	_select_world_object(building)
	_build_mode = true
	_placing_support = false
	_placing_excavation = false
	if is_instance_valid(_build_menu):
		_build_menu.visible = true
	_refresh_planned_building_visibility()


func _enter_build_mode(place_support: bool) -> void:
	_set_selected_citizens([])
	_clear_object_selection()
	_selected_building = null
	_build_mode = true
	_placing_support = place_support
	_placing_excavation = false
	if is_instance_valid(_build_menu):
		_build_menu.visible = true
	_refresh_planned_building_visibility()


func _leave_build_mode() -> void:
	_build_mode = false
	_placing_support = false
	_placing_excavation = false
	_selected_building = null
	if is_instance_valid(_build_menu):
		_build_menu.visible = false
	_clear_object_selection()
	_refresh_planned_building_visibility()


func _enter_excavation_mode() -> void:
	_set_selected_citizens([])
	_clear_object_selection()
	_selected_building = null
	_build_mode = true
	_placing_support = false
	_placing_excavation = true
	if is_instance_valid(_build_menu):
		_build_menu.visible = true
	_refresh_planned_building_visibility()


func _select_world_object(world_object: Node3D) -> void:
	_selected_world_object = world_object
	_has_selected_ground_cell = false
	if not is_instance_valid(_selection_outline_root):
		_create_world_selection_outline()
	_update_world_selection_outline()


func _select_ground_tile(world_position: Vector3) -> void:
	_selected_world_object = null
	_selected_ground_cell = _world_unit_cell(world_position)
	_has_selected_ground_cell = true
	if not is_instance_valid(_selection_outline_root):
		_create_world_selection_outline()
	_update_world_selection_outline()


func _clear_object_selection() -> void:
	_selected_world_object = null
	_has_selected_ground_cell = false
	if is_instance_valid(_selection_outline_root):
		_selection_outline_root.visible = false


func _try_delete_selected_object() -> void:
	if not is_instance_valid(_selected_world_object):
		return
	if _selected_world_object is SupportConstructionSite:
		var support := _selected_world_object as SupportConstructionSite
		_construction_sites.erase(support)
		if _selected_building == support:
			_selected_building = null
			_build_mode = false
			_placing_support = false
		_clear_object_selection()
		_collapse_world_object(support)
		_refresh_planned_building_visibility()
		return
	if _selected_world_object is ExcavationSite:
		var excavation_site := _selected_world_object as ExcavationSite
		_excavation_sites.erase(excavation_site)
		_clear_object_selection()
		_collapse_world_object(excavation_site)
		return
	# Naturally generated resources require Citizen work; Backspace only gives
	# refusal feedback and never bypasses that work.
	if _selected_world_object is WorldItem:
		_shake_world_object(_selected_world_object)


func _rotate_selected_building(direction: int) -> void:
	if (
		not is_instance_valid(_selected_building)
		or _selected_world_object != _selected_building
	):
		return
	var rotation_quarters := int(_selected_building.get_meta(
		"rotation_quarters",
		roundi(_selected_building.rotation.y / (PI * 0.5))
	))
	rotation_quarters += direction
	_selected_building.set_meta("rotation_quarters", rotation_quarters)
	if _building_rotation_tween != null and _building_rotation_tween.is_valid():
		_building_rotation_tween.kill()
	_building_rotation_tween = create_tween()
	_building_rotation_tween.tween_property(
		_selected_building,
		"rotation:y",
		float(rotation_quarters) * PI * 0.5,
		0.16
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _collapse_world_object(world_object: Node3D) -> void:
	var original_position := world_object.position
	var collapse_tween := create_tween()
	collapse_tween.set_parallel(true)
	collapse_tween.tween_property(world_object, "scale", Vector3(1.08, 0.04, 1.08), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse_tween.tween_property(world_object, "position", original_position - Vector3.UP * 0.18, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse_tween.chain().tween_callback(world_object.queue_free)


func _shake_world_object(world_object: Node3D) -> void:
	var original_position := world_object.position
	var shake_tween := create_tween()
	shake_tween.tween_property(world_object, "position", original_position + Vector3(0.07, 0.0, 0.0), 0.045)
	shake_tween.tween_property(world_object, "position", original_position - Vector3(0.07, 0.0, 0.0), 0.07)
	shake_tween.tween_property(world_object, "position", original_position + Vector3(0.04, 0.0, 0.0), 0.06)
	shake_tween.tween_property(world_object, "position", original_position, 0.045)


func _create_world_selection_outline() -> void:
	_selection_outline_mesh = BoxMesh.new()
	_selection_outline_mesh.size = Vector3(0.035, 0.035, 1.0)
	var outline_multimesh := MultiMesh.new()
	outline_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	outline_multimesh.mesh = _selection_outline_mesh
	_selection_outline_root = MultiMeshInstance3D.new()
	_selection_outline_root.name = "SelectedWorldOutline"
	_selection_outline_root.multimesh = outline_multimesh
	var outline_material := _material(Color.WHITE)
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.no_depth_test = true
	outline_material.render_priority = 2
	_selection_outline_root.material_override = outline_material
	_selection_outline_root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_selection_outline_root)


func _update_world_selection_outline() -> void:
	if not is_instance_valid(_selection_outline_root):
		return
	if _has_selected_ground_cell:
		_update_ground_selection_outline()
		return
	if not is_instance_valid(_selected_world_object) or not _selected_world_object.visible:
		_selection_outline_root.visible = false
		return
	var bounds := _world_visual_bounds(_selected_world_object).grow(0.045)
	# Grounded objects should read as wrapped from the visible surface upward,
	# rather than drawing the lower face beneath Sand.
	if bounds.position.y < 0.065 and bounds.end.y > 0.065:
		var visible_height := bounds.end.y - 0.065
		bounds.position.y = 0.065
		bounds.size.y = visible_height
	var minimum := bounds.position
	var maximum := bounds.end
	var transforms: Array[Transform3D] = []
	for y_value in [minimum.y, maximum.y]:
		transforms.append(_box_segment_transform(
			Vector3(minimum.x, y_value, minimum.z), Vector3(maximum.x, y_value, minimum.z)
		))
		transforms.append(_box_segment_transform(
			Vector3(maximum.x, y_value, minimum.z), Vector3(maximum.x, y_value, maximum.z)
		))
		transforms.append(_box_segment_transform(
			Vector3(maximum.x, y_value, maximum.z), Vector3(minimum.x, y_value, maximum.z)
		))
		transforms.append(_box_segment_transform(
			Vector3(minimum.x, y_value, maximum.z), Vector3(minimum.x, y_value, minimum.z)
		))
	# Keep the upper and lower frames visually separate. Vertical connectors are
	# intentionally hidden for now so tall Trees do not read as a wireframe cage.
	_apply_selection_outline_transforms(transforms, bounds.get_center())


func _update_ground_selection_outline() -> void:
	# Sit above the 0.025 fog plane with enough separation to avoid depth loss
	# while remaining visually attached to the selected surface tile.
	var cell_origin := Vector3(float(_selected_ground_cell.x), 0.065, float(_selected_ground_cell.y))
	var corner_a := cell_origin
	var corner_b := cell_origin + Vector3(1.0, 0.0, 0.0)
	var corner_c := cell_origin + Vector3(1.0, 0.0, 1.0)
	var corner_d := cell_origin + Vector3(0.0, 0.0, 1.0)
	var transforms: Array[Transform3D] = []
	transforms.append(_box_segment_transform(corner_a, corner_b))
	transforms.append(_box_segment_transform(corner_b, corner_c))
	transforms.append(_box_segment_transform(corner_c, corner_d))
	transforms.append(_box_segment_transform(corner_d, corner_a))
	_apply_selection_outline_transforms(
		transforms,
		cell_origin + Vector3(0.5, 0.0, 0.5)
	)


func _apply_selection_outline_transforms(
	transforms: Array[Transform3D],
	selection_centre: Vector3
) -> void:
	_selection_outline_mesh.size = Vector3(
		_selection_world_line_width(selection_centre),
		_selection_world_line_width(selection_centre),
		1.0
	)
	var multimesh := _selection_outline_root.multimesh
	multimesh.instance_count = transforms.size()
	for transform_index in transforms.size():
		multimesh.set_instance_transform(transform_index, transforms[transform_index])
	_selection_outline_root.visible = true


func _selection_world_line_width(world_position: Vector3) -> float:
	var viewport_height := maxf(1.0, get_viewport().get_visible_rect().size.y)
	var visible_world_height := _camera.size
	if _camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
		var camera_depth := maxf(0.1, _camera.global_position.distance_to(world_position))
		visible_world_height = 2.0 * camera_depth * tan(deg_to_rad(_camera.fov) * 0.5)
	return clampf(visible_world_height / viewport_height * UI_OUTLINE_PIXELS, 0.025, 0.09)


func _world_visual_bounds(world_object: Node3D) -> AABB:
	var bounds := AABB(world_object.global_position, Vector3.ZERO)
	var found_mesh := false
	var mesh_nodes := world_object.find_children("*", "MeshInstance3D", true, false)
	for mesh_node in mesh_nodes:
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null or not mesh_instance.visible:
			continue
		var local_bounds := mesh_instance.get_aabb()
		for x_side in 2:
			for y_side in 2:
				for z_side in 2:
					var local_corner := local_bounds.position + local_bounds.size * Vector3(
						float(x_side), float(y_side), float(z_side)
					)
					var world_corner := mesh_instance.global_transform * local_corner
					if found_mesh:
						bounds = bounds.expand(world_corner)
					else:
						bounds = AABB(world_corner, Vector3.ZERO)
						found_mesh = true
	if not found_mesh:
		bounds = AABB(world_object.global_position - Vector3.ONE * 0.5, Vector3.ONE)
	return bounds


func _box_segment_transform(segment_start: Vector3, segment_end: Vector3) -> Transform3D:
	var offset := segment_end - segment_start
	var length := offset.length()
	var direction := offset / length if length > 0.0 else Vector3.FORWARD
	var reference := Vector3.UP if absf(direction.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var basis_x := reference.cross(direction).normalized()
	var basis_y := direction.cross(basis_x).normalized()
	var basis := Basis(basis_x, basis_y, direction).scaled(Vector3(1.0, 1.0, length))
	return Transform3D(basis, segment_start.lerp(segment_end, 0.5))


func _refresh_planned_building_visibility() -> void:
	for construction_site in _construction_sites:
		if not is_instance_valid(construction_site):
			continue
		var revealed := _is_world_position_revealed(construction_site.global_position)
		construction_site.visible = revealed
		construction_site.set_planning_visible(_build_mode and revealed)


func _world_unit_cell(world_position: Vector3) -> Vector2i:
	return GridNavigationScript.world_cell(world_position)


func _cell_centre(cell: Vector2i) -> Vector3:
	return GridNavigationScript.cell_centre(cell)


func _clamp_to_playable_world(world_position: Vector3) -> Vector3:
	return GridNavigationScript.clamp_to_square(world_position, WORLD_HALF_EXTENT)


func _is_inside_playable_world(world_position: Vector3) -> bool:
	return GridNavigationScript.is_inside_square(world_position, WORLD_HALF_EXTENT)


func _assign_navigation_task(
	citizen: Citizen,
	target_position: Vector3,
	next_task: Dictionary,
	approach_solid_target: bool
) -> bool:
	_cancel_active_work(citizen)
	target_position = _clamp_to_playable_world(target_position)
	var route := _build_navigation_route(citizen.global_position, target_position, approach_solid_target)
	if route.is_empty():
		citizen.finish_task(UIText.CITIZEN_NO_ROUTE_STATUS_TEXT)
		return false
	citizen.assign_route(route, next_task)
	return true


func _build_navigation_route(
	start_position: Vector3,
	target_position: Vector3,
	approach_solid_target: bool
) -> Array[Vector3]:
	return GridNavigationScript.build_route(
		start_position,
		target_position,
		_navigation_blocked_cells(),
		WORLD_HALF_EXTENT,
		approach_solid_target
	)


func _navigation_blocked_cells() -> Dictionary:
	var blocked: Dictionary = _excavated_cells.duplicate()
	for item in _items:
		if not is_instance_valid(item) or item.is_carried:
			continue
		if item.item_kind in ["stone", "tree", "dead_tree", "palm_tree", "cactus", "bush"]:
			blocked[_world_unit_cell(item.global_position)] = true
	return blocked


func _order_group_chop(clicked_tree: WorldItem) -> void:
	if _selected_citizens.is_empty() or not is_instance_valid(clicked_tree):
		return
	# Release this group's previous commands before calculating Tree capacity.
	# Interrupted applied labour remains on its segment slot and can be resumed.
	for citizen in _selected_citizens:
		if not is_instance_valid(citizen):
			continue
		_cancel_active_work(citizen)
		citizen.finish_task()
	var candidates := _tree_chop_candidates(clicked_tree)
	var command_scope := _next_speech_command_scope()
	for citizen in _selected_citizens:
		if not is_instance_valid(citizen):
			continue
		var assigned := false
		for tree in candidates:
			var work_slot := _next_available_tree_work_slot(tree)
			if work_slot < 0:
				continue
			if _order_chop(citizen, tree, work_slot, command_scope):
				assigned = true
				break
		if not assigned:
			citizen.finish_task(UIText.CITIZEN_TREE_UNAVAILABLE_STATUS_TEXT)


func _tree_chop_candidates(clicked_tree: WorldItem) -> Array[WorldItem]:
	var candidates: Array[WorldItem] = []
	for item in _items:
		if (
			is_instance_valid(item)
			and item.visible
			and item.tree_log_count > 0
			and item.item_kind in ["tree", "dead_tree", "palm_tree"]
		):
			candidates.append(item)
	if not candidates.has(clicked_tree) and clicked_tree.tree_log_count > 0:
		candidates.append(clicked_tree)
	candidates.sort_custom(func(first: WorldItem, second: WorldItem) -> bool:
		return clicked_tree.global_position.distance_squared_to(first.global_position) < clicked_tree.global_position.distance_squared_to(second.global_position)
	)
	return candidates


func _next_available_tree_work_slot(tree: WorldItem) -> int:
	if not is_instance_valid(tree) or tree.tree_log_count <= 0:
		return -1
	var assigned_slots: Dictionary = {}
	for citizen in _citizens:
		if not is_instance_valid(citizen):
			continue
		if (
			str(citizen.task.get("kind", "")) == ActionCatalog.CHOP_TREE
			and citizen.task.get("target") == tree
		):
			assigned_slots[int(citizen.task.get("tree_work_slot", -1))] = true
	var recorded_slots: Dictionary = {}
	var resumable_slots: Array[int] = []
	for labour_key_value in _labour_records:
		var record: Dictionary = _labour_records[labour_key_value]
		if (
			record.get("target") != tree
			or str(record.get("kind", "")) != ActionCatalog.CHOP_TREE
		):
			continue
		var work_slot := int(record.get("work_slot", -1))
		if work_slot < 0:
			continue
		recorded_slots[work_slot] = true
		var labour := record.get("labour") as AppliedLabour
		if not assigned_slots.has(work_slot) and labour != null and not labour.is_being_applied():
			resumable_slots.append(work_slot)
	resumable_slots.sort()
	if not resumable_slots.is_empty():
		return resumable_slots[0]
	var reserved_slots := recorded_slots.duplicate()
	for assigned_slot in assigned_slots:
		reserved_slots[assigned_slot] = true
	if reserved_slots.size() >= tree.tree_log_count:
		return -1
	var next_slot := 0
	while reserved_slots.has(next_slot):
		next_slot += 1
	return next_slot


func _order_chop(
	citizen: Citizen,
	tree: WorldItem,
	work_slot := -1,
	command_scope := ""
) -> bool:
	if work_slot < 0:
		work_slot = _next_available_tree_work_slot(tree)
	if work_slot < 0:
		citizen.finish_task(UIText.CITIZEN_TREE_UNAVAILABLE_STATUS_TEXT)
		return false
	var next_task := {
		"kind": ActionCatalog.CHOP_TREE,
		"status_text_key": UIText.CITIZEN_WALKING_TO_TREE_STATUS_TEXT,
		"target": tree,
		"tree_work_slot": work_slot,
	}
	var accepted := _assign_tree_work_position(citizen, tree, work_slot, next_task)
	if accepted:
		_actor_message_bus.post_message(citizen, MessageCatalog.CONFIRM_LOG, {
			"cluster_scope": command_scope if not command_scope.is_empty() else _next_speech_command_scope(),
		})
	return accepted


func _assign_tree_work_position(
	citizen: Citizen,
	tree: WorldItem,
	work_slot: int,
	next_task: Dictionary
) -> bool:
	var tree_cell := _world_unit_cell(tree.global_position)
	var blocked_cells := _navigation_blocked_cells()
	for attempt_index in GridNavigationScript.NEIGHBOUR_OFFSETS.size():
		var offset_index := (work_slot + attempt_index) % GridNavigationScript.NEIGHBOUR_OFFSETS.size()
		var candidate_cell := tree_cell + GridNavigationScript.NEIGHBOUR_OFFSETS[offset_index]
		if blocked_cells.has(candidate_cell):
			continue
		if _assign_navigation_task(citizen, _cell_centre(candidate_cell), next_task, false):
			return true
	return false


func _order_harvest(citizen: Citizen, bush: WorldItem) -> void:
	var accepted := _assign_navigation_task(citizen, bush.global_position, {
		"kind": ActionCatalog.HARVEST_BUSH,
		"status_text_key": UIText.CITIZEN_WALKING_TO_BUSH_STATUS_TEXT,
		"target": bush,
	}, true)
	if accepted:
		_actor_message_bus.post_message(citizen, MessageCatalog.CONFIRM_FOOD, {
			"cluster_scope": _next_speech_command_scope(),
		})


func _order_collect_cactus(citizen: Citizen, cactus: WorldItem) -> void:
	var accepted := _assign_navigation_task(citizen, cactus.global_position, {
		"kind": ActionCatalog.COLLECT_CACTUS,
		"status_text_key": UIText.CITIZEN_WALKING_TO_CACTUS_STATUS_TEXT,
		"target": cactus,
	}, true)
	if accepted:
		_actor_message_bus.post_message(citizen, MessageCatalog.CONFIRM_WATER, {
			"cluster_scope": _next_speech_command_scope(),
		})


func _place_support_construction_site(world_position: Vector3, keep_placing := false) -> void:
	var construction_site := SupportConstructionSite.new()
	add_child(construction_site)
	construction_site.global_position = world_position
	_construction_sites.append(construction_site)
	if keep_placing:
		_selected_building = construction_site
		_build_mode = true
		_placing_support = true
		_refresh_planned_building_visibility()
	else:
		_select_building(construction_site)


func _ensure_support_placement_preview() -> void:
	if is_instance_valid(_support_placement_preview):
		return
	_support_placement_preview = SupportConstructionSite.new()
	_support_placement_preview.name = "SupportPlacementPreview"
	add_child(_support_placement_preview)
	for log_index in SupportConstructionSite.REQUIRED_LOGS:
		_support_placement_preview.deliver_log()
	for body_node in _support_placement_preview.find_children("*", "StaticBody3D", true, false):
		var body := body_node as StaticBody3D
		body.collision_layer = 0
		body.collision_mask = 0
	for mesh_node in _support_placement_preview.find_children("*", "GeometryInstance3D", true, false):
		var geometry := mesh_node as GeometryInstance3D
		geometry.transparency = 0.12
		geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var footprint := MeshInstance3D.new()
	footprint.name = "PlacementFootprint"
	var footprint_mesh := BoxMesh.new()
	footprint_mesh.size = Vector3(0.9, 0.02, 0.9)
	footprint.mesh = footprint_mesh
	footprint.position.y = 0.04
	var footprint_material := StandardMaterial3D.new()
	footprint_material.albedo_color = Color(1.0, 1.0, 1.0, 0.32)
	footprint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	footprint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	footprint.material_override = footprint_material
	footprint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_support_placement_preview.add_child(footprint)
	_support_placement_preview.visible = false


func _update_support_placement_preview() -> void:
	if not _placing_support or not _build_mode or not is_instance_valid(_camera):
		if is_instance_valid(_support_placement_preview):
			_support_placement_preview.visible = false
		return
	_ensure_support_placement_preview()
	var hovered_control := get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		_support_placement_preview.visible = false
		return
	var hit := _raycast(get_viewport().get_mouse_position())
	if hit.is_empty():
		_support_placement_preview.visible = false
		return
	var collider := hit.get("collider") as Node
	if collider == null or collider.get_meta("world_kind", "") != "ground":
		_support_placement_preview.visible = false
		return
	var preview_position := _snap_to_world_unit(hit.position)
	var preview_cell := _world_unit_cell(preview_position)
	_support_placement_preview.visible = (
		_is_inside_playable_world(preview_position)
		and not _excavated_cells.has(preview_cell)
	)
	if _support_placement_preview.visible:
		_support_placement_preview.global_position = preview_position


func _place_excavation_site(world_cell: Vector2i, keep_placing := false) -> void:
	if _excavated_cells.has(world_cell):
		return
	for existing_site in _excavation_sites:
		if is_instance_valid(existing_site) and _world_unit_cell(existing_site.global_position) == world_cell:
			_select_world_object(existing_site)
			return
	var excavation_site := ExcavationSiteScript.new() as ExcavationSite
	add_child(excavation_site)
	excavation_site.global_position = Vector3(
		float(world_cell.x) + 0.5,
		0.0,
		float(world_cell.y) + 0.5
	)
	_excavation_sites.append(excavation_site)
	_select_world_object(excavation_site)
	_build_mode = true
	_placing_excavation = keep_placing
	_placing_support = false


func _order_excavate(citizen: Citizen, excavation_site: ExcavationSite) -> void:
	_assign_navigation_task(citizen, excavation_site.global_position, {
		"kind": ActionCatalog.EXCAVATE,
		"status_text_key": UIText.CITIZEN_WALKING_TO_EXCAVATION_STATUS_TEXT,
		"target": excavation_site,
	}, true)


func _continue_build(citizen: Citizen, construction_site: SupportConstructionSite) -> void:
	if not is_instance_valid(construction_site) or not construction_site.needs_log():
		citizen.finish_task(UIText.CITIZEN_SUPPORT_COMPLETE_STATUS_TEXT)
		return
	_actor_message_bus.post_message(citizen, MessageCatalog.CONFIRM_CONSTRUCTION, {
		"cluster_scope": _next_speech_command_scope(),
	})
	var available_log := _nearest_available_log(citizen.global_position)
	if available_log == null:
		citizen.finish_task(UIText.CITIZEN_SUPPORT_NEEDS_LOG_STATUS_TEXT)
		return
	_assign_navigation_task(citizen, available_log.global_position, {
		"kind": ActionCatalog.FETCH_LOG,
		"status_text_key": UIText.CITIZEN_FETCHING_LOG_STATUS_TEXT,
		"log": available_log,
		"construction_site": construction_site,
	}, false)


func _on_citizen_arrived(citizen: Citizen) -> void:
	var task := citizen.task
	match str(task.get("kind", "")):
		ActionCatalog.MOVE:
			citizen.finish_task(UIText.CITIZEN_IDLE_STATUS_TEXT)
		ActionCatalog.CHOP_TREE:
			_handle_chop_arrival(citizen, task)
		ActionCatalog.HARVEST_BUSH:
			_handle_harvest_arrival(citizen, task)
		ActionCatalog.COLLECT_CACTUS:
			_handle_cactus_arrival(citizen, task)
		ActionCatalog.EXCAVATE:
			_handle_excavation_arrival(citizen, task)
		ActionCatalog.FETCH_LOG:
			_handle_fetch_log_arrival(citizen, task)
		ActionCatalog.DELIVER_LOG:
			_handle_deliver_log_arrival(citizen, task)


func _handle_chop_arrival(citizen: Citizen, task: Dictionary) -> void:
	var tree: Variant = task.get("target")
	if is_instance_valid(tree):
		_start_tree_cut_work(citizen, tree as WorldItem)
	else:
		citizen.finish_task(UIText.CITIZEN_TREE_UNAVAILABLE_STATUS_TEXT)


func _handle_harvest_arrival(citizen: Citizen, task: Dictionary) -> void:
	var bush: Variant = task.get("target")
	if is_instance_valid(bush) and (bush as WorldItem).can_harvest():
		_start_resource_work(
			citizen,
			bush as WorldItem,
			ActionCatalog.HARVEST_BUSH,
			UIText.CITIZEN_HARVESTING_BUSH_STATUS_TEXT
		)
	else:
		citizen.finish_task(UIText.CITIZEN_BUSH_REGROWING_STATUS_TEXT)


func _handle_cactus_arrival(citizen: Citizen, task: Dictionary) -> void:
	var cactus: Variant = task.get("target")
	if is_instance_valid(cactus) and (cactus as WorldItem).has_collectable_water():
		_start_resource_work(
			citizen,
			cactus as WorldItem,
			ActionCatalog.COLLECT_CACTUS,
			UIText.CITIZEN_COLLECTING_CACTUS_STATUS_TEXT
		)
	else:
		citizen.finish_task(UIText.CITIZEN_CACTUS_UNAVAILABLE_STATUS_TEXT)


func _handle_excavation_arrival(citizen: Citizen, task: Dictionary) -> void:
	var excavation_target: Variant = task.get("target")
	if is_instance_valid(excavation_target):
		_start_excavation_work(citizen, excavation_target as ExcavationSite)
	else:
		citizen.finish_task(UIText.CITIZEN_EXCAVATION_UNAVAILABLE_STATUS_TEXT)


func _handle_fetch_log_arrival(citizen: Citizen, task: Dictionary) -> void:
	var source_log: Variant = task.get("log")
	var construction_site: Variant = task.get("construction_site")
	if not is_instance_valid(source_log) or not is_instance_valid(construction_site) or not source_log.take_for_carry():
		citizen.finish_task(UIText.CITIZEN_LOG_UNAVAILABLE_STATUS_TEXT)
		return
	citizen.set_carrying_log(true)
	_assign_navigation_task(citizen, construction_site.global_position, {
		"kind": ActionCatalog.DELIVER_LOG,
		"status_text_key": UIText.CITIZEN_CARRYING_LOG_STATUS_TEXT,
		"log": source_log,
		"construction_site": construction_site,
	}, false)


func _handle_deliver_log_arrival(citizen: Citizen, task: Dictionary) -> void:
	var carried_log: Variant = task.get("log")
	var construction_site: Variant = task.get("construction_site")
	citizen.set_carrying_log(false)
	if is_instance_valid(carried_log):
		carried_log.queue_free()
	if is_instance_valid(construction_site):
		construction_site.deliver_log()
		_continue_build(citizen, construction_site)
	else:
		citizen.finish_task(UIText.CITIZEN_CONSTRUCTION_SITE_UNAVAILABLE_STATUS_TEXT)


func _start_tree_cut_work(citizen: Citizen, tree: WorldItem) -> void:
	if tree.item_kind not in ["tree", "dead_tree", "palm_tree"] or tree.tree_log_count <= 0:
		citizen.finish_task(UIText.CITIZEN_TREE_UNAVAILABLE_STATUS_TEXT)
		return
	_begin_labour(
		citizen,
		tree,
		ActionCatalog.CHOP_TREE,
		UIText.CITIZEN_CUTTING_TREE_STATUS_TEXT,
		TREE_CUT_WORK_SECONDS,
		int(citizen.task.get("tree_work_slot", 0))
	)
	citizen.set_chopping(true, tree.global_position)


func _start_excavation_work(citizen: Citizen, excavation_site: ExcavationSite) -> void:
	_begin_labour(
		citizen,
		excavation_site,
		ActionCatalog.EXCAVATE,
		UIText.CITIZEN_DIGGING_STATUS_TEXT,
		EXCAVATION_WORK_SECONDS
	)


func _start_resource_work(
	citizen: Citizen,
	target: WorldItem,
	work_kind: String,
	status_text_key: String
) -> void:
	_begin_labour(citizen, target, work_kind, status_text_key, RESOURCE_WORK_SECONDS)


func _begin_labour(
	citizen: Citizen,
	target: Node3D,
	work_kind: String,
	status_text_key: String,
	required_seconds: float,
	work_slot := -1
) -> void:
	_cancel_active_work(citizen)
	var labour_key := _labour_key(target, work_kind, work_slot)
	var record := _labour_record_for(target, work_kind, required_seconds, work_slot)
	var labour := record.get("labour") as AppliedLabour
	var contributor_id := citizen.get_instance_id()
	labour.resume(contributor_id)
	var progress_bar := record.get("bar") as LabourProgressBar
	if is_instance_valid(progress_bar):
		progress_bar.visible = true
	_active_work[citizen] = {
		"kind": work_kind,
		"target": target,
		"labour_key": labour_key,
		"contributor_id": contributor_id,
		"work_slot": work_slot,
	}
	citizen.status_text_key = status_text_key
	citizen.status_text_arguments.clear()


func _labour_key(target: Node3D, work_kind: String, work_slot := -1) -> String:
	if work_kind == ActionCatalog.CHOP_TREE and work_slot >= 0:
		return "%d:%s:%d" % [target.get_instance_id(), work_kind, work_slot]
	return "%d:%s" % [target.get_instance_id(), work_kind]


func _labour_record_for(
	target: Node3D,
	work_kind: String,
	required_seconds: float,
	work_slot := -1
) -> Dictionary:
	var labour_key := _labour_key(target, work_kind, work_slot)
	if _labour_records.has(labour_key):
		return _labour_records[labour_key] as Dictionary
	var record := {
		"kind": work_kind,
		"target": target,
		"labour": AppliedLabourScript.new(required_seconds),
		"bar": _create_labour_progress_bar(required_seconds),
		"work_slot": work_slot,
	}
	_labour_records[labour_key] = record
	return record


func _update_labour(delta: float) -> void:
	var completed_labour: Dictionary = {}
	var cancelled_citizens: Array[Citizen] = []
	for citizen_value in _active_work:
		var citizen := citizen_value as Citizen
		var work: Dictionary = _active_work[citizen]
		var target := work.get("target") as Node3D
		var labour_key := str(work.get("labour_key", ""))
		var record: Dictionary = _labour_records.get(labour_key, {})
		var labour := record.get("labour") as AppliedLabour
		if not is_instance_valid(citizen) or not is_instance_valid(target) or labour == null:
			cancelled_citizens.append(citizen)
			continue
		var contributor_id := int(work.get("contributor_id", 0))
		var completed := labour.apply(contributor_id, delta)
		var progress := labour.progress_ratio()
		if str(work.get("kind", "")) == ActionCatalog.CHOP_TREE:
			citizen.set_chop_progress(progress)
		if completed:
			completed_labour[labour_key] = citizen
	for citizen in cancelled_citizens:
		var cancelled_work: Dictionary = _active_work.get(citizen, {})
		var cancelled_kind := str(cancelled_work.get("kind", ""))
		var cancelled_target := cancelled_work.get("target") as Node3D
		var cancelled_labour_key := str(cancelled_work.get("labour_key", ""))
		_cancel_active_work(citizen)
		if not is_instance_valid(cancelled_target):
			_remove_labour_record(cancelled_labour_key)
		if is_instance_valid(citizen):
			var unavailable_status := UIText.CITIZEN_TREE_UNAVAILABLE_STATUS_TEXT
			match cancelled_kind:
				ActionCatalog.EXCAVATE:
					unavailable_status = UIText.CITIZEN_EXCAVATION_UNAVAILABLE_STATUS_TEXT
				ActionCatalog.HARVEST_BUSH:
					unavailable_status = UIText.CITIZEN_BUSH_REGROWING_STATUS_TEXT
				ActionCatalog.COLLECT_CACTUS:
					unavailable_status = UIText.CITIZEN_CACTUS_UNAVAILABLE_STATUS_TEXT
			citizen.finish_task(unavailable_status)
	for labour_key_value in completed_labour:
		var labour_key := str(labour_key_value)
		if _labour_records.has(labour_key):
			_complete_labour_job(labour_key, completed_labour[labour_key] as Citizen)
	_update_labour_records(delta)


func _update_labour_records(delta: float) -> void:
	for labour_key_value in _labour_records.keys():
		var labour_key := str(labour_key_value)
		var record: Dictionary = _labour_records[labour_key]
		var target := record.get("target") as Node3D
		var labour := record.get("labour") as AppliedLabour
		var progress_bar := record.get("bar") as LabourProgressBar
		if not is_instance_valid(target) or labour == null:
			_remove_labour_record(labour_key)
			continue
		labour.update_interruption(delta)
		if not is_instance_valid(progress_bar):
			continue
		progress_bar.set_progress_ratio(labour.progress_ratio())
		progress_bar.set_sun_screen_side(_sun_screen_side())
		var world_anchor := target.global_position + Vector3.UP * 0.18
		progress_bar.visible = labour.should_be_visible() and not _camera.is_position_behind(world_anchor)
		if progress_bar.visible:
			var work_slot := int(record.get("work_slot", -1))
			var slot_screen_offset := Vector2(0.0, -float(maxi(0, work_slot)) * 10.0)
			progress_bar.position = _camera.unproject_position(world_anchor) - Vector2(
				progress_bar.size.x * 0.5,
				progress_bar.size.y
			) + slot_screen_offset


func _sun_screen_side() -> float:
	if not is_instance_valid(_sun) or not is_instance_valid(_camera):
		return 0.0
	var direction_to_sun := _sun.global_transform.basis.z.normalized()
	var camera_right := _camera.global_transform.basis.x.normalized()
	return clampf(direction_to_sun.dot(camera_right), -1.0, 1.0)


func _complete_labour_job(labour_key: String, completing_citizen: Citizen) -> void:
	var record: Dictionary = _labour_records.get(labour_key, {})
	if record.is_empty():
		return
	var work_kind := str(record.get("kind", ""))
	var target := record.get("target") as Node3D
	for citizen_value in _active_work.keys():
		var citizen := citizen_value as Citizen
		var work: Dictionary = _active_work[citizen]
		if str(work.get("labour_key", "")) != labour_key:
			continue
		_active_work.erase(citizen)
		if is_instance_valid(citizen):
			citizen.set_chopping(false)
			if citizen != completing_citizen:
				citizen.finish_task()
	_remove_labour_record(labour_key)
	match work_kind:
		ActionCatalog.EXCAVATE:
			_complete_excavation_work(completing_citizen, target as ExcavationSite)
		ActionCatalog.HARVEST_BUSH:
			_complete_bush_harvest_work(completing_citizen, target as WorldItem)
		ActionCatalog.COLLECT_CACTUS:
			_complete_cactus_collection_work(completing_citizen, target as WorldItem)
		_:
			_complete_tree_cut_work(completing_citizen, target as WorldItem)


func _complete_bush_harvest_work(citizen: Citizen, bush: WorldItem) -> void:
	if not is_instance_valid(citizen) or not is_instance_valid(bush):
		return
	if bush.harvest():
		_calories += 1
		citizen.finish_task(UIText.CITIZEN_HARVESTED_CALORIE_STATUS_TEXT)
	else:
		citizen.finish_task(UIText.CITIZEN_BUSH_REGROWING_STATUS_TEXT)


func _complete_cactus_collection_work(citizen: Citizen, cactus: WorldItem) -> void:
	if not is_instance_valid(citizen) or not is_instance_valid(cactus):
		return
	var collected_water := cactus.collect_water()
	if collected_water > 0:
		_water += collected_water
		citizen.finish_task(UIText.CITIZEN_COLLECTED_WATER_STATUS_TEXT)
	else:
		citizen.finish_task(UIText.CITIZEN_CACTUS_UNAVAILABLE_STATUS_TEXT)


func _complete_excavation_work(citizen: Citizen, excavation_site: ExcavationSite) -> void:
	if not is_instance_valid(citizen) or not is_instance_valid(excavation_site):
		return
	var world_cell := _world_unit_cell(excavation_site.global_position)
	_excavated_cells[world_cell] = true
	_excavation_sites.erase(excavation_site)
	if _selected_world_object == excavation_site:
		_clear_object_selection()
	_create_excavated_pit(world_cell)
	_update_excavated_ground_mask()
	excavation_site.queue_free()
	citizen.finish_task(UIText.CITIZEN_EXCAVATION_COMPLETE_STATUS_TEXT)


func _complete_tree_cut_work(citizen: Citizen, tree: WorldItem) -> void:
	if not is_instance_valid(citizen) or not is_instance_valid(tree):
		return
	var tree_position := tree.global_position
	var cut_result: Dictionary = tree.cut_top_log()
	if cut_result.is_empty():
		citizen.finish_task(UIText.CITIZEN_TREE_UNAVAILABLE_STATUS_TEXT)
		return
	_spawn_item(
		"log",
		cut_result.get("drop_position", tree_position),
		int(cut_result.get("log_detail_seed", 1))
	)
	citizen.finish_task(UIText.CITIZEN_CUT_LOG_STATUS_TEXT)


func _cancel_active_work(citizen: Citizen) -> void:
	if not _active_work.has(citizen):
		return
	var work: Dictionary = _active_work[citizen]
	var labour_key := str(work.get("labour_key", ""))
	var record: Dictionary = _labour_records.get(labour_key, {})
	var labour := record.get("labour") as AppliedLabour
	if labour != null:
		labour.interrupt(int(work.get("contributor_id", 0)))
	_active_work.erase(citizen)
	if is_instance_valid(citizen):
		citizen.set_chopping(false)


func _create_labour_progress_bar(required_seconds: float) -> LabourProgressBar:
	var progress_bar := LabourProgressBarScript.new() as LabourProgressBar
	progress_bar.configure(required_seconds, UI_OUTLINE_PIXELS, Palette.WOMAN_CLOTHING)
	_world_progress_layer.add_child(progress_bar)
	return progress_bar


func _remove_labour_record(labour_key: String) -> void:
	if not _labour_records.has(labour_key):
		return
	var record: Dictionary = _labour_records[labour_key]
	var progress_bar := record.get("bar") as LabourProgressBar
	if is_instance_valid(progress_bar):
		progress_bar.queue_free()
	_labour_records.erase(labour_key)


func _nearest_available_log(from_position: Vector3) -> WorldItem:
	var nearest: WorldItem
	var nearest_distance := INF
	for item in _items:
		if not is_instance_valid(item) or not item.is_available_log():
			continue
		var distance := from_position.distance_squared_to(item.global_position)
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
	return nearest


func _raycast(screen_position: Vector2) -> Dictionary:
	var origin := _camera.project_ray_origin(screen_position)
	var end := origin + _camera.project_ray_normal(screen_position) * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _world_object_for(node: Node) -> Variant:
	var current := node
	while current != null:
		if current.has_meta("world_object"):
			return current.get_meta("world_object")
		current = current.get_parent()
	return null


func _update_hover_tooltip() -> void:
	if not is_instance_valid(_hover_tooltip) or not is_instance_valid(_camera):
		return
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	if hovered_control != null and hovered_control != _hover_tooltip:
		_reset_hover_candidate()
		return
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	if mouse_position.distance_to(_hover_last_mouse_position) > 3.0:
		_hover_last_mouse_position = mouse_position
		_reset_hover_candidate()
		return
	var hit: Dictionary = _raycast(mouse_position)
	if hit.is_empty():
		_reset_hover_candidate()
		return
	var collider: Node = hit.get("collider") as Node
	var world_object: Variant = _world_object_for(collider)
	var display_name: String = _hover_display_name(world_object, collider)
	if display_name.is_empty():
		_reset_hover_candidate()
		return
	var candidate_key := "%d:%s" % [collider.get_instance_id(), display_name]
	if candidate_key != _hover_candidate_key:
		_hover_candidate_key = candidate_key
		_hover_stable_elapsed = 0.0
		_hover_target_visible = false
		return
	_hover_stable_elapsed += HOVER_REFRESH_INTERVAL
	if _hover_stable_elapsed < HOVER_DELAY_SECONDS:
		_hover_target_visible = false
		return
	var tooltip_text: String = display_name
	if _debug_hover_enabled:
		var debug_text: String = _hover_debug_text(world_object, collider, hit)
		if not debug_text.is_empty():
			tooltip_text += "\n" + debug_text
	_hover_tooltip.text = tooltip_text
	_hover_tooltip.reset_size()
	var tooltip_size := _hover_tooltip.get_combined_minimum_size()
	_hover_tooltip.size = tooltip_size
	var tooltip_position := mouse_position + Vector2(18.0, -tooltip_size.y - 18.0)
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	tooltip_position.x = clampf(tooltip_position.x, 8.0, maxf(8.0, viewport_size.x - tooltip_size.x - 8.0))
	tooltip_position.y = clampf(tooltip_position.y, 8.0, maxf(8.0, viewport_size.y - tooltip_size.y - 8.0))
	_hover_tooltip.position = tooltip_position
	_hover_target_visible = true


func _reset_hover_candidate() -> void:
	_hover_candidate_key = ""
	_hover_stable_elapsed = 0.0
	_hover_target_visible = false


func _update_hover_transition(delta: float) -> void:
	if not is_instance_valid(_hover_tooltip):
		return
	var target_alpha := 1.0 if _hover_target_visible else 0.0
	_hover_alpha = move_toward(_hover_alpha, target_alpha, HOVER_FADE_SPEED * delta)
	_hover_tooltip.modulate.a = _hover_alpha
	_hover_tooltip.visible = _hover_alpha > 0.01


func _hover_display_name(world_object: Variant, collider: Node) -> String:
	if world_object is Citizen:
		return UIText.text(UIText.CITIZEN_NAME_TEXT)
	if world_object is SupportConstructionSite:
		return UIText.text(UIText.SUPPORT_NAME_TEXT)
	if world_object is ExcavationSite:
		return UIText.text(UIText.EXCAVATION_NAME_TEXT)
	if world_object is WorldItem:
		var item := world_object as WorldItem
		if item.item_kind in ["tree", "dead_tree", "palm_tree"]:
			var tree_resource_text_keys := {
				"tree": UIText.TREE_RESOURCE_NAME_TEXT,
				"dead_tree": UIText.DEAD_TREE_RESOURCE_NAME_TEXT,
				"palm_tree": UIText.PALM_RESOURCE_NAME_TEXT,
			}
			return UIText.text(
				tree_resource_text_keys[item.item_kind],
				[item.tree_log_count, WorldItem.TREE_MAX_LOG_COUNT]
			)
		var world_item_text_keys := {
			"bush": UIText.BUSH_NAME_TEXT,
			"cactus": UIText.CACTUS_NAME_TEXT,
			"stone": UIText.LIMESTONE_NAME_TEXT,
			"log": UIText.LOG_NAME_TEXT,
			"stump": UIText.STUMP_NAME_TEXT,
		}
		var world_item_text_key: String = world_item_text_keys.get(item.item_kind, "")
		return UIText.text(world_item_text_key) if not world_item_text_key.is_empty() else ""
	if collider != null and collider.get_meta("world_kind", "") == "ground":
		return UIText.text(UIText.SAND_NAME_TEXT)
	return ""


func _hover_debug_text(world_object: Variant, collider: Node, hit: Dictionary) -> String:
	var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
	if world_object is Citizen:
		var citizen := world_object as Citizen
		return UIText.text(UIText.CITIZEN_DEBUG_HOVER_TEXT, [
			citizen.visual_variant,
			citizen.get_status_text(),
			citizen.global_position.x,
			citizen.global_position.z,
		])
	if world_object is SupportConstructionSite:
		var support := world_object as SupportConstructionSite
		return UIText.text(UIText.SUPPORT_DEBUG_HOVER_TEXT, [
			support.delivered_logs,
			SupportConstructionSite.REQUIRED_LOGS,
			support.global_position.x,
			support.global_position.z,
		])
	if world_object is WorldItem:
		var item := world_object as WorldItem
		return UIText.text(UIText.WORLD_ITEM_DEBUG_HOVER_TEXT, [
			item.permanent_detail_seed, item.tree_log_count, item.water_stored
		])
	if collider != null and collider.get_meta("world_kind", "") == "ground":
		var cell := _world_unit_cell(hit_position)
		return UIText.text(UIText.WORLD_UNIT_DEBUG_HOVER_TEXT, [cell.x, cell.y])
	return ""


func _snap_to_world_unit(world_position: Vector3) -> Vector3:
	return Vector3(round(world_position.x), 0.0, round(world_position.z))


func _seed_world() -> void:
	_seed_bush_patches()
	_seed_desert_resource_patches()
	_seed_tree_distribution()

	for spawn_position in [Vector3(-1.0, 0, 3.0), Vector3(0.4, 0, 3.0), Vector3(1.8, 0, 3.0), Vector3(3.2, 0, 3.0), Vector3(-1.0, 0, 4.0), Vector3(0.4, 0, 4.0)]:
		_spawn_item("log", spawn_position)

	_spawn_citizen(Vector3(-1.5, 0.0, 0.5))
	_spawn_citizen(Vector3(0.5, 0.0, 1.5))
	_select_only(_citizens[0])
	_selected_citizen.status_text_key = UIText.CITIZEN_SELECTED_STATUS_TEXT
	_selected_citizen.status_text_arguments.clear()
	_camera_focus = _selected_citizen.global_position
	_update_camera_transform()


func _spawn_tree_in_tile(tile: Vector2i, seed_value: int, slot: int) -> void:
	var x_offset := _seeded_offset(seed_value + slot * 43, 0.27)
	var z_offset := _seeded_offset(seed_value + slot * 71 + 11, 0.27)
	if slot == 1:
		x_offset = -x_offset
		z_offset = -z_offset
	var tree_kind := "dead_tree" if seed_value % 9 == 0 and slot == 0 else "tree"
	_spawn_item(tree_kind, Vector3(tile.x + 0.5 + x_offset, 0.0, tile.y + 0.5 + z_offset))


func _seed_tree_distribution() -> void:
	# Trees form irregular forests separated by clear land, with a smaller set
	# of standalone specimens between them. This avoids a repeating global
	# scatter while preserving approximately the previous overall density.
	var forest_centres := [
		Vector2i(-5, -4), Vector2i(-20, 15), Vector2i(17, -17),
		Vector2i(20, 19), Vector2i(-17, -21), Vector2i(2, 24),
	]
	var forest_radii := [4, 5, 5, 4, 4, 3]
	for forest_index in forest_centres.size():
		var forest_centre: Vector2i = forest_centres[forest_index]
		var forest_radius: int = forest_radii[forest_index]
		for offset_x in range(-forest_radius, forest_radius + 1):
			for offset_z in range(-forest_radius, forest_radius + 1):
				var tile := forest_centre + Vector2i(offset_x, offset_z)
				if _occupied_static_world_units.has(tile):
					continue
				var distance := Vector2(float(offset_x), float(offset_z)).length()
				if distance > float(forest_radius) + 0.25:
					continue
				var forest_seed := _coordinate_seed(tile.x, tile.y, 311 + forest_index)
				var centre_weight := 1.0 - distance / float(forest_radius + 1)
				var density_threshold := int(18.0 + centre_weight * 34.0)
				if forest_seed % 100 >= density_threshold:
					continue
				_occupied_static_world_units[tile] = true
				_spawn_tree_in_tile(tile, forest_seed, 0)
				if forest_seed % 11 == 0:
					_spawn_tree_in_tile(tile, forest_seed + 43, 1)

	var standalone_tiles := [
		Vector2i(7, 5), Vector2i(11, 1), Vector2i(-12, 2), Vector2i(4, -12),
		Vector2i(-2, 13), Vector2i(26, -3), Vector2i(-27, 6), Vector2i(10, 27),
		Vector2i(-8, -28), Vector2i(28, 8), Vector2i(-27, -8),
	]
	for standalone_index in standalone_tiles.size():
		var tile: Vector2i = standalone_tiles[standalone_index]
		if _occupied_static_world_units.has(tile):
			continue
		_occupied_static_world_units[tile] = true
		_spawn_tree_in_tile(tile, _coordinate_seed(tile.x, tile.y, 401 + standalone_index), 0)


func _seed_bush_patches() -> void:
	# Bushes now grow as recognizable colonies rather than independent random
	# points. Reusing three irregular footprints gives each patch a different
	# outline while keeping generation deterministic.
	var patch_shapes := [
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(0, -1),
		],
		[
			Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
			Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, -1), Vector2i(2, -1),
		],
		[
			Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1),
			Vector2i(1, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(-1, 1),
			Vector2i(2, 0),
		],
	]
	var patch_centres := [
		Vector2i(-2, -1), Vector2i(2, 2), Vector2i(-12, 8),
		Vector2i(13, -8), Vector2i(-22, -16), Vector2i(22, 18),
		Vector2i(-18, 24), Vector2i(17, 25), Vector2i(25, -23),
		Vector2i(-25, 3), Vector2i(3, -20),
	]
	for patch_index in patch_centres.size():
		var patch_centre: Vector2i = patch_centres[patch_index]
		var patch_shape: Array = patch_shapes[patch_index % patch_shapes.size()]
		for offset_value in patch_shape:
			var patch_offset: Vector2i = offset_value
			var bush_world_unit := patch_centre + patch_offset
			var bush_seed := _coordinate_seed(bush_world_unit.x, bush_world_unit.y, patch_index + 101)
			_spawn_bush_in_world_unit(bush_world_unit, bush_seed)


func _spawn_bush_in_world_unit(world_unit: Vector2i, seed_value: int) -> void:
	if _occupied_bush_world_units.has(world_unit):
		return
	if is_instance_valid(_grass_renderer) and _grass_renderer.has_grass_in_world_unit(world_unit):
		return
	_occupied_bush_world_units[world_unit] = true
	_occupied_static_world_units[world_unit] = true
	var offset := Vector2(
		_seeded_offset(seed_value + 19, 0.075),
		_seeded_offset(seed_value + 47, 0.075)
	)
	_spawn_item(
		"bush",
		Vector3(float(world_unit.x) + 0.5 + offset.x, 0.0, float(world_unit.y) + 0.5 + offset.y)
	)


func _seed_desert_resource_patches() -> void:
	var compact_patch := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, -1),
	]
	var long_patch := [
		Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0),
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1),
	]
	_spawn_resource_patch("stone", Vector2i(5, -5), compact_patch, 211)
	_spawn_resource_patch("stone", Vector2i(-14, -9), long_patch, 223)
	_spawn_resource_patch("stone", Vector2i(18, 12), compact_patch, 227)
	_spawn_resource_patch("cactus", Vector2i(4, 1), compact_patch, 229)
	_spawn_resource_patch("cactus", Vector2i(-10, 15), long_patch, 233)
	_spawn_resource_patch("cactus", Vector2i(21, -14), compact_patch, 239)
	_spawn_resource_patch("palm_tree", Vector2i(-6, 6), compact_patch, 241)
	_spawn_resource_patch("palm_tree", Vector2i(15, 20), long_patch, 251)


func _spawn_resource_patch(kind: String, centre: Vector2i, shape: Array, salt: int) -> void:
	for offset_value in shape:
		var patch_offset: Vector2i = offset_value
		var world_unit := centre + patch_offset
		if _occupied_static_world_units.has(world_unit):
			continue
		_occupied_static_world_units[world_unit] = true
		var detail_seed := _coordinate_seed(world_unit.x, world_unit.y, salt)
		var offset := Vector2(
			_seeded_offset(detail_seed + 31, 0.11),
			_seeded_offset(detail_seed + 59, 0.11)
		)
		_spawn_item(
			kind,
			Vector3(float(world_unit.x) + 0.5 + offset.x, 0.0, float(world_unit.y) + 0.5 + offset.y)
		)


func _coordinate_seed(x_coordinate: int, z_coordinate: int, salt: int) -> int:
	return DeterministicRandomScript.coordinate_seed(x_coordinate, z_coordinate, salt)


func _seeded_offset(seed_value: int, maximum: float) -> float:
	return DeterministicRandomScript.signed_offset(seed_value, maximum)


func _spawn_item(kind: String, world_position: Vector3, explicit_detail_seed := 0) -> void:
	var item := WorldItem.new()
	item.set_simulation_speed(_simulation_speed)
	var detail_seed := explicit_detail_seed if explicit_detail_seed != 0 else _coordinate_seed(
		floori(world_position.x * 100.0),
		floori(world_position.z * 100.0),
		kind.length() * 19
	)
	item.configure(kind, detail_seed)
	add_child(item)
	item.global_position = world_position
	_items.append(item)
	if _fog_image != null:
		item.visible = _is_world_position_revealed(item.global_position)


func _spawn_citizen(world_position: Vector3) -> void:
	var citizen := Citizen.new()
	citizen.set_simulation_speed(_simulation_speed)
	citizen.configure_visual_variant("woman" if _citizens.size() % 2 == 0 else "man")
	add_child(citizen)
	citizen.global_position = world_position
	citizen.arrived.connect(_on_citizen_arrived)
	_citizens.append(citizen)


func _create_ground() -> void:
	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(BACKGROUND_HALF_EXTENT * 2.0, BACKGROUND_HALF_EXTENT * 2.0)
	ground_mesh.mesh = plane
	_ground_material = _terrain_material(Palette.SAND_SURFACE)
	ground_mesh.material_override = _ground_material
	add_child(ground_mesh)

	var ground_body := StaticBody3D.new()
	ground_body.set_meta("world_kind", "ground")
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(BACKGROUND_HALF_EXTENT * 2.0, 0.1, BACKGROUND_HALF_EXTENT * 2.0)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.05
	ground_body.add_child(ground_shape)
	add_child(ground_body)
	_update_excavated_ground_mask()


func _update_excavated_ground_mask() -> void:
	if not is_instance_valid(_ground_material):
		return
	var shader_cells := PackedVector2Array()
	shader_cells.resize(64)
	var cell_index := 0
	for cell_value in _excavated_cells:
		if cell_index >= 64:
			break
		var world_cell: Vector2i = cell_value
		shader_cells[cell_index] = Vector2(world_cell)
		cell_index += 1
	_ground_material.set_shader_parameter("excavated_cell_count", cell_index)
	_ground_material.set_shader_parameter("excavated_cells", shader_cells)


func _create_excavated_pit(world_cell: Vector2i) -> void:
	var pit_root := Node3D.new()
	pit_root.name = "ExcavatedCell_%d_%d" % [world_cell.x, world_cell.y]
	pit_root.position = Vector3(float(world_cell.x) + 0.5, 0.0, float(world_cell.y) + 0.5)
	add_child(pit_root)
	var pit_material := _material(Palette.SAND_SURFACE.darkened(0.42))
	_create_pit_piece(pit_root, Vector3(0.94, 0.06, 0.94), Vector3(0.0, -0.48, 0.0), pit_material)
	_create_pit_piece(pit_root, Vector3(0.94, 0.46, 0.06), Vector3(0.0, -0.24, -0.47), pit_material)
	_create_pit_piece(pit_root, Vector3(0.94, 0.46, 0.06), Vector3(0.0, -0.24, 0.47), pit_material)
	_create_pit_piece(pit_root, Vector3(0.06, 0.46, 0.94), Vector3(-0.47, -0.24, 0.0), pit_material)
	_create_pit_piece(pit_root, Vector3(0.06, 0.46, 0.94), Vector3(0.47, -0.24, 0.0), pit_material)


func _create_pit_piece(
	parent: Node3D,
	size: Vector3,
	position: Vector3,
	material: Material
) -> void:
	var piece := MeshInstance3D.new()
	var piece_mesh := BoxMesh.new()
	piece_mesh.size = size
	piece.mesh = piece_mesh
	piece.position = position
	piece.material_override = material
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(piece)

func _create_camera() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = _camera_size
	_camera.position = _camera_focus + _current_camera_offset()
	_camera.near = 0.1
	_camera.far = 400.0
	_camera.current = true
	add_child(_camera)
	# Cameras look along their negative Z axis. Character meshes use the
	# opposite convention, so this must not use the model-front option.
	_camera.look_at(_camera_focus, Vector3.UP)


func _update_camera_pan(delta: float) -> void:
	var horizontal := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var vertical := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var input_length := Vector2(horizontal, vertical).length()
	if input_length <= 0.0:
		return
	var camera_offset := _current_camera_offset()
	var forward := Vector3(-camera_offset.x, 0.0, -camera_offset.z).normalized()
	var right := Vector3(-forward.z, 0.0, forward.x)
	var movement := (right * horizontal + forward * vertical).normalized()
	var zoom_scale := _camera_size / CAMERA_MINIMUM_SIZE
	_camera_focus += movement * CAMERA_PAN_SPEED * zoom_scale * delta
	_camera_focus.x = clampf(_camera_focus.x, -CAMERA_FOCUS_LIMIT, CAMERA_FOCUS_LIMIT)
	_camera_focus.z = clampf(_camera_focus.z, -CAMERA_FOCUS_LIMIT, CAMERA_FOCUS_LIMIT)
	_update_camera_transform()


func _update_camera_transform() -> void:
	if _camera == null:
		return
	_camera.global_position = _camera_focus + _current_camera_offset()
	_camera.size = _camera_size
	_camera.look_at(_camera_focus, Vector3.UP)
	_update_compass_camera()


func _adjust_camera_zoom(size_delta: float) -> void:
	_camera_size = clampf(
		_camera_size + size_delta,
		CAMERA_MINIMUM_SIZE,
		CAMERA_MAXIMUM_SIZE
	)
	_update_camera_transform()


func _current_camera_offset() -> Vector3:
	var camera_distance := CAMERA_DISTANCE * (_camera_size / CAMERA_MINIMUM_SIZE)
	var horizontal_distance := cos(_camera_pitch) * camera_distance
	return Vector3(
		sin(_camera_yaw) * horizontal_distance,
		sin(_camera_pitch) * camera_distance,
		cos(_camera_yaw) * horizontal_distance
	)


func _create_clouds() -> void:
	_clouds_root = Node3D.new()
	_clouds_root.name = "CloudLayer"
	add_child(_clouds_root)
	for cloud_index in 8:
		var cloud := Node3D.new()
		cloud.name = "Cloud_%d" % cloud_index
		cloud.position = Vector3(
			-90.0 + float((cloud_index * 29) % 180),
			295.0 + float(cloud_index % 3) * 2.0,
			-80.0 + float((cloud_index * 47) % 160)
		)
		_clouds_root.add_child(cloud)
		var block_count := 3 + cloud_index % 5
		for block_index in block_count:
			var block_mesh := BoxMesh.new()
			block_mesh.size = Vector3(
				5.0 + float((cloud_index + block_index * 3) % 7),
				1.5 + float(block_index % 2),
				4.0 + float((cloud_index * 2 + block_index) % 6)
			)
			var block := MeshInstance3D.new()
			block.mesh = block_mesh
			block.position = Vector3(float(block_index) * 4.5, float(block_index % 2), float((block_index * 5) % 9) - 4.0)
			block.material_override = _material(Palette.CLOUD)
			# High-altitude geometry cannot cast the gameplay shadow directly: a
			# rotating sun would sweep that projection across the ground too fast.
			block.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(block)
		_cloud_velocities[cloud] = Vector3(
			0.34 + float(cloud_index % 3) * 0.055,
			0.0,
			0.075
		)


func _update_clouds(delta: float) -> void:
	for cloud_value in _cloud_velocities:
		var cloud := cloud_value as Node3D
		if not is_instance_valid(cloud):
			continue
		var velocity: Vector3 = _cloud_velocities[cloud]
		cloud.position += velocity * delta
		if cloud.position.x > BACKGROUND_HALF_EXTENT + 20.0:
			cloud.position.x = -BACKGROUND_HALF_EXTENT - 20.0
	_cloud_shadow_offset += Vector2(0.42, 0.105) * delta
	if is_instance_valid(_ground_material):
		_ground_material.set_shader_parameter("cloud_shadow_offset", _cloud_shadow_offset)
		var visible_citizen_positions := PackedVector2Array()
		var visible_citizen_count := 0
		for citizen in _citizens:
			if is_instance_valid(citizen) and visible_citizen_count < 32:
				visible_citizen_positions.append(Vector2(citizen.global_position.x, citizen.global_position.z))
				visible_citizen_count += 1
		while visible_citizen_positions.size() < 32:
			visible_citizen_positions.append(Vector2.ZERO)
		_ground_material.set_shader_parameter("citizen_count", visible_citizen_count)
		_ground_material.set_shader_parameter("citizen_positions", visible_citizen_positions)


func _create_fog_of_war() -> void:
	_fog_image = Image.create(FOG_MASK_RESOLUTION, FOG_MASK_RESOLUTION, false, Image.FORMAT_R8)
	_fog_image.fill(Color.BLACK)
	_fog_texture = ImageTexture.create_from_image(_fog_image)

	var fog_plane := PlaneMesh.new()
	fog_plane.size = Vector2(WORLD_HALF_EXTENT * 2.0, WORLD_HALF_EXTENT * 2.0)
	_fog_instance = MeshInstance3D.new()
	_fog_instance.mesh = fog_plane
	_fog_instance.position.y = 0.025
	_fog_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fog_colour := Palette.FOG_AND_SHADOW
	var fog_shader := Shader.new()
	fog_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D fog_mask : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color;
uniform float world_half_extent;
varying vec2 fog_uv;

void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	fog_uv = (world_position.xz + vec2(world_half_extent)) / (world_half_extent * 2.0);
}

void fragment() {
	// Linear mask interpolation is used only to locate the binary contour.
	// The rendered result still has no fractional alpha: every fragment is
	// either exact fog colour or completely discarded.
	float revealed = texture(fog_mask, fog_uv).r;
	if (revealed >= 0.5) {
		discard;
	}
	ALBEDO = fog_color.rgb;
	ROUGHNESS = 1.0;
}
"""
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = fog_shader
	_fog_material.set_shader_parameter("fog_mask", _fog_texture)
	_fog_material.set_shader_parameter("fog_color", fog_colour)
	_fog_material.set_shader_parameter("world_half_extent", WORLD_HALF_EXTENT)
	_fog_instance.material_override = _fog_material
	add_child(_fog_instance)
	_reveal_world_around_citizens()


func _create_grass_renderer() -> void:
	_grass_renderer = GrassRendererScript.new()
	_grass_renderer.name = "GrassRenderer"
	add_child(_grass_renderer)
	_grass_renderer.setup(WORLD_HALF_EXTENT, FOG_CELL_SIZE, _occupied_bush_world_units)


func _reveal_world_around_citizens() -> void:
	if _fog_image == null:
		return
	var changed := false
	var newly_revealed_cells: Array[Vector2i] = []
	var fog_radius_in_cells := int(ceil(REVEAL_RADIUS / FOG_CELL_SIZE))
	var half_cell_count := int(WORLD_HALF_EXTENT / FOG_CELL_SIZE)
	for citizen in _citizens:
		if not is_instance_valid(citizen):
			continue
		var citizen_position_2d := Vector2(citizen.global_position.x, citizen.global_position.z)
		var citizen_cell := Vector2i(
			floori(citizen_position_2d.x / FOG_CELL_SIZE),
			floori(citizen_position_2d.y / FOG_CELL_SIZE)
		)
		for cell_x in range(citizen_cell.x - fog_radius_in_cells, citizen_cell.x + fog_radius_in_cells + 1):
			for cell_z in range(citizen_cell.y - fog_radius_in_cells, citizen_cell.y + fog_radius_in_cells + 1):
				if cell_x < -half_cell_count or cell_x >= half_cell_count or cell_z < -half_cell_count or cell_z >= half_cell_count:
					continue
				var fog_cell := Vector2i(cell_x, cell_z)
				if _revealed_fog_cells.has(fog_cell):
					continue
				var fog_cell_centre := Vector2(
					(cell_x + 0.5) * FOG_CELL_SIZE,
					(cell_z + 0.5) * FOG_CELL_SIZE
				)
				if fog_cell_centre.distance_squared_to(citizen_position_2d) <= REVEAL_RADIUS * REVEAL_RADIUS:
					_revealed_fog_cells[fog_cell] = true
					newly_revealed_cells.append(fog_cell)
					changed = true
	if changed:
		_fill_enclosed_world_unit_holes(newly_revealed_cells)
		_paint_revealed_fog_cells(newly_revealed_cells)
		_fog_texture.update(_fog_image)
		_update_revealed_entity_visibility()
		if is_instance_valid(_grass_renderer):
			_grass_renderer.reveal_fog_cells(newly_revealed_cells)


func _paint_revealed_fog_cells(newly_revealed_cells: Array[Vector2i]) -> void:
	var half_cell_count := int(WORLD_HALF_EXTENT / FOG_CELL_SIZE)
	for fog_cell in newly_revealed_cells:
		var pixel_x := fog_cell.x + half_cell_count
		var pixel_y := fog_cell.y + half_cell_count
		if pixel_x < 0 or pixel_x >= FOG_MASK_RESOLUTION or pixel_y < 0 or pixel_y >= FOG_MASK_RESOLUTION:
			continue
		_fog_image.set_pixel(pixel_x, pixel_y, Color.WHITE)


func _fill_enclosed_world_unit_holes(newly_revealed_cells: Array[Vector2i]) -> bool:
	var candidates: Dictionary = {}
	for fog_cell in newly_revealed_cells:
		var changed_world_unit := Vector2i(
			floori(float(fog_cell.x) * FOG_CELL_SIZE),
			floori(float(fog_cell.y) * FOG_CELL_SIZE)
		)
		for offset_x in range(-1, 2):
			for offset_z in range(-1, 2):
				candidates[changed_world_unit + Vector2i(offset_x, offset_z)] = true

	var filled_hole := false
	for candidate_value in candidates:
		var candidate: Vector2i = candidate_value
		if candidate.x <= -int(WORLD_HALF_EXTENT) or candidate.x >= int(WORLD_HALF_EXTENT) - 1:
			continue
		if candidate.y <= -int(WORLD_HALF_EXTENT) or candidate.y >= int(WORLD_HALF_EXTENT) - 1:
			continue
		if _world_unit_fully_revealed(candidate):
			continue
		var surrounded := true
		for neighbour_offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not _world_unit_fully_revealed(candidate + neighbour_offset):
				surrounded = false
				break
		if not surrounded:
			continue
		_reveal_world_unit(candidate, newly_revealed_cells)
		filled_hole = true
	return filled_hole


func _world_unit_fully_revealed(world_unit: Vector2i) -> bool:
	var base_cell := world_unit * 2
	return (
		_revealed_fog_cells.has(base_cell)
		and _revealed_fog_cells.has(base_cell + Vector2i(1, 0))
		and _revealed_fog_cells.has(base_cell + Vector2i(0, 1))
		and _revealed_fog_cells.has(base_cell + Vector2i(1, 1))
	)


func _reveal_world_unit(world_unit: Vector2i, newly_revealed_cells: Array[Vector2i]) -> void:
	var base_cell := world_unit * 2
	for sub_x in 2:
		for sub_z in 2:
			var fog_cell := base_cell + Vector2i(sub_x, sub_z)
			if _revealed_fog_cells.has(fog_cell):
				continue
			_revealed_fog_cells[fog_cell] = true
			newly_revealed_cells.append(fog_cell)


func _update_revealed_entity_visibility() -> void:
	for item in _items:
		if is_instance_valid(item):
			item.visible = not item.is_carried and _is_world_position_revealed(item.global_position)
	_refresh_planned_building_visibility()


func _is_world_position_revealed(world_position: Vector3) -> bool:
	var fog_cell := Vector2i(
		floori(world_position.x / FOG_CELL_SIZE),
		floori(world_position.z / FOG_CELL_SIZE)
	)
	return _revealed_fog_cells.has(fog_cell)


func _create_path_preview() -> void:
	_path_overlay_layer = CanvasLayer.new()
	_path_overlay_layer.name = "ProjectedRoutePreview"
	_path_overlay_layer.layer = 90
	add_child(_path_overlay_layer)


func _ensure_path_screen_item(item_index: int) -> void:
	while _path_screen_lines.size() <= item_index:
		var route_line := Line2D.new()
		route_line.name = "ContinuousRouteLine%d" % (_path_screen_lines.size() + 1)
		route_line.width = CITIZEN_PATH_LINE_WIDTH_PIXELS
		route_line.default_color = Color.WHITE
		route_line.antialiased = false
		route_line.joint_mode = Line2D.LINE_JOINT_BEVEL
		route_line.begin_cap_mode = Line2D.LINE_CAP_NONE
		route_line.end_cap_mode = Line2D.LINE_CAP_NONE
		_path_overlay_layer.add_child(route_line)
		_path_screen_lines.append(route_line)
		var target_dot := Polygon2D.new()
		target_dot.name = "RouteTargetDot%d" % (_path_screen_targets.size() + 1)
		target_dot.color = Color.WHITE
		var dot_points := PackedVector2Array()
		for point_index in 12:
			var angle := TAU * float(point_index) / 12.0
			dot_points.append(Vector2(cos(angle), sin(angle)) * 5.0)
		target_dot.polygon = dot_points
		_path_overlay_layer.add_child(target_dot)
		_path_screen_targets.append(target_dot)


func _update_path_preview() -> void:
	_update_citizen_selection_preview()
	var visible_route_count := 0
	for citizen in _selected_citizens:
		if not is_instance_valid(citizen) or not citizen.has_active_route():
			continue
		var route_points := citizen.route_points()
		if route_points.size() < 2:
			continue
		var screen_points := PackedVector2Array()
		for route_point in route_points:
			var raised_point := route_point + Vector3.UP * 0.09
			if _camera.is_position_behind(raised_point):
				screen_points.clear()
				break
			screen_points.append(_camera.unproject_position(raised_point).round())
		if screen_points.size() < 2:
			continue
		_ensure_path_screen_item(visible_route_count)
		var route_line := _path_screen_lines[visible_route_count]
		var target_dot := _path_screen_targets[visible_route_count]
		route_line.points = screen_points
		route_line.visible = true
		target_dot.position = screen_points[-1]
		target_dot.visible = true
		visible_route_count += 1
	for hidden_index in range(visible_route_count, _path_screen_lines.size()):
		_path_screen_lines[hidden_index].visible = false
		_path_screen_targets[hidden_index].visible = false


func _ensure_citizen_selection_screen_item(item_index: int) -> void:
	while _citizen_selection_screen_lines.size() <= item_index:
		var selection_line := Line2D.new()
		selection_line.name = "CitizenSelectionCircle%d" % (
			_citizen_selection_screen_lines.size() + 1
		)
		selection_line.width = CITIZEN_SELECTION_LINE_WIDTH_PIXELS
		selection_line.default_color = Color.WHITE
		selection_line.antialiased = false
		selection_line.joint_mode = Line2D.LINE_JOINT_BEVEL
		selection_line.begin_cap_mode = Line2D.LINE_CAP_NONE
		selection_line.end_cap_mode = Line2D.LINE_CAP_NONE
		_path_overlay_layer.add_child(selection_line)
		_citizen_selection_screen_lines.append(selection_line)


func _update_citizen_selection_preview() -> void:
	var visible_selection_count := 0
	for citizen in _selected_citizens:
		if not is_instance_valid(citizen):
			continue
		var screen_points := PackedVector2Array()
		for point_index in CITIZEN_SELECTION_POINT_COUNT + 1:
			var angle := TAU * float(point_index) / float(CITIZEN_SELECTION_POINT_COUNT)
			var world_point := citizen.global_position + Vector3(
				cos(angle) * CITIZEN_SELECTION_RADIUS_WORLD,
				0.045,
				sin(angle) * CITIZEN_SELECTION_RADIUS_WORLD
			)
			if _camera.is_position_behind(world_point):
				screen_points.clear()
				break
			screen_points.append(_camera.unproject_position(world_point).round())
		if screen_points.size() != CITIZEN_SELECTION_POINT_COUNT + 1:
			continue
		_ensure_citizen_selection_screen_item(visible_selection_count)
		var selection_line := _citizen_selection_screen_lines[visible_selection_count]
		selection_line.points = screen_points
		selection_line.visible = true
		visible_selection_count += 1
	for hidden_index in range(visible_selection_count, _citizen_selection_screen_lines.size()):
		_citizen_selection_screen_lines[hidden_index].visible = false


func _create_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color("80b9d6")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Palette.FOG_AND_SHADOW
	_environment.ambient_light_energy = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	_sun.light_energy = 1.15
	_sun.shadow_enabled = true
	_sun.shadow_opacity = 1.0
	_sun.shadow_blur = 0.0
	# Clouds use their own overlay and do not cast directional shadows. Limiting
	# this range to the playable surface gives ordinary shadows much more shadow-
	# map precision and prevents granular midday sand.
	_sun.directional_shadow_max_distance = 48.0
	_sun.directional_shadow_blend_splits = false
	add_child(_sun)


func _update_day_night() -> void:
	var day_phase := fmod(_elapsed, DAY_LENGTH_SECONDS) / DAY_LENGTH_SECONDS
	var sun_height := sin(day_phase * TAU)
	var daylight := smoothstep(-0.2, 0.2, sun_height)
	var surface_colour := _day_cycle_colour(
		day_phase,
		Palette.MORNING_SURFACE,
		Palette.SAND_SURFACE,
		Palette.EVENING_SURFACE,
		Palette.NIGHT_SURFACE
	)
	var shadow_colour := _day_cycle_colour(
		day_phase,
		Palette.MORNING_SHADOW,
		Palette.FOG_AND_SHADOW,
		Palette.EVENING_SHADOW,
		Palette.NIGHT_FOG_AND_SHADOW
	)
	var light_colour := _day_cycle_colour(
		day_phase,
		Palette.MORNING_LIGHT,
		Palette.SUN,
		Palette.EVENING_LIGHT,
		Palette.NIGHT_LIGHT
	)
	var sky_colour := _day_cycle_colour(
		day_phase,
		Palette.MORNING_SKY,
		Color("80b9d6"),
		Palette.EVENING_SKY,
		Palette.NIGHT_SKY
	)
	# Rotation around X carries the light from the eastern horizon, overhead,
	# to the western horizon, then beneath the world during the night half.
	_sun.rotation_degrees = Vector3(-day_phase * 360.0, -90.0, 0.0)
	_sun.light_color = light_colour
	_sun.light_energy = 1.15 * daylight
	_environment.background_color = sky_colour
	_environment.ambient_light_color = light_colour
	_environment.ambient_light_energy = lerpf(0.12, 0.55, daylight)
	if is_instance_valid(_ground_material):
		_ground_material.set_shader_parameter("daylight", daylight)
		_ground_material.set_shader_parameter("surface_color", surface_colour)
		_ground_material.set_shader_parameter("shadow_color", shadow_colour)
	for item in _items:
		if is_instance_valid(item) and item.item_kind == "stone":
			item.set_limestone_cycle(
				daylight,
				surface_colour,
				_sun.global_transform.basis.z.normalized()
			)
	if is_instance_valid(_fog_material):
		_fog_material.set_shader_parameter("fog_color", shadow_colour)
	if is_instance_valid(_day_night_wheel):
		_day_night_wheel.rotation = day_phase * TAU
	if is_instance_valid(_compass_glass):
		_compass_glass.visible = daylight > 0.08
		_compass_glass.rotation.y = day_phase * TAU
	if is_instance_valid(_compass_glass_mesh):
		var reflection_width := lerpf(0.54, 0.1, clampf(maxf(sun_height, 0.0), 0.0, 1.0))
		_compass_glass_mesh.size = Vector2(1.8, reflection_width)


func _day_cycle_colour(
	day_phase: float,
	morning: Color,
	day: Color,
	evening: Color,
	night: Color
) -> Color:
	if day_phase < 0.12:
		return morning.lerp(day, smoothstep(0.0, 0.12, day_phase))
	if day_phase < 0.38:
		return day
	if day_phase < 0.5:
		return day.lerp(evening, smoothstep(0.38, 0.5, day_phase))
	if day_phase < 0.62:
		return evening.lerp(night, smoothstep(0.5, 0.62, day_phase))
	if day_phase < 0.86:
		return night
	return night.lerp(morning, smoothstep(0.86, 1.0, day_phase))


func request_actor_message(
	actor: Node3D,
	message_id: String,
	cluster_scope := "world",
	options: Dictionary = {}
) -> String:
	## Public bridge for citizens, buildings, and future Utility simulations.
	## Reposting a persistent need refreshes its TTL; stopping the refresh lets
	## the stale request remove itself from the queue.
	if not is_instance_valid(_actor_message_bus):
		return ""
	var resolved_options := options.duplicate(true)
	resolved_options["cluster_scope"] = cluster_scope
	return _actor_message_bus.post_message(actor, message_id, resolved_options)


func clear_actor_message(actor: Node3D, message_id: String, cluster_scope := "world") -> void:
	if is_instance_valid(_actor_message_bus):
		_actor_message_bus.clear_message(actor, message_id, cluster_scope)


func _create_actor_speech_system() -> void:
	_actor_message_bus = ActorMessageBusScript.new() as ActorMessageBus
	_actor_message_bus.name = "ActorMessageBus"
	add_child(_actor_message_bus)
	_speech_bubble_overlay = SpeechBubbleOverlayScript.new() as SpeechBubbleOverlay
	add_child(_speech_bubble_overlay)
	_speech_bubble_overlay.configure(_camera, self, _actor_message_bus)


func _next_speech_command_scope() -> String:
	_speech_command_sequence += 1
	return "command:%d" % _speech_command_sequence


func _create_interface() -> void:
	var selection_layer := CanvasLayer.new()
	selection_layer.layer = 50
	add_child(selection_layer)
	_selection_box = Panel.new()
	_selection_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_box.visible = false
	var selection_style := StyleBoxFlat.new()
	selection_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	selection_style.border_color = Color.WHITE
	selection_style.border_width_left = 1
	selection_style.border_width_top = 1
	selection_style.border_width_right = 1
	selection_style.border_width_bottom = 1
	_selection_box.add_theme_stylebox_override("panel", selection_style)
	selection_layer.add_child(_selection_box)
	_rts_count_badge = _create_count_badge(
		selection_layer,
		Vector2.ZERO,
		Vector2(18.0, 18.0),
		9,
		Palette.HOME_DOORWAY
	)
	_rts_count_badge.name = "CitizenSelectionCountBadge"
	_rts_count_badge.custom_minimum_size = Vector2(18.0, 18.0)
	_rts_count_badge.clip_text = true
	_rts_count_badge.add_theme_font_size_override("font_size", 11)
	_goods_count_badge = _create_count_badge(
		selection_layer,
		Vector2(62.0, 20.0),
		Vector2(48.0, 32.0),
		6,
		Palette.WOODEN_ROOF
	)
	_day_label = Label.new()
	_day_label.name = "DayCount"
	_day_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_day_label.position = Vector2(-27.0, 50.0)
	_day_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_label.add_theme_font_size_override("font_size", 16)
	_day_label.add_theme_color_override("font_color", Color.BLACK)
	selection_layer.add_child(_day_label)
	_create_day_night_wheel(selection_layer)
	_create_compass(selection_layer)
	_create_build_stamp(selection_layer)
	_create_building_hotkey_hint(selection_layer)
	_create_world_progress_layer()
	_create_top_toolbar()
	_create_hover_tooltip()

	var layer := CanvasLayer.new()
	layer.visible = SHOW_DEBUG_OVERLAY
	add_child(layer)

	var title := Label.new()
	title.text = UIText.text(UIText.PROTOTYPE_TITLE_TEXT)
	title.position = Vector2(18, 16)
	title.add_theme_font_size_override("font_size", 24)
	layer.add_child(title)

	var instructions := Label.new()
	instructions.text = UIText.text(UIText.PROTOTYPE_INSTRUCTIONS_TEXT)
	instructions.position = Vector2(18, 52)
	instructions.add_theme_font_size_override("font_size", 15)
	layer.add_child(instructions)

	_ui_mode = Label.new()
	_ui_mode.position = Vector2(18, 104)
	_ui_mode.add_theme_font_size_override("font_size", 17)
	layer.add_child(_ui_mode)

	_ui_status = Label.new()
	_ui_status.position = Vector2(18, 132)
	_ui_status.add_theme_font_size_override("font_size", 17)
	layer.add_child(_ui_status)

	_ui_resources = Label.new()
	_ui_resources.position = Vector2(18, 160)
	_ui_resources.add_theme_font_size_override("font_size", 17)
	layer.add_child(_ui_resources)


func _create_day_night_wheel(parent: Node) -> void:
	var wheel_container := Control.new()
	wheel_container.name = "DayNightWheelContainer"
	wheel_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wheel_container.position = Vector2(-21.5, 6.0)
	wheel_container.size = Vector2(43.0, 43.0)
	wheel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(wheel_container)

	var wheel_image := Image.create(43, 43, false, Image.FORMAT_RGBA8)
	wheel_image.fill(Color.TRANSPARENT)
	for pixel_x in 43:
		for pixel_y in 43:
			var offset := Vector2(float(pixel_x) - 21.0, float(pixel_y) - 21.0)
			if offset.length() > 18.5:
				continue
			var wheel_colour := Palette.SUN if pixel_x < 21 else Palette.NIGHT_SKY
			if offset.length() >= 16.5:
				wheel_colour = Color.BLACK
			wheel_image.set_pixel(pixel_x, pixel_y, wheel_colour)
	_day_night_wheel = TextureRect.new()
	_day_night_wheel.name = "RotatingDayNightWheel"
	_day_night_wheel.texture = ImageTexture.create_from_image(wheel_image)
	_day_night_wheel.size = Vector2(43.0, 43.0)
	_day_night_wheel.pivot_offset = Vector2(21.5, 21.5)
	_day_night_wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wheel_container.add_child(_day_night_wheel)

	var sun_marker := Panel.new()
	sun_marker.name = "FixedSunMarker"
	sun_marker.position = Vector2(16.0, -1.0)
	sun_marker.size = Vector2(10.0, 10.0)
	sun_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sun_style := StyleBoxFlat.new()
	sun_style.bg_color = Palette.SUN
	sun_style.border_color = Color.BLACK
	sun_style.set_border_width_all(int(UI_OUTLINE_PIXELS))
	sun_style.corner_radius_top_left = 5
	sun_style.corner_radius_top_right = 5
	sun_style.corner_radius_bottom_left = 5
	sun_style.corner_radius_bottom_right = 5
	sun_marker.add_theme_stylebox_override("panel", sun_style)
	wheel_container.add_child(sun_marker)


func _create_compass(parent: Node) -> void:
	_compass_viewport = SubViewport.new()
	_compass_viewport.name = "CompassViewport"
	_compass_viewport.size = Vector2i(COMPASS_DIAMETER_PIXELS, COMPASS_DIAMETER_PIXELS)
	_compass_viewport.transparent_bg = true
	_compass_viewport.own_world_3d = true
	_compass_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_compass_viewport)

	var compass_root := Node3D.new()
	compass_root.name = "GroundParallelCompass"
	_compass_viewport.add_child(compass_root)
	_compass_hover_outline = _create_compass_hover_silhouette()
	compass_root.add_child(_compass_hover_outline)
	compass_root.add_child(_create_compass_side_wall(
		0.9, 0.0, 0.54, 32, Palette.TOOL_METAL.darkened(0.28)
	))
	compass_root.add_child(_create_compass_ring(
		0.9, 0.74, 32, Palette.TOOL_METAL, 0.54
	))
	compass_root.add_child(_create_compass_disc(
		0.74, 32, Palette.FOG_AND_SHADOW.lightened(0.28), 0.42
	))
	compass_root.add_child(_create_compass_triangle(true))
	compass_root.add_child(_create_compass_triangle(false))

	_compass_glass = MeshInstance3D.new()
	_compass_glass.name = "SemiTransparentSunGlassReflection"
	_compass_glass_mesh = QuadMesh.new()
	_compass_glass_mesh.size = Vector2(1.8, 0.14)
	_compass_glass_mesh.orientation = PlaneMesh.FACE_Y
	_compass_glass.mesh = _compass_glass_mesh
	_compass_glass.position.y = 0.565
	_compass_glass.material_override = _compass_material(Color(1.0, 1.0, 1.0, 0.5), true)
	compass_root.add_child(_compass_glass)

	_compass_camera = Camera3D.new()
	_compass_camera.name = "CompassCamera"
	_compass_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_compass_camera.size = 2.35
	_compass_camera.near = 0.05
	_compass_camera.far = 20.0
	_compass_camera.current = true
	_compass_viewport.add_child(_compass_camera)
	_update_compass_camera()

	var compass_button := TextureButton.new()
	compass_button.name = "ResetCameraCompass"
	compass_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	compass_button.position = Vector2(-84.0, -84.0)
	compass_button.size = Vector2(COMPASS_DIAMETER_PIXELS, COMPASS_DIAMETER_PIXELS)
	compass_button.ignore_texture_size = true
	compass_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	compass_button.texture_normal = _compass_viewport.get_texture()
	compass_button.tooltip_text = UIText.text(UIText.COMPASS_BUTTON_TOOLTIP_TEXT)
	compass_button.theme = PixelUI.tooltip_theme()
	compass_button.pressed.connect(_reset_camera_from_compass)
	compass_button.mouse_entered.connect(_set_compass_hover.bind(true))
	compass_button.mouse_exited.connect(_set_compass_hover.bind(false))
	compass_button.focus_entered.connect(_set_compass_hover.bind(true))
	compass_button.focus_exited.connect(_set_compass_hover.bind(false))
	parent.add_child(compass_button)


func _create_build_stamp(parent: Node) -> void:
	_build_stamp_label = Label.new()
	_build_stamp_label.name = "BuildStamp"
	_build_stamp_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_build_stamp_label.position = Vector2(-520.0, -29.0)
	_build_stamp_label.size = Vector2(420.0, 18.0)
	_build_stamp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_build_stamp_label.text = BuildInfo.inline_label()
	_build_stamp_label.add_theme_font_size_override("font_size", 12)
	_build_stamp_label.add_theme_color_override("font_color", Color("747e83"))
	parent.add_child(_build_stamp_label)


func _create_building_hotkey_hint(parent: Node) -> void:
	_building_hotkey_hint = PanelContainer.new()
	_building_hotkey_hint.name = "BuildingHotkeyHint"
	_building_hotkey_hint.visible = false
	_building_hotkey_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(0.02, 0.02, 0.02, 0.84)
	hint_style.border_color = Color.WHITE
	hint_style.set_border_width_all(int(UI_OUTLINE_PIXELS))
	hint_style.set_corner_radius_all(0)
	hint_style.content_margin_left = 7.0
	hint_style.content_margin_right = 7.0
	hint_style.content_margin_top = 4.0
	hint_style.content_margin_bottom = 4.0
	_building_hotkey_hint.add_theme_stylebox_override("panel", hint_style)
	parent.add_child(_building_hotkey_hint)
	_building_hotkey_hint_label = Label.new()
	_building_hotkey_hint_label.name = "RotateHotkey"
	_building_hotkey_hint_label.text = UIText.text(UIText.BUILDING_ROTATE_HOTKEY_TEXT)
	_building_hotkey_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_building_hotkey_hint_label.add_theme_font_size_override("font_size", 14)
	_building_hotkey_hint_label.add_theme_color_override("font_color", Color.WHITE)
	_building_hotkey_hint.add_child(_building_hotkey_hint_label)


func _update_building_hotkey_hint() -> void:
	if not is_instance_valid(_building_hotkey_hint) or not is_instance_valid(_camera):
		return
	if (
		not is_instance_valid(_selected_building)
		or _selected_world_object != _selected_building
		or _camera.is_position_behind(_selected_building.global_position)
	):
		_building_hotkey_hint.visible = false
		return
	_building_hotkey_hint.reset_size()
	var hint_size := _building_hotkey_hint.get_combined_minimum_size()
	_building_hotkey_hint.size = hint_size
	var screen_base := _camera.unproject_position(_selected_building.global_position)
	var viewport_size := Vector2(get_viewport().get_visible_rect().size)
	_building_hotkey_hint.position = Vector2(
		clampf(screen_base.x - hint_size.x * 0.5, 6.0, viewport_size.x - hint_size.x - 6.0),
		clampf(screen_base.y + 18.0, 6.0, viewport_size.y - hint_size.y - 6.0)
	)
	_building_hotkey_hint.visible = true


func _create_compass_hover_silhouette() -> MeshInstance3D:
	var outline_mesh := CylinderMesh.new()
	outline_mesh.top_radius = 0.9
	outline_mesh.bottom_radius = 0.9
	outline_mesh.height = 0.54
	outline_mesh.radial_segments = 32
	outline_mesh.rings = 1
	var outline := MeshInstance3D.new()
	outline.name = "ViewDependentCompassHoverOutline"
	outline.mesh = outline_mesh
	outline.position.y = 0.27
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var outline_shader := Shader.new()
	outline_shader.code = """
shader_type spatial;
render_mode unshaded, cull_front;

uniform float outline_pixels = 2.0;
uniform vec2 viewport_size = vec2(72.0);

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 projected_normal = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	float normal_length = length(projected_normal);
	if (normal_length > 0.0001) {
		projected_normal /= normal_length;
		clip_position.xy += projected_normal * clip_position.w * outline_pixels * 2.0 / viewport_size;
	}
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = vec3(1.0);
}
"""
	var outline_material := ShaderMaterial.new()
	outline_material.shader = outline_shader
	outline_material.set_shader_parameter("outline_pixels", UI_OUTLINE_PIXELS)
	outline_material.set_shader_parameter(
		"viewport_size", Vector2(COMPASS_DIAMETER_PIXELS, COMPASS_DIAMETER_PIXELS)
	)
	outline.material_override = outline_material
	outline.visible = false
	return outline


func _create_compass_disc(radius: float, side_count: int, colour: Color, height: float) -> MeshInstance3D:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side_index in side_count:
		var angle_a := TAU * float(side_index) / float(side_count)
		var angle_b := TAU * float(side_index + 1) / float(side_count)
		surface_tool.add_vertex(Vector3.ZERO + Vector3.UP * height)
		surface_tool.add_vertex(Vector3(cos(angle_b) * radius, height, sin(angle_b) * radius))
		surface_tool.add_vertex(Vector3(cos(angle_a) * radius, height, sin(angle_a) * radius))
	var instance := MeshInstance3D.new()
	instance.mesh = surface_tool.commit()
	instance.material_override = _compass_material(colour)
	return instance


func _create_compass_ring(
	outer_radius: float,
	inner_radius: float,
	side_count: int,
	colour: Color,
	height: float
) -> MeshInstance3D:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side_index in side_count:
		var angle_a := TAU * float(side_index) / float(side_count)
		var angle_b := TAU * float(side_index + 1) / float(side_count)
		var outer_a := Vector3(cos(angle_a) * outer_radius, height, sin(angle_a) * outer_radius)
		var outer_b := Vector3(cos(angle_b) * outer_radius, height, sin(angle_b) * outer_radius)
		var inner_a := Vector3(cos(angle_a) * inner_radius, height, sin(angle_a) * inner_radius)
		var inner_b := Vector3(cos(angle_b) * inner_radius, height, sin(angle_b) * inner_radius)
		surface_tool.add_vertex(outer_a)
		surface_tool.add_vertex(outer_b)
		surface_tool.add_vertex(inner_b)
		surface_tool.add_vertex(outer_a)
		surface_tool.add_vertex(inner_b)
		surface_tool.add_vertex(inner_a)
	var instance := MeshInstance3D.new()
	instance.mesh = surface_tool.commit()
	instance.material_override = _compass_material(colour)
	return instance


func _create_compass_side_wall(
	radius: float,
	bottom_height: float,
	top_height: float,
	side_count: int,
	colour: Color
) -> MeshInstance3D:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side_index in side_count:
		var angle_a := TAU * float(side_index) / float(side_count)
		var angle_b := TAU * float(side_index + 1) / float(side_count)
		var bottom_a := Vector3(cos(angle_a) * radius, bottom_height, sin(angle_a) * radius)
		var bottom_b := Vector3(cos(angle_b) * radius, bottom_height, sin(angle_b) * radius)
		var top_a := Vector3(cos(angle_a) * radius, top_height, sin(angle_a) * radius)
		var top_b := Vector3(cos(angle_b) * radius, top_height, sin(angle_b) * radius)
		surface_tool.add_vertex(bottom_a)
		surface_tool.add_vertex(top_b)
		surface_tool.add_vertex(bottom_b)
		surface_tool.add_vertex(bottom_a)
		surface_tool.add_vertex(top_a)
		surface_tool.add_vertex(top_b)
	var instance := MeshInstance3D.new()
	instance.mesh = surface_tool.commit()
	instance.material_override = _compass_material(colour)
	return instance


func _create_compass_triangle(points_north: bool) -> MeshInstance3D:
	var direction := -1.0 if points_north else 1.0
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.add_vertex(Vector3(-0.16, 0.435, direction * 0.03))
	surface_tool.add_vertex(Vector3(0.0, 0.435, direction * 0.62))
	surface_tool.add_vertex(Vector3(0.16, 0.435, direction * 0.03))
	var instance := MeshInstance3D.new()
	instance.name = "NorthNeedle" if points_north else "SouthNeedle"
	instance.mesh = surface_tool.commit()
	instance.material_override = _compass_material(
		Palette.WOMAN_CLOTHING if points_north else Palette.TOOL_METAL
	)
	return instance


func _compass_material(colour: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _update_compass_camera() -> void:
	if not is_instance_valid(_compass_camera):
		return
	var viewing_direction := _current_camera_offset().normalized()
	_compass_camera.position = viewing_direction * 4.0
	_compass_camera.look_at(Vector3.ZERO, Vector3.UP)


func _reset_camera_from_compass() -> void:
	_camera_yaw = DEFAULT_CAMERA_YAW
	_camera_pitch = DEFAULT_CAMERA_PITCH
	_update_camera_transform()


func _set_compass_hover(is_hovered: bool) -> void:
	if is_instance_valid(_compass_hover_outline):
		_compass_hover_outline.visible = is_hovered


func _create_world_progress_layer() -> void:
	_world_progress_layer = CanvasLayer.new()
	_world_progress_layer.name = "WorldProgressBars"
	_world_progress_layer.layer = 105
	add_child(_world_progress_layer)


func _create_top_toolbar() -> void:
	var toolbar_layer := CanvasLayer.new()
	toolbar_layer.name = "TopToolbar"
	toolbar_layer.layer = 110
	add_child(toolbar_layer)
	_create_toolbar_tooltip(toolbar_layer)
	_create_population_indicator(toolbar_layer)
	_top_toolbar = HBoxContainer.new()
	_top_toolbar.name = "TransparentTopToolbar"
	_top_toolbar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Keep the right edge fixed and let the toolbar grow towards the left. This
	# avoids losing the final buttons when optional controls become visible.
	_top_toolbar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_top_toolbar.offset_right = -10.0
	_top_toolbar.offset_top = 10.0
	_top_toolbar.add_theme_constant_override("separation", 8)
	toolbar_layer.add_child(_top_toolbar)

	_simulation_speed_button = _create_simulation_speed_button()
	_top_toolbar.add_child(_simulation_speed_button)

	_deconstruct_button = _create_toolbar_button(
		_create_toolbar_icon("deconstruct"),
		UIText.text(UIText.DECONSTRUCT_BUTTON_TOOLTIP_TEXT),
		false,
		_create_toolbar_icon("deconstruct_hover")
	)
	_deconstruct_button.name = "DeconstructButton"
	_deconstruct_button.visible = false
	_deconstruct_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deconstruct_button.pressed.connect(_deconstruct_selected_building)
	_top_toolbar.add_child(_deconstruct_button)

	_building_button = _create_toolbar_button(
		_create_toolbar_icon("building"),
		UIText.text(UIText.BUILD_BUTTON_TOOLTIP_TEXT),
		false,
		_create_toolbar_icon("building_hover")
	)
	_building_button.name = "BuildingModeButton"
	_building_button.toggle_mode = true
	_building_button.set_meta("pressed_icon", _create_toolbar_icon("building_active"))
	_building_button.pressed.connect(_toggle_build_menu)
	_top_toolbar.add_child(_building_button)
	_create_build_menu(toolbar_layer)

	var save_quit_icon := _create_toolbar_icon("save_quit")
	var save_quit_hover_icon := _create_toolbar_icon("save_quit_hover")
	var save_quit_button := _create_toolbar_button(
		save_quit_icon,
		UIText.text(UIText.EXIT_BUTTON_TOOLTIP_TEXT),
		false,
		save_quit_hover_icon
	)
	save_quit_button.name = "SaveQuitButton"
	save_quit_button.pressed.connect(_close_game)
	_top_toolbar.add_child(save_quit_button)


func _close_game() -> void:
	get_tree().quit()


func _create_population_indicator(toolbar_layer: CanvasLayer) -> void:
	var population_row := HBoxContainer.new()
	population_row.name = "PopulationIndicator"
	population_row.position = Vector2(10.0, 10.0)
	population_row.add_theme_constant_override("separation", 2)
	toolbar_layer.add_child(population_row)

	var population_icon := _create_toolbar_button(
		_create_toolbar_icon("population"),
		UIText.text(UIText.POPULATION_TOOLTIP_TEXT),
		false,
		_create_toolbar_icon("population_hover")
	)
	population_icon.name = "PopulationIcon"
	population_icon.focus_mode = Control.FOCUS_NONE
	population_row.add_child(population_icon)

	_population_count_label = Label.new()
	_population_count_label.name = "PopulationCount"
	_population_count_label.custom_minimum_size = Vector2(28.0, 44.0)
	_population_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_population_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_population_count_label.add_theme_font_size_override("font_size", 22)
	_population_count_label.add_theme_color_override("font_color", Color.BLACK)
	population_row.add_child(_population_count_label)


func _create_simulation_speed_button() -> Button:
	var button := Button.new()
	button.name = "SimulationSpeedButton"
	button.custom_minimum_size = Vector2(52.0, 44.0)
	button.size = Vector2(52.0, 44.0)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.flat = true
	button.text = _simulation_speed_text()
	button.tooltip_text = ""
	button.theme = PixelUI.tooltip_theme()
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_hover_color", Palette.HOME_DOORWAY)
	button.add_theme_color_override("font_focus_color", Palette.HOME_DOORWAY)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	var empty_style := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, empty_style)
	var hover_text := UIText.text(UIText.SIMULATION_SPEED_TOOLTIP_TEXT)
	button.mouse_entered.connect(_show_toolbar_tooltip.bind(button, hover_text))
	button.mouse_exited.connect(_hide_toolbar_tooltip)
	button.focus_entered.connect(_show_toolbar_tooltip.bind(button, hover_text))
	button.focus_exited.connect(_hide_toolbar_tooltip)
	button.pressed.connect(_cycle_simulation_speed)
	return button


func _simulation_speed_text() -> String:
	return "%d×" % int(_simulation_speed)


func _cycle_simulation_speed() -> void:
	var current_index := SIMULATION_SPEED_OPTIONS.find(_simulation_speed)
	var next_index := (current_index + 1) % SIMULATION_SPEED_OPTIONS.size()
	_set_simulation_speed(float(SIMULATION_SPEED_OPTIONS[next_index]))


func _set_simulation_speed(next_speed: float) -> void:
	if next_speed not in SIMULATION_SPEED_OPTIONS:
		return
	_simulation_speed = next_speed
	if is_instance_valid(_simulation_speed_button):
		_simulation_speed_button.text = _simulation_speed_text()
	for citizen in _citizens:
		if is_instance_valid(citizen):
			citizen.set_simulation_speed(_simulation_speed)
	for item in _items:
		if is_instance_valid(item):
			item.set_simulation_speed(_simulation_speed)


func _create_toolbar_button(
	icon_texture: ImageTexture,
	hover_text: String,
	is_disabled: bool,
	hover_icon: ImageTexture = null
) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(44.0, 44.0)
	button.size = Vector2(44.0, 44.0)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.icon = icon_texture
	button.set_meta("normal_icon", icon_texture)
	button.expand_icon = true
	button.flat = true
	# A dedicated tooltip is anchored beneath the complete rectangular hit area;
	# native pointer-relative placement could cover the icon itself.
	button.tooltip_text = ""
	button.theme = PixelUI.tooltip_theme()
	button.disabled = is_disabled
	button.add_theme_color_override("icon_disabled_color", Color.WHITE)
	var empty_style := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, empty_style)
	button.mouse_entered.connect(_show_toolbar_tooltip.bind(button, hover_text))
	button.mouse_exited.connect(_hide_toolbar_tooltip)
	button.focus_entered.connect(_show_toolbar_tooltip.bind(button, hover_text))
	button.focus_exited.connect(_hide_toolbar_tooltip)
	if hover_icon != null:
		button.set_meta("active_icon", hover_icon)
		button.mouse_entered.connect(_set_toolbar_button_icon.bind(button, hover_icon))
		button.mouse_exited.connect(_set_toolbar_button_icon.bind(button, icon_texture))
		button.focus_entered.connect(_set_toolbar_button_icon.bind(button, hover_icon))
		button.focus_exited.connect(_set_toolbar_button_icon.bind(button, icon_texture))
	return button


func _set_toolbar_button_icon(button: Button, next_icon: ImageTexture) -> void:
	if button.toggle_mode and button.button_pressed and button.has_meta("pressed_icon"):
		button.icon = button.get_meta("pressed_icon") as ImageTexture
	elif button.toggle_mode and button.button_pressed and button.has_meta("active_icon"):
		button.icon = button.get_meta("active_icon") as ImageTexture
	else:
		button.icon = next_icon


func _create_toolbar_tooltip(toolbar_layer: CanvasLayer) -> void:
	_toolbar_tooltip = PanelContainer.new()
	_toolbar_tooltip.name = "ToolbarTooltip"
	_toolbar_tooltip.visible = false
	_toolbar_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toolbar_tooltip.z_index = 20
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color.BLACK
	tooltip_style.border_color = Color.WHITE
	tooltip_style.set_border_width_all(int(UI_OUTLINE_PIXELS))
	tooltip_style.set_corner_radius_all(0)
	tooltip_style.set_content_margin_all(4.0)
	_toolbar_tooltip.add_theme_stylebox_override("panel", tooltip_style)
	toolbar_layer.add_child(_toolbar_tooltip)
	_toolbar_tooltip_label = Label.new()
	_toolbar_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toolbar_tooltip_label.add_theme_font_size_override("font_size", 14)
	_toolbar_tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	_toolbar_tooltip.add_child(_toolbar_tooltip_label)


func _show_toolbar_tooltip(button: Button, tooltip_text: String) -> void:
	if not is_instance_valid(_toolbar_tooltip) or tooltip_text.is_empty():
		return
	_toolbar_tooltip_label.text = tooltip_text
	_toolbar_tooltip.reset_size()
	var tooltip_size := _toolbar_tooltip.get_combined_minimum_size()
	_toolbar_tooltip.size = tooltip_size
	var button_rect := button.get_global_rect()
	var viewport_width := get_viewport().get_visible_rect().size.x
	_toolbar_tooltip.position = Vector2(
		clampf(
			button_rect.get_center().x - tooltip_size.x * 0.5,
			4.0,
			maxf(4.0, viewport_width - tooltip_size.x - 4.0)
		),
		button_rect.end.y + 5.0
	)
	_toolbar_tooltip.visible = true


func _hide_toolbar_tooltip() -> void:
	if is_instance_valid(_toolbar_tooltip):
		_toolbar_tooltip.visible = false


func _apply_pixel_font_to_controls(parent: Node) -> void:
	if parent is Control:
		PixelUI.apply(parent as Control)
	for child in parent.get_children():
		_apply_pixel_font_to_controls(child)


func _toggle_build_menu() -> void:
	if _build_mode:
		_leave_build_mode()
		return
	_enter_build_mode(false)
	if is_instance_valid(_build_menu):
		_build_menu.visible = true


func _deconstruct_selected_building() -> void:
	if (
		_selected_world_object is SupportConstructionSite
		or _selected_world_object is ExcavationSite
	):
		_try_delete_selected_object()


func _create_build_menu(toolbar_layer: CanvasLayer) -> void:
	_build_menu = PanelContainer.new()
	_build_menu.name = "BottomConstructionCatalog"
	_build_menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_build_menu.position = Vector2(-126.0, -62.0)
	_build_menu.visible = false
	_build_menu.theme = PixelUI.tooltip_theme()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color.BLACK
	panel_style.border_color = Color.WHITE
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(0)
	panel_style.set_content_margin_all(4.0)
	_build_menu.add_theme_stylebox_override("panel", panel_style)
	toolbar_layer.add_child(_build_menu)
	var catalog_row := HBoxContainer.new()
	catalog_row.name = "ConstructionCatalogRow"
	catalog_row.add_theme_constant_override("separation", 6)
	_build_menu.add_child(catalog_row)

	var excavation_button := _create_toolbar_button(
		_create_toolbar_icon("excavate"),
		UIText.text(UIText.EXCAVATE_TOOL_TOOLTIP_TEXT),
		false,
		_create_toolbar_icon("excavate_hover")
	)
	excavation_button.name = "ExcavateToolButton"
	excavation_button.pressed.connect(_enter_excavation_mode)
	catalog_row.add_child(excavation_button)

	var support_button := _create_toolbar_button(
		_create_toolbar_icon("support"),
		UIText.text(UIText.SUPPORT_NAME_TEXT),
		false
	)
	support_button.name = "PlaceSupportButton"
	support_button.pressed.connect(_enter_build_mode.bind(true))
	catalog_row.add_child(support_button)

	for unavailable_building in [
		["platform", UIText.SUPPORT_PLATFORM_NAME_TEXT, "SupportPlatformButton"],
		["pergola", UIText.PERGOLA_NAME_TEXT, "PergolaButton"],
		["house", UIText.LIVABLE_HOUSE_NAME_TEXT, "LivableHouseButton"],
	]:
		var unavailable_button := _create_toolbar_button(
			_create_toolbar_icon(str(unavailable_building[0])),
			UIText.text(str(unavailable_building[1])),
			true
		)
		unavailable_button.name = str(unavailable_building[2])
		unavailable_button.modulate = Color(1.0, 1.0, 1.0, 0.48)
		catalog_row.add_child(unavailable_button)


func _create_toolbar_icon(icon_kind: String) -> ImageTexture:
	var icon_image := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	icon_image.fill(Color.TRANSPARENT)
	if icon_kind in ["population", "population_hover"]:
		if icon_kind == "population_hover":
			_draw_icon_circle(icon_image, Vector2(20, 11), 5.0 + UI_OUTLINE_PIXELS, Color.WHITE)
			_draw_rounded_icon_line(icon_image, Vector2(14, 22), Vector2(26, 22), 3.0 + UI_OUTLINE_PIXELS, Color.WHITE)
			_draw_rounded_icon_line(icon_image, Vector2(20, 21), Vector2(20, 33), 5.0 + UI_OUTLINE_PIXELS, Color.WHITE)
		_draw_icon_circle(icon_image, Vector2(20, 11), 5.0, Color.BLACK)
		_draw_rounded_icon_line(icon_image, Vector2(14, 22), Vector2(26, 22), 3.0, Color.BLACK)
		_draw_rounded_icon_line(icon_image, Vector2(20, 21), Vector2(20, 33), 5.0, Color.BLACK)
	elif icon_kind in ["building", "building_hover", "building_active"]:
		var building_polygon := PackedVector2Array([
			Vector2(12, 18), Vector2(20, 10), Vector2(28, 18), Vector2(28, 31), Vector2(12, 31),
		])
		if icon_kind == "building_active":
			_fill_icon_polygon(icon_image, building_polygon, Color.BLACK)
		else:
			if icon_kind == "building_hover":
				_draw_building_outline(
					icon_image,
					BUILDING_ICON_STROKE_PIXELS + UI_OUTLINE_PIXELS * 2.0,
					Color.WHITE
				)
			_draw_building_outline(icon_image, BUILDING_ICON_STROKE_PIXELS, Color.BLACK)
	elif icon_kind in ["deconstruct", "deconstruct_hover"]:
		if icon_kind == "deconstruct_hover":
			_draw_rounded_icon_line(icon_image, Vector2(11, 10), Vector2(29, 10), 2.5 + UI_OUTLINE_PIXELS, Color.WHITE)
			_draw_rounded_icon_line(icon_image, Vector2(13, 12), Vector2(13, 30), 2.0 + UI_OUTLINE_PIXELS, Color.WHITE)
			_draw_rounded_icon_line(icon_image, Vector2(27, 12), Vector2(27, 30), 2.0 + UI_OUTLINE_PIXELS, Color.WHITE)
			_draw_rounded_icon_line(icon_image, Vector2(9, 31), Vector2(31, 9), 2.2 + UI_OUTLINE_PIXELS, Color.WHITE)
		_draw_rounded_icon_line(icon_image, Vector2(11, 10), Vector2(29, 10), 2.5, Palette.ROOF_LOG)
		_draw_rounded_icon_line(icon_image, Vector2(13, 12), Vector2(13, 30), 2.0, Palette.ROOF_LOG)
		_draw_rounded_icon_line(icon_image, Vector2(27, 12), Vector2(27, 30), 2.0, Palette.ROOF_LOG)
		_draw_rounded_icon_line(icon_image, Vector2(9, 31), Vector2(31, 9), 2.2, Palette.WOMAN_CLOTHING)
	elif icon_kind in ["excavate", "excavate_hover"]:
		if icon_kind == "excavate_hover":
			_draw_rounded_icon_line(icon_image, Vector2(27, 7), Vector2(13, 27), 2.2 + UI_OUTLINE_PIXELS, Color.WHITE)
			_draw_rounded_icon_line(icon_image, Vector2(10, 26), Vector2(17, 33), 4.0 + UI_OUTLINE_PIXELS, Color.WHITE)
		_draw_rounded_icon_line(icon_image, Vector2(27, 7), Vector2(13, 27), 2.2, Palette.ROOF_LOG)
		_draw_rounded_icon_line(icon_image, Vector2(10, 26), Vector2(17, 33), 4.0, Palette.TOOL_METAL)
	elif icon_kind == "support":
		for post_x in [12.0, 28.0]:
			_draw_rounded_icon_line(
				icon_image, Vector2(post_x, 12), Vector2(post_x, 32), 2.5, Palette.ROOF_LOG
			)
		_draw_rounded_icon_line(icon_image, Vector2(10, 13), Vector2(30, 13), 2.5, Palette.ROOF_LOG)
	elif icon_kind == "platform":
		for post_x in [12.0, 28.0]:
			_draw_rounded_icon_line(icon_image, Vector2(post_x, 17), Vector2(post_x, 32), 2.2, Palette.ROOF_LOG)
		_draw_rounded_icon_line(icon_image, Vector2(9, 15), Vector2(31, 15), 4.0, Palette.WOODEN_ROOF)
	elif icon_kind == "pergola":
		for post_x in [12.0, 28.0]:
			_draw_rounded_icon_line(icon_image, Vector2(post_x, 16), Vector2(post_x, 32), 2.2, Palette.ROOF_LOG)
		_draw_rounded_icon_line(icon_image, Vector2(9, 14), Vector2(31, 14), 3.5, Palette.SUN)
	elif icon_kind == "house":
		_draw_rounded_icon_line(icon_image, Vector2(12, 18), Vector2(12, 32), 2.3, Palette.FOG_AND_SHADOW)
		_draw_rounded_icon_line(icon_image, Vector2(28, 18), Vector2(28, 32), 2.3, Palette.FOG_AND_SHADOW)
		_draw_rounded_icon_line(icon_image, Vector2(12, 31), Vector2(28, 31), 2.3, Palette.FOG_AND_SHADOW)
		_draw_rounded_icon_line(icon_image, Vector2(9, 19), Vector2(20, 9), 2.8, Palette.WOMAN_CLOTHING)
		_draw_rounded_icon_line(icon_image, Vector2(20, 9), Vector2(31, 19), 2.8, Palette.WOMAN_CLOTHING)
	elif icon_kind == "save_quit":
		# Slightly unequal strokes keep the X hand-drawn. Its resting state is
		# black only; the shared cursor-width white silhouette belongs to hover.
		_draw_rounded_icon_line(icon_image, Vector2(10, 9), Vector2(31, 30), 3.0, Color.BLACK)
		_draw_rounded_icon_line(icon_image, Vector2(30, 10), Vector2(9, 31), 2.6, Color.BLACK)
	else:
		_draw_rounded_icon_line(
			icon_image, Vector2(10, 9), Vector2(31, 30), 3.0 + UI_OUTLINE_PIXELS, Color.WHITE
		)
		_draw_rounded_icon_line(
			icon_image, Vector2(30, 10), Vector2(9, 31), 2.6 + UI_OUTLINE_PIXELS, Color.WHITE
		)
		_draw_rounded_icon_line(icon_image, Vector2(10, 9), Vector2(31, 30), 3.0, Color.BLACK)
		_draw_rounded_icon_line(icon_image, Vector2(30, 10), Vector2(9, 31), 2.6, Color.BLACK)
	return ImageTexture.create_from_image(icon_image)


func _draw_building_outline(target_image: Image, stroke_width: float, colour: Color) -> void:
	# Five edges only: the slightly overhanging roof replaces the ceiling line.
	var stroke_radius := stroke_width * 0.5
	_draw_rounded_icon_line(target_image, Vector2(12, 18), Vector2(12, 31), stroke_radius, colour)
	_draw_rounded_icon_line(target_image, Vector2(12, 31), Vector2(28, 31), stroke_radius, colour)
	_draw_rounded_icon_line(target_image, Vector2(28, 31), Vector2(28, 18), stroke_radius, colour)
	_draw_rounded_icon_line(target_image, Vector2(9, 19), Vector2(20, 9), stroke_radius, colour)
	_draw_rounded_icon_line(target_image, Vector2(20, 9), Vector2(31, 19), stroke_radius, colour)


func _fill_icon_polygon(target_image: Image, polygon: PackedVector2Array, colour: Color) -> void:
	for pixel_x in target_image.get_width():
		for pixel_y in target_image.get_height():
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			if Geometry2D.is_point_in_polygon(pixel_centre, polygon):
				target_image.set_pixel(pixel_x, pixel_y, colour)
	_draw_building_outline(target_image, BUILDING_ICON_STROKE_PIXELS, colour)


func _draw_icon_circle(target_image: Image, centre: Vector2, radius: float, colour: Color) -> void:
	for pixel_x in target_image.get_width():
		for pixel_y in target_image.get_height():
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			if pixel_centre.distance_to(centre) <= radius:
				target_image.set_pixel(pixel_x, pixel_y, colour)


func _draw_rounded_icon_line(
	target_image: Image,
	line_start: Vector2,
	line_end: Vector2,
	radius: float,
	colour: Color
) -> void:
	var line_offset := line_end - line_start
	var line_length_squared := line_offset.length_squared()
	for pixel_x in target_image.get_width():
		for pixel_y in target_image.get_height():
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			var projection := 0.0
			if line_length_squared > 0.0:
				projection = clampf(
					(pixel_centre - line_start).dot(line_offset) / line_length_squared,
					0.0,
					1.0
				)
			var nearest_point := line_start + line_offset * projection
			if pixel_centre.distance_to(nearest_point) <= radius:
				target_image.set_pixel(pixel_x, pixel_y, colour)


func _create_hover_tooltip() -> void:
	var tooltip_layer := CanvasLayer.new()
	tooltip_layer.name = "WorldHoverTooltip"
	tooltip_layer.layer = 120
	add_child(tooltip_layer)
	_hover_tooltip = Label.new()
	_hover_tooltip.name = "HoverName"
	_hover_tooltip.visible = false
	_hover_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_tooltip.add_theme_font_size_override("font_size", 16)
	_hover_tooltip.add_theme_color_override("font_color", Color.BLACK)
	_hover_tooltip.add_theme_constant_override("outline_size", 0)
	var tooltip_style := StyleBoxEmpty.new()
	tooltip_style.content_margin_left = 2.0
	tooltip_style.content_margin_right = 2.0
	tooltip_style.content_margin_top = 2.0
	tooltip_style.content_margin_bottom = 2.0
	_hover_tooltip.add_theme_stylebox_override("normal", tooltip_style)
	tooltip_layer.add_child(_hover_tooltip)


func _create_custom_cursor() -> void:
	var cursor_image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	cursor_image.fill(Color.TRANSPARENT)
	# The cursor keeps a hard-pixel black-and-white treatment, but its core
	# polygons are expanded by a circular radius so the tip, tail, and joints
	# feel friendly instead of knife-sharp. No fractional alpha is introduced.
	var outer_core := PackedVector2Array([
		Vector2(5, 4), Vector2(5, 34), Vector2(12, 28), Vector2(21, 44),
		Vector2(26, 41), Vector2(18, 26), Vector2(32, 26),
	])
	var inner_core := PackedVector2Array([
		Vector2(8, 9), Vector2(8, 29), Vector2(13, 25), Vector2(21, 39),
		Vector2(22, 38), Vector2(15, 24), Vector2(27, 24),
	])
	for pixel_x in 48:
		for pixel_y in 48:
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			if _is_point_in_rounded_polygon(pixel_centre, outer_core, 2.75):
				cursor_image.set_pixel(pixel_x, pixel_y, Color.WHITE)
			if _is_point_in_rounded_polygon(pixel_centre, inner_core, 1.5):
				cursor_image.set_pixel(pixel_x, pixel_y, Color.BLACK)
	_cursor_texture = ImageTexture.create_from_image(cursor_image)
	Input.set_custom_mouse_cursor(_cursor_texture, Input.CURSOR_ARROW, Vector2(5.0, 4.0))


func _is_point_in_rounded_polygon(
	point: Vector2,
	polygon: PackedVector2Array,
	radius: float
) -> bool:
	if Geometry2D.is_point_in_polygon(point, polygon):
		return true
	var radius_squared := radius * radius
	for point_index in polygon.size():
		var edge_start := polygon[point_index]
		var edge_end := polygon[(point_index + 1) % polygon.size()]
		if _distance_squared_to_segment(point, edge_start, edge_end) <= radius_squared:
			return true
	return false


func _distance_squared_to_segment(point: Vector2, edge_start: Vector2, edge_end: Vector2) -> float:
	var edge := edge_end - edge_start
	var edge_length_squared := edge.length_squared()
	if edge_length_squared <= 0.0001:
		return point.distance_squared_to(edge_start)
	var edge_progress := clampf((point - edge_start).dot(edge) / edge_length_squared, 0.0, 1.0)
	return point.distance_squared_to(edge_start + edge * edge_progress)


func _create_first_launch_onboarding() -> void:
	_onboarding_layer = CanvasLayer.new()
	_onboarding_layer.name = "FirstLaunchOnboarding"
	_onboarding_layer.layer = 140
	_onboarding_layer.visible = false
	add_child(_onboarding_layer)

	var panel := Panel.new()
	panel.name = "KeyboardLesson"
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-260.0, -270.0)
	panel.size = Vector2(520.0, 245.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.03, 0.03, 0.78)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	_onboarding_layer.add_child(panel)

	var title := Label.new()
	title.text = UIText.text(UIText.ONBOARDING_TITLE_TEXT)
	title.position = Vector2(22.0, 14.0)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(title)
	var explanation := Label.new()
	explanation.text = UIText.text(UIText.ONBOARDING_EXPLANATION_TEXT)
	explanation.position = Vector2(22.0, 42.0)
	explanation.add_theme_font_size_override("font_size", 13)
	explanation.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(explanation)

	_create_blank_keyboard_row(panel, [31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0], Vector2(22.0, 73.0))
	_create_blank_keyboard_row(panel, [31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0], Vector2(39.0, 111.0))
	_create_blank_keyboard_row(panel, [31.0, 31.0, 31.0, 31.0, 31.0, 31.0, 31.0], Vector2(56.0, 149.0))
	# Wider blank modifiers and the long Space shape remain recognizable without
	# prescribing key bindings before the player needs them.
	_create_blank_keyboard_row(panel, [46.0, 46.0, 170.0, 46.0, 46.0], Vector2(39.0, 187.0))

	var dismiss_button := Button.new()
	dismiss_button.text = UIText.text(UIText.ONBOARDING_DISMISS_BUTTON_TEXT)
	dismiss_button.position = Vector2(426.0, 199.0)
	dismiss_button.size = Vector2(72.0, 32.0)
	dismiss_button.pressed.connect(_complete_onboarding)
	panel.add_child(dismiss_button)

	var onboarding_state := ConfigFile.new()
	var has_completed := false
	if onboarding_state.load(ONBOARDING_STATE_PATH) == OK:
		has_completed = bool(onboarding_state.get_value("onboarding", "wasd_complete", false))
	if not has_completed:
		_show_onboarding()


func _create_blank_keyboard_row(parent: Control, key_widths: Array[float], row_position: Vector2) -> void:
	var row := HBoxContainer.new()
	row.name = "BlankKeyboardRow"
	row.position = row_position
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)
	for key_width in key_widths:
		var key := Label.new()
		key.name = "BlankKey"
		key.custom_minimum_size = Vector2(key_width, 31.0)
		key.text = ""
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var key_style := StyleBoxFlat.new()
		key_style.bg_color = Color(0.34, 0.34, 0.34, 0.62)
		key_style.border_color = Color.WHITE
		key_style.border_width_left = 1
		key_style.border_width_top = 1
		key_style.border_width_right = 1
		key_style.border_width_bottom = 1
		key_style.corner_radius_top_left = 5
		key_style.corner_radius_top_right = 5
		key_style.corner_radius_bottom_left = 5
		key_style.corner_radius_bottom_right = 5
		key.add_theme_stylebox_override("normal", key_style)
		row.add_child(key)


func _show_onboarding() -> void:
	if is_instance_valid(_onboarding_layer):
		_onboarding_layer.visible = true


func _complete_onboarding() -> void:
	if is_instance_valid(_onboarding_layer):
		_onboarding_layer.visible = false
	var onboarding_state := ConfigFile.new()
	onboarding_state.set_value("onboarding", "wasd_complete", true)
	onboarding_state.save(ONBOARDING_STATE_PATH)


func _create_count_badge(
	parent: Node,
	screen_position: Vector2,
	badge_size: Vector2,
	corner_radius: int,
	background_colour: Color
) -> Label:
	var badge := Label.new()
	badge.position = screen_position
	badge.size = badge_size
	badge.custom_minimum_size = badge_size
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = background_colour
	badge_style.corner_radius_top_left = corner_radius
	badge_style.corner_radius_top_right = corner_radius
	badge_style.corner_radius_bottom_left = corner_radius
	badge_style.corner_radius_bottom_right = corner_radius
	badge_style.content_margin_left = 3.0
	badge_style.content_margin_right = 3.0
	badge.add_theme_stylebox_override("normal", badge_style)
	parent.add_child(badge)
	return badge


func _create_pixel_filter() -> void:
	var pixel_layer := CanvasLayer.new()
	pixel_layer.name = "PixelFilter"
	pixel_layer.layer = 100
	add_child(pixel_layer)

	var pixel_rect := ColorRect.new()
	pixel_rect.name = "NearestPixelFilter"
	pixel_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_layer.add_child(pixel_rect)
	pixel_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var pixel_shader := Shader.new()
	pixel_shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_block_size = 2.0;

void fragment() {
	vec2 block_uv = SCREEN_PIXEL_SIZE * pixel_block_size;
	vec2 sampled_uv = (floor(SCREEN_UV / block_uv) + vec2(0.5)) * block_uv;
	COLOR = textureLod(screen_texture, sampled_uv, 0.0);
}
"""
	var pixel_material := ShaderMaterial.new()
	pixel_material.shader = pixel_shader
	pixel_material.set_shader_parameter("pixel_block_size", PIXEL_BLOCK_SIZE)
	pixel_rect.material = pixel_material


func _update_interface() -> void:
	if _ui_mode == null:
		return
	if _build_mode:
		_ui_mode.text = UIText.text(UIText.BUILDING_MODE_LABEL_TEXT)
	elif not _selected_citizens.is_empty():
		_ui_mode.text = UIText.text(UIText.CITIZEN_MODE_LABEL_TEXT)
	else:
		_ui_mode.text = UIText.text(UIText.COMMAND_MODE_LABEL_TEXT)
	_rts_count_badge.visible = not _build_mode and _selected_citizens.size() > 1
	_rts_count_badge.text = str(_selected_citizens.size())
	_update_rts_count_badge_geometry()
	_goods_count_badge.visible = _build_mode
	_goods_count_badge.text = str(_count_available_logs())
	if is_instance_valid(_population_count_label):
		_population_count_label.text = str(_population_count())
	_update_toolbar_mode_state()
	_day_label.text = UIText.text(
		UIText.DAY_COUNT_TEXT,
		[int(floor(_elapsed / DAY_LENGTH_SECONDS)) + 1]
	)
	var selected_text := UIText.text(UIText.NO_CITIZEN_SELECTED_TEXT)
	if _selected_citizens.size() > 1:
		selected_text = UIText.text(
			UIText.MULTIPLE_CITIZENS_SELECTED_TEXT,
			[_selected_citizens.size()]
		)
	elif is_instance_valid(_selected_citizen):
		selected_text = UIText.text(
			UIText.SINGLE_CITIZEN_SELECTED_TEXT,
			[_selected_citizen.get_status_text()]
		)
	_ui_status.text = selected_text
	_ui_resources.text = UIText.text(UIText.RESOURCES_SUMMARY_TEXT, [
		_calories,
		_water,
		_count_available_logs(),
		_construction_sites.size(),
	])


func _update_toolbar_mode_state() -> void:
	if not is_instance_valid(_building_button) or not is_instance_valid(_deconstruct_button):
		return
	_building_button.set_pressed_no_signal(_build_mode)
	_set_toolbar_button_icon(
		_building_button,
		_building_button.get_meta("normal_icon") as ImageTexture
	)
	_deconstruct_button.modulate.a = 1.0 if _build_mode else 0.0
	_deconstruct_button.visible = _build_mode
	_deconstruct_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP if _build_mode else Control.MOUSE_FILTER_IGNORE
	)
	var has_deconstruct_target := is_instance_valid(_selected_world_object) and (
		_selected_world_object is SupportConstructionSite
		or _selected_world_object is ExcavationSite
	)
	_deconstruct_button.disabled = not has_deconstruct_target


func _population_count() -> int:
	var count := 0
	for citizen in _citizens:
		if is_instance_valid(citizen):
			count += 1
	return count


func _update_rts_count_badge_geometry() -> void:
	const BADGE_DIAMETER := 18.0
	var badge_font := _rts_count_badge.get_theme_font("font")
	var badge_font_size := _rts_count_badge.get_theme_font_size("font_size")
	var text_width := badge_font.get_string_size(
		_rts_count_badge.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		badge_font_size
	).x
	# One digit remains a true circle. Larger counts may extend only sideways,
	# retaining circular end caps and the same 18-pixel vertical diameter.
	var badge_width := maxf(BADGE_DIAMETER, ceilf(text_width + 6.0))
	_rts_count_badge.custom_minimum_size = Vector2(BADGE_DIAMETER, BADGE_DIAMETER)
	_rts_count_badge.size = Vector2(badge_width, BADGE_DIAMETER)
	_rts_count_badge.position = get_viewport().get_mouse_position() + Vector2(19.0, 18.0)


func _count_available_logs() -> int:
	var count := 0
	for item in _items:
		if is_instance_valid(item) and item.is_available_log():
			count += 1
	return count


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _terrain_material(surface_colour: Color) -> ShaderMaterial:
	var terrain_shader := Shader.new()
	terrain_shader.code = """
shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 surface_color : source_color;
uniform vec4 shadow_color : source_color;
uniform float daylight = 1.0;
uniform vec2 cloud_shadow_offset;
uniform int citizen_count = 0;
uniform vec2 citizen_positions[32];
uniform float citizen_clear_radius = 4.4;
uniform float cloud_shadow_cell_size = 0.5;
uniform float cloud_cell_coverage_threshold = 0.5;
uniform int excavated_cell_count = 0;
uniform vec2 excavated_cells[64];
varying vec2 world_xz;

float hash_cell(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float inside_ellipse(vec2 point, vec2 radius) {
	return 1.0 - step(1.0, length(point / radius));
}

float raw_cloud_coverage(vec2 moving_position) {
	const float CELL_SIZE = 34.0;
	vec2 base_cell = floor(moving_position / CELL_SIZE);
	float covered = 0.0;
	for (int x_offset = -1; x_offset <= 1; x_offset++) {
		for (int y_offset = -1; y_offset <= 1; y_offset++) {
			vec2 cell = base_cell + vec2(float(x_offset), float(y_offset));
			float first_seed = hash_cell(cell);
			float second_seed = hash_cell(cell + vec2(19.0, 7.0));
			vec2 centre = (cell + vec2(0.2 + first_seed * 0.6, 0.2 + second_seed * 0.6)) * CELL_SIZE;
			vec2 blob_position = moving_position - centre;
			vec2 radius = vec2(5.5 + first_seed * 5.0, 4.0 + second_seed * 3.5);
			float main_blob = inside_ellipse(blob_position, radius);
			float left_blob = inside_ellipse(blob_position + vec2(radius.x * 0.65, -1.0), radius * vec2(0.62, 0.72));
			float right_blob = inside_ellipse(blob_position - vec2(radius.x * 0.65, 1.0), radius * vec2(0.68, 0.78));
			covered = max(covered, max(main_blob, max(left_blob, right_blob)));
		}
	}
	return covered;
}

float cloud_cell_shadow(vec2 shadow_cell) {
	vec2 cell_origin = shadow_cell * cloud_shadow_cell_size;
	vec2 cell_centre = cell_origin + vec2(cloud_shadow_cell_size * 0.5);
	for (int citizen_index = 0; citizen_index < 32; citizen_index++) {
		if (citizen_index >= citizen_count) {
			break;
		}
		if (distance(cell_centre, citizen_positions[citizen_index]) <= citizen_clear_radius) {
			return 0.0;
		}
	}

	vec2 sample_offset = vec2(cloud_shadow_cell_size * 0.42);
	float covered_weight = raw_cloud_coverage(cell_centre - cloud_shadow_offset) * 4.0;
	covered_weight += raw_cloud_coverage(cell_centre + vec2(-sample_offset.x, -sample_offset.y) - cloud_shadow_offset);
	covered_weight += raw_cloud_coverage(cell_centre + vec2(sample_offset.x, -sample_offset.y) - cloud_shadow_offset);
	covered_weight += raw_cloud_coverage(cell_centre + vec2(-sample_offset.x, sample_offset.y) - cloud_shadow_offset);
	covered_weight += raw_cloud_coverage(cell_centre + sample_offset - cloud_shadow_offset);
	float estimated_coverage = covered_weight / 8.0;
	return step(cloud_cell_coverage_threshold + 0.0001, estimated_coverage);
}

float cloud_coverage(vec2 ground_position) {
	// Coverage remains binary, but exposed 90-degree cell corners are clipped
	// to quarter circles like the interpolated fog contour instead of leaving
	// a staircase made exclusively from sharp rectangles.
	vec2 scaled_position = ground_position / cloud_shadow_cell_size;
	vec2 shadow_cell = floor(scaled_position);
	if (cloud_cell_shadow(shadow_cell) < 0.5) {
		return 0.0;
	}
	vec2 local_position = fract(scaled_position);
	const float CORNER_RADIUS = 0.38;
	float west = cloud_cell_shadow(shadow_cell + vec2(-1.0, 0.0));
	float east = cloud_cell_shadow(shadow_cell + vec2(1.0, 0.0));
	float north = cloud_cell_shadow(shadow_cell + vec2(0.0, -1.0));
	float south = cloud_cell_shadow(shadow_cell + vec2(0.0, 1.0));
	if (west < 0.5 && north < 0.5 && local_position.x < CORNER_RADIUS && local_position.y < CORNER_RADIUS && distance(local_position, vec2(CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	if (east < 0.5 && north < 0.5 && local_position.x > 1.0 - CORNER_RADIUS && local_position.y < CORNER_RADIUS && distance(local_position, vec2(1.0 - CORNER_RADIUS, CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	if (west < 0.5 && south < 0.5 && local_position.x < CORNER_RADIUS && local_position.y > 1.0 - CORNER_RADIUS && distance(local_position, vec2(CORNER_RADIUS, 1.0 - CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	if (east < 0.5 && south < 0.5 && local_position.x > 1.0 - CORNER_RADIUS && local_position.y > 1.0 - CORNER_RADIUS && distance(local_position, vec2(1.0 - CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	return 1.0;
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 terrain_cell = floor(world_xz);
	for (int excavation_index = 0; excavation_index < 64; excavation_index++) {
		if (excavation_index >= excavated_cell_count) {
			break;
		}
		if (distance(terrain_cell, excavated_cells[excavation_index]) < 0.1) {
			discard;
		}
	}
	ALBEDO = mix(surface_color.rgb, shadow_color.rgb, cloud_coverage(world_xz));
	ROUGHNESS = 1.0;
	EMISSION = ALBEDO * (1.0 - daylight);
}

void light() {
	float binary_light = step(0.5, ATTENUATION);
	// Godot multiplies DIFFUSE_LIGHT by ALBEDO after this function. Supplying
	// the colour ratio makes the final shadow pixel equal shadow_color rather
	// than tinting it with the surface (for example gray becoming brown on sand).
	vec3 shadow_ratio = shadow_color.rgb / max(ALBEDO, vec3(0.001));
	DIFFUSE_LIGHT += mix(shadow_ratio, vec3(1.0), binary_light) * daylight;
}
"""
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	terrain_material.set_shader_parameter("surface_color", surface_colour)
	terrain_material.set_shader_parameter("shadow_color", Palette.FOG_AND_SHADOW)
	terrain_material.set_shader_parameter("daylight", 1.0)
	terrain_material.set_shader_parameter("cloud_shadow_offset", Vector2.ZERO)
	terrain_material.set_shader_parameter("citizen_clear_radius", REVEAL_RADIUS + 0.4)
	terrain_material.set_shader_parameter("cloud_shadow_cell_size", FOG_CELL_SIZE)
	terrain_material.set_shader_parameter("cloud_cell_coverage_threshold", 0.5)
	terrain_material.set_shader_parameter("excavated_cell_count", 0)
	return terrain_material
