class_name CitizenNavigationPolicy
extends RefCounted

## Citizen movement and pointer interaction are separate concerns. WorldItem
## hitboxes remain selectable even when their World Unit is passable to a Citizen.
const PASSABLE := "passable"
const SOFT_AVOID := "soft_avoid"
const HARD_BLOCK := "hard_block"

## Layer 1 remains the pointer/interaction layer. Layer 2 is reserved for
## physical shapes that a future CharacterBody Citizen must not cross.
const INTERACTION_COLLISION_LAYER := 1
const CITIZEN_BLOCKER_COLLISION_LAYER := 2

const CACTUS_TRAVEL_COST := 3.0
const EMERGENCY_ESCAPE_DELAY_SECONDS := 2.0


static func world_item_mode(item_kind: String) -> String:
	match item_kind:
		"tree", "dead_tree", "palm_tree", "stump", "cactus":
			return SOFT_AVOID if item_kind == "cactus" else PASSABLE
		"stone", "bush":
			return HARD_BLOCK
		_:
			return PASSABLE


static func world_item_blocks(item_kind: String) -> bool:
	return world_item_mode(item_kind) == HARD_BLOCK


static func world_item_travel_cost(item_kind: String) -> float:
	return CACTUS_TRAVEL_COST if item_kind == "cactus" else 0.0


static func world_item_collision_layer(item_kind: String) -> int:
	var layers := INTERACTION_COLLISION_LAYER
	if world_item_blocks(item_kind):
		layers |= CITIZEN_BLOCKER_COLLISION_LAYER
	return layers
