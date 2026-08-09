class_name WorldUnit
extends RefCounted

## Authoritative spatial data for one 1×1×1 World Unit.
## Presentation code may render it at any engine scale, but its logical shape
## always remains two by two by two Sub-Units.

const SUB_UNITS_PER_AXIS := 2
const SUB_UNIT_COUNT := 8
const SIDES := ["left", "right", "bottom", "top", "back", "front"]

var world_coordinate: Vector3i
var occupancy: Array[String] = ["", "", "", "", "", "", "", "",]


func _init(p_world_coordinate := Vector3i.ZERO) -> void:
	world_coordinate = p_world_coordinate


func index_for(sub_unit: Vector3i) -> int:
	assert(is_valid_sub_unit(sub_unit))
	return sub_unit.x + SUB_UNITS_PER_AXIS * (sub_unit.y + SUB_UNITS_PER_AXIS * sub_unit.z)


func is_valid_sub_unit(sub_unit: Vector3i) -> bool:
	return (
		sub_unit.x >= 0 and sub_unit.x < SUB_UNITS_PER_AXIS
		and sub_unit.y >= 0 and sub_unit.y < SUB_UNITS_PER_AXIS
		and sub_unit.z >= 0 and sub_unit.z < SUB_UNITS_PER_AXIS
	)


func is_empty(sub_unit: Vector3i) -> bool:
	return occupancy[index_for(sub_unit)].is_empty()


func set_occupant(sub_unit: Vector3i, entity_id: String) -> void:
	occupancy[index_for(sub_unit)] = entity_id


func anchor_id(sub_unit: Vector3i, side: String) -> String:
	assert(is_valid_sub_unit(sub_unit))
	assert(SIDES.has(side))
	# Anchor ownership belongs to the Sub-Unit and face direction. Two anchors
	# may occupy one shared face-centre position but remain separate identities.
	return "%s:%s:%s:%s:%s" % [
		world_coordinate.x,
		world_coordinate.y,
		world_coordinate.z,
		"%s,%s,%s" % [sub_unit.x, sub_unit.y, sub_unit.z],
		side,
	]
