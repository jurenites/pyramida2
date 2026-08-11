class_name IconNumber
extends HBoxContainer

const PixelUITheme = preload("res://scripts/pixel_ui.gd")
const VisualTokens = preload("res://scripts/ui_visual_tokens.gd")

## Shared icon-and-number readout. Standard matches fixed toolbar geometry,
## Full Scale preserves the apparent size of a represented world object as the
## camera zooms, and Compact remains fixed for dense resource summaries.
## Typography never changes with camera zoom.

enum ScaleMode {
	COMPACT,
	STANDARD,
	FULL_SCALE,
}

var _icon_button: Button
var _number_label: Label
var _scale_mode := ScaleMode.COMPACT
var _base_icon_size := Vector2.ONE
var _normal_icon: Texture2D
var _hover_icon: Texture2D


func configure(
	normal_icon: Texture2D,
	hover_icon: Texture2D,
	number_value: int,
	scale_mode: int,
	base_icon_size: Vector2,
	font_size: int,
	interactive := false,
	icon_node_name := "Icon",
	number_node_name := "Number",
	number_minimum_size := Vector2.ZERO
) -> void:
	_scale_mode = scale_mode
	_base_icon_size = base_icon_size
	_normal_icon = normal_icon
	_hover_icon = hover_icon
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(
		"separation",
		VisualTokens.ICON_NUMBER_COMPACT_SEPARATION_PIXELS
		if _scale_mode == ScaleMode.COMPACT
		else VisualTokens.ICON_NUMBER_DEFAULT_SEPARATION_PIXELS
	)

	_icon_button = Button.new()
	_icon_button.name = icon_node_name
	_icon_button.custom_minimum_size = _base_icon_size
	_icon_button.size = _base_icon_size
	_icon_button.icon = _normal_icon
	_icon_button.expand_icon = true
	_icon_button.flat = true
	_icon_button.focus_mode = Control.FOCUS_NONE
	_icon_button.mouse_filter = (
		Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	)
	_icon_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon_button.tooltip_text = ""
	_icon_button.add_theme_color_override("icon_normal_color", Color.WHITE)
	_icon_button.add_theme_color_override("icon_hover_color", Color.WHITE)
	_icon_button.add_theme_color_override("icon_pressed_color", Color.WHITE)
	_icon_button.add_theme_color_override("icon_focus_color", Color.WHITE)
	var empty_style := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		_icon_button.add_theme_stylebox_override(style_name, empty_style)
	if _hover_icon != null:
		_icon_button.mouse_entered.connect(_set_hovered.bind(true))
		_icon_button.mouse_exited.connect(_set_hovered.bind(false))
		_icon_button.focus_entered.connect(_set_hovered.bind(true))
		_icon_button.focus_exited.connect(_set_hovered.bind(false))
	add_child(_icon_button)

	_number_label = Label.new()
	_number_label.name = number_node_name
	_number_label.text = str(number_value)
	_number_label.custom_minimum_size = number_minimum_size
	_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_number_label.add_theme_font_size_override("font_size", font_size)
	_number_label.add_theme_color_override("font_color", Color.BLACK)
	PixelUITheme.apply(_number_label)
	add_child(_number_label)


func set_number(number_value: int) -> void:
	if is_instance_valid(_number_label):
		_number_label.text = str(number_value)


func set_fraction(current_value: int, total_value: int) -> void:
	if is_instance_valid(_number_label):
		_number_label.text = "%d/%d" % [current_value, total_value]


func apply_camera_zoom(camera_size: float, minimum_camera_size: float, maximum_camera_size: float) -> void:
	if _scale_mode != ScaleMode.FULL_SCALE or not is_instance_valid(_icon_button):
		return
	var bounded_camera_size := clampf(camera_size, minimum_camera_size, maximum_camera_size)
	var icon_scale := maximum_camera_size / maxf(bounded_camera_size, 0.001)
	_set_icon_size(_base_icon_size * icon_scale)


func icon_button() -> Button:
	return _icon_button


func number_label() -> Label:
	return _number_label


func scale_mode() -> int:
	return _scale_mode


func current_icon_size() -> Vector2:
	if not is_instance_valid(_icon_button):
		return Vector2.ZERO
	return _icon_button.custom_minimum_size


func _set_icon_size(next_size: Vector2) -> void:
	_icon_button.custom_minimum_size = next_size
	_icon_button.size = next_size


func _set_hovered(is_hovered: bool) -> void:
	_icon_button.icon = _hover_icon if is_hovered else _normal_icon
