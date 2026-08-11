extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var five_cell_shape: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	]
	var rectangle: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	]
	_check(
		PileStorage.convex_boundary_vertices(five_cell_shape).size() == 5,
		"Five-cell non-rectangular Pile does not produce five convex boundary stones"
	)
	_check(
		PileStorage.convex_boundary_vertices(rectangle).size() == 4,
		"Three-by-two rectangular Pile does not collapse to four boundary stones"
	)

	var pile := PileStorage.new()
	pile.configure_footprint(PileStorage.DEFAULT_FOOTPRINT)
	root.add_child(pile)
	pile.global_position = Vector3(10.5, 0.0, 20.5)
	await process_frame
	_check(pile.storage_world_units == 4, "Starting Pile capacity does not report four World Units")
	_check(
		pile.world_footprint_cells() == [
			Vector2i(10, 20), Vector2i(11, 20),
			Vector2i(10, 21), Vector2i(11, 21),
		],
		"Pile local footprint does not translate into the expected world cells"
	)
	var nearest := pile.nearest_delivery_world_position(Vector3(12.5, 0.0, 21.5))
	_check(nearest == Vector3(11.5, 0.0, 21.5), "Delivery does not target the nearest Pile World Unit")
	_check(pile.expand_with_cell(Vector2i(2, 1)), "Adjacent World Unit did not expand the Pile")
	_check(pile.storage_world_units == 5, "Expanded Pile does not report five World Units")
	_check(
		PileStorage.convex_boundary_vertices(pile.local_footprint_cells()).size() == 5,
		"Expanded five-cell Pile does not recalculate five boundary stones"
	)
	_check(
		not pile.expand_with_cell(Vector2i(8, 8)),
		"Disconnected World Unit was incorrectly accepted as part of one Pile"
	)

	if _failures.is_empty():
		print("PASS: expandable Pile footprint")
		quit(0)
		return
	printerr("FAIL: expandable Pile footprint (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
