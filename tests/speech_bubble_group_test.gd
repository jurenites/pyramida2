extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var overlay := SpeechBubbleOverlay.new()
	root.add_child(overlay)
	var single_bubble := overlay.call("_create_bubble", {
		"icon": "construction",
		"short_text": "",
		"speaker_kind": "citizen",
		"actor_count": 1,
	}) as Control
	var group_bubble := overlay.call("_create_bubble", {
		"icon": "construction",
		"short_text": "",
		"speaker_kind": "citizen",
		"actor_count": 2,
	}) as Control

	_check(single_bubble.has_node("MessageIcon"), "Single-Citizen bubble lost its work icon")
	_check(group_bubble.has_node("MessageIcon"), "Grouped bubble lost its work icon")
	_check(not group_bubble.has_node("ActorCount"), "Grouped bubble still contains the workforce counter")
	_check(
		is_equal_approx(group_bubble.size.x, single_bubble.size.x),
		"Grouped bubble still reserves width for the removed counter"
	)
	single_bubble.free()
	group_bubble.free()
	overlay.free()

	if _failures.is_empty():
		print("PASS: grouped speech bubble without counter")
		quit(0)
		return
	printerr("FAIL: grouped speech bubble without counter (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
