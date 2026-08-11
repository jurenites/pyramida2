extends SceneTree

const GridNavigationScript = preload("res://scripts/grid_navigation.gd")
const BuildingCatalogScript = preload("res://scripts/building_catalog.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var road_definition := BuildingCatalogScript.entry("road")
	_check(road_definition.get("recipe", {}) == {"plank": 4}, "Wooden Road recipe is not four Planks")
	_check(
		is_equal_approx(float(road_definition.get("travel_cost", 0.0)), GridNavigationScript.ROAD_TRAVEL_COST),
		"Road catalog cost does not match navigation"
	)

	var region := Rect2i(Vector2i.ZERO, Vector2i(9, 5))
	var start := GridNavigationScript.cell_centre(Vector2i(0, 2))
	var target := GridNavigationScript.cell_centre(Vector2i(8, 2))
	var road_costs: Dictionary = {}
	for road_x in range(1, 8):
		road_costs[Vector2i(road_x, 1)] = GridNavigationScript.ROAD_TRAVEL_COST
	var road_route := GridNavigationScript.build_route_in_region(
		start,
		target,
		{},
		region,
		false,
		road_costs
	)
	var road_steps := 0
	for route_point in road_route:
		if GridNavigationScript.world_cell(route_point).y == 1:
			road_steps += 1
	_check(road_steps >= 5, "A* did not prefer the nearby lower-cost Road")

	var citizen := Citizen.new()
	root.add_child(citizen)
	citizen.global_position = start
	citizen.assign_route([GridNavigationScript.cell_centre(Vector2i(1, 1))], {}, road_costs)
	citizen.call("_walk", 0.1)
	var road_distance := citizen.global_position.distance_to(start)
	citizen.global_position = start
	citizen.assign_route([GridNavigationScript.cell_centre(Vector2i(1, 2))], {}, {})
	citizen.call("_walk", 0.1)
	var ground_distance := citizen.global_position.distance_to(start)
	_check(road_distance > ground_distance, "Road did not increase Citizen walking speed")

	if _failures.is_empty():
		print("PASS: weighted Road navigation")
		quit(0)
		return
	printerr("FAIL: weighted Road navigation (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
