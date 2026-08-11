class_name CitizenCommandOverlay
extends CanvasLayer

const OVERLAY_LAYER := 90
const PATH_LINE_WIDTH_PIXELS := 2.0
const SELECTION_LINE_WIDTH_PIXELS := 2.0
const SELECTION_RADIUS_WORLD := 0.3168
const SELECTION_POINT_COUNT := 16
const TARGET_DOT_RADIUS_PIXELS := 5.0
const PATH_HEIGHT_WORLD := 0.09
const SELECTION_HEIGHT_WORLD := 0.045

var _camera: Camera3D
var _route_lines: Array[Line2D] = []
var _route_targets: Array[Polygon2D] = []
var _selection_lines: Array[Line2D] = []


func configure(camera: Camera3D) -> void:
	name = "CitizenCommandOverlay"
	layer = OVERLAY_LAYER
	_camera = camera


func update_citizens(selected_citizens: Array) -> void:
	# The overlay needs only Node3D positions plus route-query methods. Keeping
	# the collection untyped avoids coupling presentation to Citizen simulation.
	if not is_instance_valid(_camera):
		_hide_all()
		return
	_update_selection_lines(selected_citizens)
	_update_route_lines(selected_citizens)


func _update_route_lines(selected_citizens: Array) -> void:
	var visible_count := 0
	for citizen in selected_citizens:
		if not is_instance_valid(citizen) or not citizen.has_active_route():
			continue
		var route_points: Array[Vector3] = citizen.route_points()
		if route_points.size() < 2:
			continue
		var screen_points := _project_world_points(route_points, PATH_HEIGHT_WORLD)
		if screen_points.size() < 2:
			continue
		_ensure_route_item(visible_count)
		var route_line := _route_lines[visible_count]
		var target_dot := _route_targets[visible_count]
		route_line.points = screen_points
		route_line.visible = true
		target_dot.position = screen_points[-1]
		target_dot.visible = true
		visible_count += 1
	for hidden_index in range(visible_count, _route_lines.size()):
		_route_lines[hidden_index].visible = false
		_route_targets[hidden_index].visible = false


func _update_selection_lines(selected_citizens: Array) -> void:
	var visible_count := 0
	for citizen in selected_citizens:
		if not is_instance_valid(citizen):
			continue
		var world_points: Array[Vector3] = []
		for point_index in SELECTION_POINT_COUNT + 1:
			var angle := TAU * float(point_index) / float(SELECTION_POINT_COUNT)
			world_points.append(citizen.global_position + Vector3(
				cos(angle) * SELECTION_RADIUS_WORLD,
				0.0,
				sin(angle) * SELECTION_RADIUS_WORLD
			))
		var screen_points := _project_world_points(world_points, SELECTION_HEIGHT_WORLD)
		if screen_points.size() != SELECTION_POINT_COUNT + 1:
			continue
		_ensure_selection_item(visible_count)
		var selection_line := _selection_lines[visible_count]
		selection_line.points = screen_points
		selection_line.visible = true
		visible_count += 1
	for hidden_index in range(visible_count, _selection_lines.size()):
		_selection_lines[hidden_index].visible = false


func _project_world_points(world_points: Array[Vector3], height: float) -> PackedVector2Array:
	var screen_points := PackedVector2Array()
	for world_point in world_points:
		var raised_point := world_point + Vector3.UP * height
		if _camera.is_position_behind(raised_point):
			return PackedVector2Array()
		screen_points.append(_camera.unproject_position(raised_point).round())
	return screen_points


func _ensure_route_item(item_index: int) -> void:
	while _route_lines.size() <= item_index:
		var route_line := _create_line(
			"ContinuousRouteLine%d" % (_route_lines.size() + 1),
			PATH_LINE_WIDTH_PIXELS
		)
		add_child(route_line)
		_route_lines.append(route_line)

		var target_dot := Polygon2D.new()
		target_dot.name = "RouteTargetDot%d" % (_route_targets.size() + 1)
		target_dot.color = Color.WHITE
		var dot_points := PackedVector2Array()
		for point_index in 12:
			var angle := TAU * float(point_index) / 12.0
			dot_points.append(Vector2(cos(angle), sin(angle)) * TARGET_DOT_RADIUS_PIXELS)
		target_dot.polygon = dot_points
		add_child(target_dot)
		_route_targets.append(target_dot)


func _ensure_selection_item(item_index: int) -> void:
	while _selection_lines.size() <= item_index:
		var selection_line := _create_line(
			"CitizenSelectionCircle%d" % (_selection_lines.size() + 1),
			SELECTION_LINE_WIDTH_PIXELS
		)
		add_child(selection_line)
		_selection_lines.append(selection_line)


func _create_line(line_name: String, line_width: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.width = line_width
	line.default_color = Color.WHITE
	line.antialiased = false
	line.joint_mode = Line2D.LINE_JOINT_BEVEL
	line.begin_cap_mode = Line2D.LINE_CAP_NONE
	line.end_cap_mode = Line2D.LINE_CAP_NONE
	return line


func _hide_all() -> void:
	for route_line in _route_lines:
		route_line.visible = false
	for target_dot in _route_targets:
		target_dot.visible = false
	for selection_line in _selection_lines:
		selection_line.visible = false
