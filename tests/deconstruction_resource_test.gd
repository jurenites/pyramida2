extends SceneTree

const SupportConstructionSiteScript = preload("res://scripts/support_construction_site.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var support := SupportConstructionSiteScript.new() as SupportConstructionSite
	root.add_child(support)
	_expect(
		support.deconstruction_resource_snapshot().is_empty(),
		"An empty Construction Site must return no resources"
	)
	var contributor_id := 41
	_expect(support.reserve_log(contributor_id) >= 0, "Expected a Log reservation")
	_expect(
		support.deconstruction_resource_snapshot().is_empty(),
		"A reserved Log must not be duplicated as an installed resource"
	)
	support.release_log_reservation(contributor_id)
	support.deliver_log()
	support.deliver_log()
	_expect(
		int(support.deconstruction_resource_snapshot().get("log", 0)) == 2,
		"Two installed Support posts must return exactly two loose Logs"
	)
	support.queue_free()
	if _failures.is_empty():
		print("PASS: deconstruction resource contract")
		quit(0)
		return
	printerr("FAIL: deconstruction resource contract (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)


func _expect(condition: bool, failure_message: String) -> void:
	if not condition:
		_failures.append(failure_message)
