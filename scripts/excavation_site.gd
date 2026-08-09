class_name ExcavationSite
extends Node3D

const Palette = preload("res://scripts/game_palette.gd")


func _ready() -> void:
	for diagonal_index in 2:
		var marker := MeshInstance3D.new()
		marker.name = "ExcavationMarker%d" % (diagonal_index + 1)
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.08, 0.055, 0.82)
		marker.mesh = marker_mesh
		marker.position = Vector3(0.0, 0.04, 0.0)
		marker.rotation.y = PI * (0.25 if diagonal_index == 0 else -0.25)
		var marker_material := StandardMaterial3D.new()
		marker_material.albedo_color = Palette.WOMAN_CLOTHING
		marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.material_override = marker_material
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)

	var body := StaticBody3D.new()
	body.set_meta("world_object", self)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.82, 0.1, 0.82)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func speech_anchor_world_position() -> Vector3:
	return global_position + Vector3.UP * 0.35


func speech_actor_kind() -> String:
	return "building"
