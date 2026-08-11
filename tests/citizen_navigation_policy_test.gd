extends SceneTree

const GridNavigationScript = preload("res://scripts/grid_navigation.gd")
const Policy = preload("res://scripts/citizen_navigation_policy.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	for tree_kind in ["tree", "dead_tree", "palm_tree", "stump"]:
		_check(not Policy.world_item_blocks(tree_kind), "%s blocks Citizens" % tree_kind)
		_check(Policy.world_item_mode(tree_kind) == Policy.PASSABLE, "%s is not passable" % tree_kind)
	_check(not Policy.world_item_blocks("cactus"), "Cactus physically blocks Citizens")
	_check(Policy.world_item_mode("cactus") == Policy.SOFT_AVOID, "Cactus is not a soft obstacle")
	_check(
		Policy.world_item_travel_cost("cactus") > GridNavigationScript.GROUND_TRAVEL_COST,
		"Cactus does not discourage A*"
	)
	_check(Policy.world_item_blocks("stone"), "Limestone is not a hard blocker")
	_check(
		Policy.world_item_collision_layer("tree") == Policy.INTERACTION_COLLISION_LAYER,
		"Tree physics still includes the Citizen blocker layer"
	)
	_check(
		Policy.world_item_collision_layer("cactus") == Policy.INTERACTION_COLLISION_LAYER,
		"Cactus physics still includes the Citizen blocker layer"
	)
	_check(
		Policy.world_item_collision_layer("stone")
		== (Policy.INTERACTION_COLLISION_LAYER | Policy.CITIZEN_BLOCKER_COLLISION_LAYER),
		"Limestone physics lacks the Citizen blocker layer"
	)

	var region := Rect2i(Vector2i.ZERO, Vector2i(7, 3))
	var cactus_costs := {Vector2i(3, 1): Policy.CACTUS_TRAVEL_COST}
	var route := GridNavigationScript.build_route_in_region(
		GridNavigationScript.cell_centre(Vector2i(0, 1)),
		GridNavigationScript.cell_centre(Vector2i(6, 1)),
		{},
		region,
		false,
		cactus_costs
	)
	var crossed_cactus := false
	for route_point in route:
		crossed_cactus = crossed_cactus or GridNavigationScript.world_cell(route_point) == Vector2i(3, 1)
	_check(not crossed_cactus, "A* crossed a Cactus despite an open alternative")

	var enclosed_start := GridNavigationScript.cell_centre(Vector2i(2, 1))
	var blockers: Dictionary = {}
	for offset in GridNavigationScript.NEIGHBOUR_OFFSETS:
		blockers[Vector2i(2, 1) + offset] = true
	_check(
		GridNavigationScript.is_locally_enclosed(enclosed_start, blockers, region),
		"Enclosed Citizen was not detected"
	)
	var escape_route := GridNavigationScript.build_emergency_route_in_region(
		enclosed_start,
		GridNavigationScript.cell_centre(Vector2i(6, 1)),
		blockers,
		region,
		false
	)
	_check(not escape_route.is_empty(), "Enclosed Citizen received no emergency escape route")
	var citizen := Citizen.new()
	root.add_child(citizen)
	citizen.global_position = enclosed_start
	citizen.assign_route(escape_route, {"emergency_escape": true}, {}, 2.0)
	_check(citizen.has_active_route(), "Delayed Emergency Escape lost its route preview")
	citizen.call("_process", 1.0)
	_check(citizen.global_position == enclosed_start, "Emergency Escape ignored its recovery delay")
	citizen.call("_process", 1.1)
	citizen.call("_process", 0.1)
	_check(citizen.global_position != enclosed_start, "Emergency Escape did not begin after its delay")

	if _failures.is_empty():
		print("PASS: Citizen navigation collision policy")
		quit(0)
		return
	printerr("FAIL: Citizen navigation collision policy (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
