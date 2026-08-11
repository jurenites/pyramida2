class_name ConstructionProgress
extends RefCounted

## Construction duration is derived from the recipe. Every material quantity is
## multiplied by that material's installation time, then all products are added.


static func total_required_seconds(
	recipe: Dictionary,
	labour_seconds_by_resource: Dictionary
) -> float:
	return installed_seconds(recipe, labour_seconds_by_resource)


static func installed_seconds(
	installed_materials: Dictionary,
	labour_seconds_by_resource: Dictionary
) -> float:
	var total := 0.0
	for resource_kind_value in installed_materials:
		var resource_kind := str(resource_kind_value)
		total += (
			float(installed_materials[resource_kind])
			* float(labour_seconds_by_resource.get(resource_kind, 0.0))
		)
	return total
