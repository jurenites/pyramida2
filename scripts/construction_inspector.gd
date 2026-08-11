class_name ConstructionInspector
extends VBoxContainer

const IconNumberScript = preload("res://scripts/icon_number.gd")
const LabourProgressBarScript = preload("res://scripts/labour_progress_bar.gd")
const PixelUITheme = preload("res://scripts/pixel_ui.gd")
const ToolbarIcons = preload("res://scripts/toolbar_icon_renderer.gd")
const VisualTokens = preload("res://scripts/ui_visual_tokens.gd")

var _name_label: Label
var _total_progress_holder: CenterContainer
var _total_progress_bar: LabourProgressBar
var _materials_holder: CenterContainer
var _materials_row: HBoxContainer
var _material_readouts: Dictionary = {}
var _recipe_signature := ""
var _total_labour_seconds := -1.0


func configure() -> void:
	name = "SelectedConstructionInspector"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)

	_name_label = Label.new()
	_name_label.name = "BuildingName"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.add_theme_font_size_override(
		"font_size",
		VisualTokens.CONSTRUCTION_NAME_FONT_SIZE
	)
	_name_label.add_theme_color_override("font_color", Color.BLACK)
	PixelUITheme.apply(_name_label)
	add_child(_name_label)

	_total_progress_holder = CenterContainer.new()
	_total_progress_holder.name = "TotalLabourLine"
	_total_progress_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_total_progress_holder)

	_materials_holder = CenterContainer.new()
	_materials_holder.name = "MaterialLine"
	_materials_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_materials_holder)
	_materials_row = HBoxContainer.new()
	_materials_row.name = "MaterialIconNumbers"
	_materials_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_materials_row.add_theme_constant_override("separation", 6)
	_materials_holder.add_child(_materials_row)


func present(
	building_name: String,
	total_labour_seconds: float,
	applied_labour_seconds: float,
	recipe: Dictionary,
	installed_materials: Dictionary,
	camera_size: float,
	minimum_camera_size: float,
	maximum_camera_size: float
) -> void:
	_name_label.text = building_name
	_ensure_total_progress_bar(total_labour_seconds)
	_total_progress_bar.set_progress_ratio(
		applied_labour_seconds / maxf(total_labour_seconds, 0.001)
	)
	_ensure_material_readouts(recipe)
	for resource_kind_value in recipe:
		var resource_kind := str(resource_kind_value)
		var readout := _material_readouts.get(resource_kind) as IconNumber
		if not is_instance_valid(readout):
			continue
		readout.set_fraction(
			int(installed_materials.get(resource_kind, 0)),
			int(recipe[resource_kind])
		)
		readout.apply_camera_zoom(
			camera_size,
			minimum_camera_size,
			maximum_camera_size
		)
	visible = true


func total_progress_bar() -> LabourProgressBar:
	return _total_progress_bar


func material_readout(resource_kind: String) -> IconNumber:
	return _material_readouts.get(resource_kind) as IconNumber


func _ensure_total_progress_bar(total_labour_seconds: float) -> void:
	if (
		is_instance_valid(_total_progress_bar)
		and is_equal_approx(_total_labour_seconds, total_labour_seconds)
	):
		return
	_total_labour_seconds = total_labour_seconds
	if is_instance_valid(_total_progress_bar):
		_total_progress_holder.remove_child(_total_progress_bar)
		_total_progress_bar.queue_free()
	_total_progress_bar = LabourProgressBarScript.new() as LabourProgressBar
	_total_progress_bar.name = "TotalConstructionLabourProgress"
	_total_progress_bar.configure(
		total_labour_seconds,
		VisualTokens.OUTLINE_PIXELS,
		Color.WHITE
	)
	_total_progress_holder.add_child(_total_progress_bar)


func _ensure_material_readouts(recipe: Dictionary) -> void:
	var resource_kinds: Array[String] = []
	for resource_kind_value in recipe:
		resource_kinds.append(str(resource_kind_value))
	resource_kinds.sort()
	var signature_parts: Array[String] = []
	for resource_kind in resource_kinds:
		signature_parts.append("%s:%d" % [resource_kind, int(recipe[resource_kind])])
	var next_signature := ",".join(signature_parts)
	if next_signature == _recipe_signature:
		return
	_recipe_signature = next_signature
	_material_readouts.clear()
	for child in _materials_row.get_children():
		_materials_row.remove_child(child)
		child.queue_free()
	for resource_kind in resource_kinds:
		var readout := IconNumberScript.new() as IconNumber
		readout.name = "%sMaterial" % resource_kind.capitalize().replace(" ", "")
		readout.configure(
			ToolbarIcons.create_resource_icon(
				resource_kind,
				int(VisualTokens.CONSTRUCTION_MATERIAL_ICON_BASE_PIXELS)
			),
			null,
			0,
			IconNumber.ScaleMode.FULL_SCALE,
			Vector2.ONE * VisualTokens.CONSTRUCTION_MATERIAL_ICON_BASE_PIXELS,
			VisualTokens.CONSTRUCTION_MATERIAL_FONT_SIZE
		)
		_materials_row.add_child(readout)
		_material_readouts[resource_kind] = readout
