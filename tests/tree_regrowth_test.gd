extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var stump := WorldItem.new()
	stump.set_process(false)
	stump.configure("stump", 71)
	root.add_child(stump)
	stump.restore_stream_state({
		"kind": "stump",
		"detail_seed": 71,
		"tree_log_count": 0,
		"tree_growth_height": 0.0,
		"tree_top_present": false,
		"tree_growth_remaining": WorldItem.TREE_GROWTH_INTERVAL,
	})

	stump.advance_stream_time(WorldItem.TREE_GROWTH_INTERVAL - 1.0)
	_check(stump.item_kind == "stump", "Stump regrew before three completed days")
	stump.advance_stream_time(1.0)
	_check(stump.item_kind == "tree", "Stump did not become a living Tree after three days")
	_check(stump.tree_log_count == 1, "First regrowth step did not create exactly one Log")
	_check(
		is_equal_approx(stump.tree_growth_height, 1.0),
		"First regrowth step was not one World Unit high"
	)

	stump.advance_stream_time(WorldItem.TREE_GROWTH_INTERVAL)
	_check(stump.tree_log_count == 2, "Second three-day step did not create the second Log")
	stump.advance_stream_time(WorldItem.TREE_GROWTH_INTERVAL)
	_check(stump.tree_log_count == WorldItem.TREE_MAX_LOG_COUNT, "Tree did not reach height three")
	stump.advance_stream_time(WorldItem.TREE_GROWTH_INTERVAL)
	_check(stump.tree_log_count == WorldItem.TREE_MAX_LOG_COUNT, "Tree grew beyond height three")

	if _failures.is_empty():
		print("PASS: Tree stump regrowth cadence")
		quit(0)
		return
	printerr("FAIL: Tree stump regrowth cadence (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
