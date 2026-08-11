extends SceneTree

const Catalog = preload("res://scripts/building_catalog.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	_check(
		Catalog.CATEGORY_ORDER == ["path", "storage", "livable", "structure"],
		"Building family order changed"
	)
	var road := Catalog.entry("road")
	_check(road.get("footprint") == Vector3i(1, 1, 1), "Road is not one World Unit")
	_check(road.get("recipe") == {"plank": 4}, "Wooden Road is not four Planks")
	_check(road.get("upgrade_when_above") == "support", "Road cannot recognize a Support below")
	_check(road.get("upgrade_result") == "support_platform", "Road plus Support does not become Platform")

	for bridge_id in ["rope_bridge", "suspension_bridge"]:
		var bridge := Catalog.entry(bridge_id)
		_check(bridge.get("minimum_footprint") == Vector3i(2, 1, 1), "%s minimum is not 2x1x1" % bridge_id)
		_check(bridge.get("drag_axis") == "cardinal", "%s accepts non-cardinal dragging" % bridge_id)
	_check(
		float(Catalog.entry("rope_bridge").get("maximum_center_height_offset", 0.0)) == -0.5,
		"Rope Bridge does not preserve its half-World-Unit sag"
	)
	_check(
		float(Catalog.entry("suspension_bridge").get("maximum_center_height_offset", 0.0)) > 0.0,
		"Suspension Bridge does not preserve its raised centre"
	)

	var tunnel := Catalog.entry("tunnel")
	_check(tunnel.get("minimum_footprint") == Vector3i(2, 1, 1), "Tunnel minimum is not 2x1x1")
	_check((tunnel.get("sequence", []) as Array).size() == 4, "Tunnel has no composite construction sequence")

	var pile := Catalog.entry("pile")
	_check(pile.get("footprint") == Vector3i(2, 1, 2), "Pile surface footprint is not 2x2")
	_check((pile.get("recipe", {}) as Dictionary).is_empty(), "Pile is not free")
	_check(bool(pile.get("implemented", false)), "Free Pile is not buildable")
	var platform := Catalog.entry("platform")
	_check(platform.get("recipe") == {"log": 4, "plank": 4}, "Platform recipe changed")
	var sawmill := Catalog.entry("sawmill")
	_check(sawmill.get("recipe") == {"log": 10}, "Sawmill is not ten Logs")
	_check(int(sawmill.get("entry_points", 0)) == 4, "Sawmill does not expose four entry points")
	var sawmill_recipes := sawmill.get("workshop_recipes", []) as Array
	_check(
		not sawmill_recipes.is_empty()
		and sawmill_recipes[0].get("input") == {"log": 1}
		and sawmill_recipes[0].get("output") == {"plank": 1}
		and is_equal_approx(float(sawmill_recipes[0].get("work_seconds", 0.0)), 3.0),
		"Sawmill does not convert one Log to one Plank in three seconds"
	)
	var warehouse := Catalog.entry("warehouse")
	_check(warehouse.get("footprint") == Vector3i.ONE, "Warehouse is not 1x1x1")
	_check(warehouse.get("recipe") == {"log": 4, "plank": 4}, "Warehouse recipe changed")
	_check(bool(warehouse.get("merge_on_facing_door", false)), "Warehouse units cannot merge through facing Doors")
	var warehouse_navigation := warehouse.get("citizen_navigation", {}) as Dictionary
	_check(warehouse_navigation.get("door") == "passable", "Warehouse Door is not passable")
	_check(warehouse_navigation.get("walls") == "hard_block", "Warehouse walls are not hard blockers")
	_check(not Catalog.citizen_face_blocks("warehouse", "door"), "Warehouse Door blocks a Citizen")
	_check(Catalog.citizen_face_blocks("warehouse", "walls"), "Warehouse wall lets a Citizen through")

	var small_home := Catalog.entry("small_livable")
	_check(small_home.get("footprint") == Vector3i.ONE, "Small home is not 1x1x1")
	_check(small_home.get("recipe") == {"log": 4, "plank": 8}, "Small home base recipe changed")
	_check(
		small_home.get("standalone_roof_recipe") == {"log": 4, "hay": 4},
		"Small home standalone roof recipe changed"
	)

	if _failures.is_empty():
		print("PASS: Building catalog contracts")
		quit(0)
		return
	printerr("FAIL: Building catalog contracts (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
