class_name PileStorage
extends Node3D

const Palette = preload("res://scripts/game_palette.gd")
const WoodVisual = preload("res://scripts/wood_visual.gd")
const DEFAULT_FOOTPRINT: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(0, 1), Vector2i(1, 1),
]
const CELL_CORNER_OFFSETS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(1, 1), Vector2i(0, 1),
]
const LOGS_PER_LAYER := 4
const LOG_LAYER_COUNT := 4
const LOG_CAPACITY := LOGS_PER_LAYER * LOG_LAYER_COUNT
const LOG_SLOT_SPACING := 0.38
const LOG_LAYER_BASE_Y := WoodVisual.LOG_START_RADIUS
const LOG_LAYER_RISE := 0.23

var stored_logs := 0
var stored_calories := 0
var stored_other_resources: Dictionary = {}
var storage_world_units := DEFAULT_FOOTPRINT.size()
var _footprint_cells: Array[Vector2i] = DEFAULT_FOOTPRINT.duplicate()
var _structure_root: Node3D
var _contents_root: Node3D


func configure_footprint(next_cells: Array[Vector2i]) -> void:
	var normalized: Array[Vector2i] = []
	for cell in next_cells:
		if not normalized.has(cell):
			normalized.append(cell)
	if normalized.is_empty():
		normalized.append(Vector2i.ZERO)
	_footprint_cells = normalized
	storage_world_units = _footprint_cells.size()
	if is_inside_tree():
		_build_structure()
		_rebuild_contents()


func expand_with_cell(local_cell: Vector2i) -> bool:
	if _footprint_cells.has(local_cell):
		return false
	var touches_existing_cell := false
	for neighbour_offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _footprint_cells.has(local_cell + neighbour_offset):
			touches_existing_cell = true
			break
	if not touches_existing_cell:
		return false
	var expanded := _footprint_cells.duplicate()
	expanded.append(local_cell)
	configure_footprint(expanded)
	return true


func local_footprint_cells() -> Array[Vector2i]:
	return _footprint_cells.duplicate()


func world_footprint_cells() -> Array[Vector2i]:
	var origin := Vector2i(floori(global_position.x), floori(global_position.z))
	var result: Array[Vector2i] = []
	for local_cell in _footprint_cells:
		result.append(origin + local_cell)
	return result


func nearest_delivery_world_position(from_position: Vector3) -> Vector3:
	var nearest_position := global_position
	var nearest_distance := INF
	for world_cell in world_footprint_cells():
		var cell_centre := Vector3(float(world_cell.x) + 0.5, global_position.y, float(world_cell.y) + 0.5)
		var distance := from_position.distance_squared_to(cell_centre)
		if distance < nearest_distance:
			nearest_position = cell_centre
			nearest_distance = distance
	return nearest_position


static func convex_boundary_vertices(cells: Array[Vector2i]) -> Array[Vector2i]:
	var vertex_touch_counts: Dictionary = {}
	for cell in cells:
		for corner_offset in CELL_CORNER_OFFSETS:
			var vertex := cell + corner_offset
			vertex_touch_counts[vertex] = int(vertex_touch_counts.get(vertex, 0)) + 1
	var result: Array[Vector2i] = []
	for vertex_value in vertex_touch_counts:
		var vertex: Vector2i = vertex_value
		# One touching cell is a convex outer corner. Two is a straight edge or
		# an internal join; three is the concave notch of an L-shaped Pile.
		if int(vertex_touch_counts[vertex]) == 1:
			result.append(vertex)
	return result


func configure_starting_inventory(log_count: int) -> void:
	stored_logs = clampi(log_count, 0, LOG_CAPACITY)
	if is_inside_tree():
		_rebuild_contents()


func _ready() -> void:
	_build_structure()
	_rebuild_contents()


func has_log() -> bool:
	return stored_logs > 0


func take_log() -> bool:
	return take_resource("log", 1)


func store_log() -> bool:
	return store_resource("log", 1)


func store_calories(amount: int) -> void:
	store_resource("calories", amount)


func store_resource(resource_kind: String, amount: int) -> bool:
	if amount <= 0 or not can_store_resource(resource_kind):
		return false
	if resource_kind == "log" and stored_logs + amount > LOG_CAPACITY:
		return false
	match resource_kind:
		"log":
			stored_logs += amount
		"calories":
			stored_calories += amount
		_:
			stored_other_resources[resource_kind] = resource_count(resource_kind) + amount
	_rebuild_contents()
	return true


func take_resource(resource_kind: String, amount: int) -> bool:
	if amount <= 0 or resource_count(resource_kind) < amount:
		return false
	match resource_kind:
		"log":
			stored_logs -= amount
		"calories":
			stored_calories -= amount
		_:
			stored_other_resources[resource_kind] = resource_count(resource_kind) - amount
	_rebuild_contents()
	return true


func resource_count(resource_kind: String) -> int:
	match resource_kind:
		"log":
			return stored_logs
		"calories":
			return stored_calories
		_:
			return int(stored_other_resources.get(resource_kind, 0))


func inventory_snapshot() -> Dictionary:
	var inventory := {}
	if stored_logs > 0:
		inventory["log"] = stored_logs
	if stored_calories > 0:
		inventory["calories"] = stored_calories
	var other_resource_kinds := stored_other_resources.keys()
	other_resource_kinds.sort()
	for resource_kind_value in other_resource_kinds:
		var resource_kind := str(resource_kind_value)
		var amount := resource_count(resource_kind)
		if amount > 0:
			inventory[resource_kind] = amount
	return inventory


func can_store_resource(resource_kind: String) -> bool:
	# Water requires a future pottery or bottle vessel and cannot be poured into
	# an open Pile. Other physical resource families can be added later.
	if resource_kind == "water":
		return false
	if resource_kind == "log":
		return stored_logs < LOG_CAPACITY
	return true


func speech_anchor_world_position() -> Vector3:
	return global_position + _footprint_local_centre() + Vector3.UP * 1.0


func speech_actor_kind() -> String:
	return "building"


func _build_structure() -> void:
	if is_instance_valid(_structure_root):
		_structure_root.queue_free()
	_structure_root = Node3D.new()
	_structure_root.name = "PileStructure"
	add_child(_structure_root)

	var boundary_vertices := convex_boundary_vertices(_footprint_cells)
	for corner_index in boundary_vertices.size():
		var vertex := boundary_vertices[corner_index]
		var marker_mesh := SphereMesh.new()
		marker_mesh.radius = 0.11
		marker_mesh.height = 0.16
		marker_mesh.radial_segments = 7
		marker_mesh.rings = 3
		var marker := MeshInstance3D.new()
		marker.name = "PileBoundaryStone_%d" % corner_index
		marker.mesh = marker_mesh
		marker.position = Vector3(float(vertex.x) - 0.5, 0.08, float(vertex.y) - 0.5)
		marker.rotation.y = float(corner_index) * 0.71
		marker.scale = Vector3(1.0, 0.9, 0.82) if corner_index % 2 == 0 else Vector3(0.84, 0.95, 1.0)
		marker.material_override = _flat_material(Palette.LIMESTONE_SIDE)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_structure_root.add_child(marker)

	var body := StaticBody3D.new()
	body.name = "PileCollision"
	body.set_meta("world_object", self)
	for local_cell in _footprint_cells:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 0.55, 1.0)
		shape.shape = box
		shape.position = Vector3(float(local_cell.x), 0.275, float(local_cell.y))
		body.add_child(shape)
	_structure_root.add_child(body)

	if is_instance_valid(_contents_root):
		_contents_root.queue_free()
	_contents_root = Node3D.new()
	_contents_root.name = "StoredContents"
	add_child(_contents_root)


func _rebuild_contents() -> void:
	if not is_instance_valid(_contents_root):
		return
	for child in _contents_root.get_children():
		_contents_root.remove_child(child)
		child.queue_free()
	var stack_centre := _footprint_local_centre()
	for log_index in mini(stored_logs, LOG_CAPACITY):
		var layer := floori(float(log_index) / float(LOGS_PER_LAYER))
		var slot := log_index % LOGS_PER_LAYER
		var log_tool := SurfaceTool.new()
		log_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var along_z := layer % 2 == 1
		var lateral := (float(slot) - float(LOGS_PER_LAYER - 1) * 0.5) * LOG_SLOT_SPACING
		var centre := stack_centre + Vector3(
			lateral if along_z else 0.0,
			LOG_LAYER_BASE_Y + float(layer) * LOG_LAYER_RISE,
			0.0 if along_z else lateral
		)
		var axis := Vector3(0.0, 0.0, WoodVisual.LOG_LENGTH) if along_z else Vector3(WoodVisual.LOG_LENGTH, 0.0, 0.0)
		WoodVisual.append_tapered_segment(
			log_tool, centre - axis * 0.5, centre + axis * 0.5,
			WoodVisual.LOG_START_RADIUS, WoodVisual.LOG_END_RADIUS, true, true, 6
		)
		log_tool.generate_normals()
		var stored_log := MeshInstance3D.new()
		stored_log.name = "StoredLog_%02d" % (log_index + 1)
		stored_log.set_meta("stack_layer", layer)
		stored_log.set_meta("stack_slot", slot)
		stored_log.set_meta("along_z", along_z)
		stored_log.mesh = log_tool.commit()
		stored_log.material_override = WoodVisual.binary_material(Palette.ROOF_LOG)
		_contents_root.add_child(stored_log)

	var visible_food_capacity := _footprint_cells.size() * 6
	for food_index in mini(stored_calories, visible_food_capacity):
		var footprint_index := food_index % _footprint_cells.size()
		var local_food_index := floori(float(food_index) / float(_footprint_cells.size()))
		var local_cell := _footprint_cells[footprint_index]
		var berry_mesh := SphereMesh.new()
		berry_mesh.radius = 0.055
		berry_mesh.height = 0.1
		berry_mesh.radial_segments = 6
		berry_mesh.rings = 3
		var berry := MeshInstance3D.new()
		berry.mesh = berry_mesh
		berry.position = Vector3(
			float(local_cell.x) - 0.25 + float(local_food_index % 3) * 0.12,
			0.1 + float(floori(float(local_food_index) / 3.0)) * 0.1,
			float(local_cell.y) + 0.28
		)
		berry.material_override = _flat_material(Palette.WOODEN_ROOF)
		_contents_root.add_child(berry)


func _footprint_local_centre() -> Vector3:
	var minimum := _footprint_cells[0]
	var maximum := _footprint_cells[0]
	for cell in _footprint_cells:
		minimum.x = mini(minimum.x, cell.x)
		minimum.y = mini(minimum.y, cell.y)
		maximum.x = maxi(maximum.x, cell.x)
		maximum.y = maxi(maximum.y, cell.y)
	return Vector3(
		(float(minimum.x) + float(maximum.x)) * 0.5,
		0.0,
		(float(minimum.y) + float(maximum.y)) * 0.5
	)


func _flat_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.92
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
