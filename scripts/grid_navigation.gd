class_name GridNavigation
extends RefCounted

const NEIGHBOUR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]
const GROUND_TRAVEL_COST := 1.35
const ROAD_TRAVEL_COST := 1.0


static func world_cell(world_position: Vector3) -> Vector2i:
	return Vector2i(floori(world_position.x), floori(world_position.z))


static func cell_centre(cell: Vector2i, height := 0.0) -> Vector3:
	return Vector3(float(cell.x) + 0.5, height, float(cell.y) + 0.5)


static func clamp_to_square(world_position: Vector3, half_extent: float) -> Vector3:
	return Vector3(
		clampf(world_position.x, -half_extent + 0.5, half_extent - 0.5),
		world_position.y,
		clampf(world_position.z, -half_extent + 0.5, half_extent - 0.5)
	)


static func is_inside_square(world_position: Vector3, half_extent: float) -> bool:
	return (
		world_position.x >= -half_extent
		and world_position.x <= half_extent
		and world_position.z >= -half_extent
		and world_position.z <= half_extent
	)


static func build_route(
	start_position: Vector3,
	target_position: Vector3,
	blocked_cells: Dictionary,
	half_extent: float,
	approach_solid_target: bool
) -> Array[Vector3]:
	var region := Rect2i(
		Vector2i(-int(half_extent), -int(half_extent)),
		Vector2i(int(half_extent * 2.0), int(half_extent * 2.0))
	)
	return build_route_in_region(
		start_position,
		target_position,
		blocked_cells,
		region,
		approach_solid_target
	)


static func build_route_in_region(
	start_position: Vector3,
	target_position: Vector3,
	blocked_cells: Dictionary,
	region: Rect2i,
	approach_solid_target: bool,
	travel_costs: Dictionary = {}
) -> Array[Vector3]:
	var start_cell := world_cell(start_position)
	var target_cell := world_cell(target_position)
	var route_blockers := blocked_cells.duplicate()
	route_blockers.erase(start_cell)
	if not region.has_point(start_cell) or not region.has_point(target_cell):
		return []
	var astar := _create_astar_for_region(region, route_blockers, travel_costs)
	var reachable_cells := _reachable_cells(start_cell, route_blockers, astar.region)
	var candidates := _target_candidates(
		target_cell,
		approach_solid_target,
		route_blockers,
		astar.region
	)
	var shortest_path := _shortest_path(
		astar,
		start_cell,
		candidates,
		reachable_cells,
		travel_costs
	)
	if shortest_path.is_empty() and not approach_solid_target:
		var fallback_cell := _closest_reachable_cell(target_cell, start_cell, reachable_cells)
		if reachable_cells.has(fallback_cell):
			shortest_path.assign(astar.get_id_path(start_cell, fallback_cell))
	return _world_route(
		shortest_path,
		start_position,
		target_position,
		target_cell,
		route_blockers,
		approach_solid_target
	)


static func build_direct_route(route_start: Vector3, route_end: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var current_cell := world_cell(route_start)
	var end_cell := world_cell(route_end)
	var first_centre := cell_centre(current_cell, route_start.y)
	if route_start.distance_squared_to(first_centre) > 0.0025:
		result.append(first_centre)
	while current_cell != end_cell:
		var x_remaining := end_cell.x - current_cell.x
		var z_remaining := end_cell.y - current_cell.y
		if x_remaining != 0:
			current_cell.x += signi(x_remaining)
		if z_remaining != 0:
			current_cell.y += signi(z_remaining)
		result.append(cell_centre(current_cell, route_start.y))
	if result.is_empty():
		result.append(cell_centre(end_cell, route_start.y))
	return result


static func _create_astar(half_extent: float, blocked_cells: Dictionary) -> AStarGrid2D:
	return _create_astar_for_region(
		Rect2i(
		Vector2i(-int(half_extent), -int(half_extent)),
		Vector2i(int(half_extent * 2.0), int(half_extent * 2.0))
		),
		blocked_cells
	)


static func _create_astar_for_region(
	region: Rect2i,
	blocked_cells: Dictionary,
	travel_costs: Dictionary = {}
) -> AStarGrid2D:
	var astar := AStarGrid2D.new()
	astar.region = region
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for world_x in range(region.position.x, region.end.x):
		for world_z in range(region.position.y, region.end.y):
			astar.set_point_weight_scale(
				Vector2i(world_x, world_z),
				GROUND_TRAVEL_COST
			)
	for blocked_cell_value in blocked_cells:
		var blocked_cell: Vector2i = blocked_cell_value
		if astar.region.has_point(blocked_cell):
			astar.set_point_solid(blocked_cell, true)
	for travel_cell_value in travel_costs:
		var travel_cell: Vector2i = travel_cell_value
		if astar.region.has_point(travel_cell) and not blocked_cells.has(travel_cell):
			astar.set_point_weight_scale(
				travel_cell,
				maxf(ROAD_TRAVEL_COST, float(travel_costs[travel_cell]))
			)
	return astar


static func _target_candidates(
	target_cell: Vector2i,
	approach_solid_target: bool,
	blocked_cells: Dictionary,
	region: Rect2i
) -> Array[Vector2i]:
	if not approach_solid_target and not blocked_cells.has(target_cell):
		return [target_cell]
	var candidates: Array[Vector2i] = []
	for offset in NEIGHBOUR_OFFSETS:
		var candidate := target_cell + offset
		if region.has_point(candidate) and not blocked_cells.has(candidate):
			candidates.append(candidate)
	return candidates


static func _shortest_path(
	astar: AStarGrid2D,
	start_cell: Vector2i,
	candidates: Array[Vector2i],
	reachable_cells: Dictionary,
	travel_costs: Dictionary = {}
) -> Array[Vector2i]:
	var shortest_path: Array[Vector2i] = []
	var shortest_cost := INF
	for candidate in candidates:
		if not reachable_cells.has(candidate):
			continue
		var id_path: Array[Vector2i] = astar.get_id_path(start_cell, candidate)
		var path_cost := _path_travel_cost(id_path, travel_costs)
		if not id_path.is_empty() and path_cost < shortest_cost:
			shortest_path.assign(id_path)
			shortest_cost = path_cost
	return shortest_path


static func _path_travel_cost(path: Array[Vector2i], travel_costs: Dictionary) -> float:
	var total := 0.0
	for path_index in range(1, path.size()):
		var previous := path[path_index - 1]
		var current := path[path_index]
		var diagonal_multiplier := sqrt(2.0) if previous.x != current.x and previous.y != current.y else 1.0
		total += diagonal_multiplier * float(travel_costs.get(current, GROUND_TRAVEL_COST))
	return total


static func _world_route(
	path: Array[Vector2i],
	start_position: Vector3,
	target_position: Vector3,
	target_cell: Vector2i,
	blocked_cells: Dictionary,
	approach_solid_target: bool
) -> Array[Vector3]:
	var route: Array[Vector3] = []
	if path.is_empty():
		return route
	for path_cell in path:
		var route_point := cell_centre(path_cell)
		if route.is_empty() and start_position.distance_squared_to(route_point) <= 0.0025:
			continue
		route.append(route_point)
	if route.is_empty():
		route.append(cell_centre(path[-1]))
	if not approach_solid_target and not blocked_cells.has(target_cell) and path[-1] == target_cell:
		var precise_target := Vector3(target_position.x, 0.0, target_position.z)
		if route[-1].distance_squared_to(precise_target) > 0.0025:
			route.append(precise_target)
		else:
			route[-1] = precise_target
	return route


static func _reachable_cells(
	start_cell: Vector2i,
	blocked_cells: Dictionary,
	region: Rect2i
) -> Dictionary:
	var reachable: Dictionary = {start_cell: true}
	var frontier: Array[Vector2i] = [start_cell]
	var frontier_index := 0
	while frontier_index < frontier.size():
		var current := frontier[frontier_index]
		frontier_index += 1
		for offset in NEIGHBOUR_OFFSETS:
			var neighbour := current + offset
			if not region.has_point(neighbour) or blocked_cells.has(neighbour) or reachable.has(neighbour):
				continue
			if offset.x != 0 and offset.y != 0:
				if (
					blocked_cells.has(current + Vector2i(offset.x, 0))
					or blocked_cells.has(current + Vector2i(0, offset.y))
				):
					continue
			reachable[neighbour] = true
			frontier.append(neighbour)
	return reachable


static func _closest_reachable_cell(
	target_cell: Vector2i,
	start_cell: Vector2i,
	reachable_cells: Dictionary
) -> Vector2i:
	var closest := start_cell
	var closest_target_distance := INF
	var closest_start_distance := INF
	for cell_value in reachable_cells:
		var cell: Vector2i = cell_value
		var target_distance := Vector2(cell - target_cell).length_squared()
		var start_distance := Vector2(cell - start_cell).length_squared()
		if (
			target_distance < closest_target_distance
			or (
				is_equal_approx(target_distance, closest_target_distance)
				and start_distance < closest_start_distance
			)
		):
			closest = cell
			closest_target_distance = target_distance
			closest_start_distance = start_distance
	return closest
