extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var cloud_layer := game.find_child("CloudLayer", true, false) as Node3D
	_check(cloud_layer != null, "Cloud code was removed instead of retained")
	if cloud_layer != null:
		_check(not cloud_layer.visible, "Cloud layer is still visible at startup")
		_check(cloud_layer.get_child_count() == 8, "Hidden future weather clouds were not retained")
		for cloud_child in cloud_layer.get_children():
			_check(not cloud_child.is_visible_in_tree(), "A hidden cloud remains visible in the scene tree")

	var ground_material := game.get("_ground_material") as ShaderMaterial
	_check(
		not bool(ground_material.get_shader_parameter("cloud_shadows_enabled")),
		"Procedural cloud shadows remain enabled on revealed terrain"
	)
	var shadow_offset_before := game.get("_cloud_shadow_offset") as Vector2
	game.call("_update_clouds", 60.0)
	_check(
		(game.get("_cloud_shadow_offset") as Vector2).is_equal_approx(shadow_offset_before),
		"Disabled cloud shadows continue moving"
	)

	if _failures.is_empty():
		print("PASS: clouds and cloud shadows hidden")
		quit(0)
		return
	printerr("FAIL: cloud visibility (%d failures)" % _failures.size())
	for failure in _failures:
		printerr("- %s" % failure)
	quit(1)
