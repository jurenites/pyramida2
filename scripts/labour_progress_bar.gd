class_name LabourProgressBar
extends Control

const PIXELS_PER_SECOND := 8.0
const BAR_HEIGHT := 8.0
const CORNER_RADIUS := 3
const INNER_CORNER_RADIUS := 1
const MAXIMUM_SUN_TILT_DEGREES := 2.0

var _progress_ratio := 0.0
var _outline_pixels := 2.0
var _fill_colour := Color.WHITE
var _background_style: StyleBoxFlat
var _fill_style: StyleBoxFlat
var _outline_style: StyleBoxFlat


func configure(required_seconds: float, outline_pixels: float, fill_colour: Color) -> void:
	name = "AppliedLabourProgress"
	var bar_width := maxf(PIXELS_PER_SECOND, required_seconds * PIXELS_PER_SECOND)
	var bar_size := Vector2(bar_width, BAR_HEIGHT)
	_outline_pixels = clampf(outline_pixels, 1.0, BAR_HEIGHT * 0.5)
	_fill_colour = fill_colour
	_progress_ratio = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = bar_size
	size = bar_size
	pivot_offset = bar_size * 0.5
	_create_styles()
	queue_redraw()


func set_progress_ratio(progress: float) -> void:
	_progress_ratio = clampf(progress, 0.0, 1.0)
	queue_redraw()


func progress_ratio() -> float:
	return _progress_ratio


func outline_pixels() -> float:
	return _outline_pixels


func corner_radius_pixels() -> int:
	return CORNER_RADIUS


func set_sun_screen_side(screen_side: float) -> void:
	rotation_degrees = clampf(screen_side, -1.0, 1.0) * MAXIMUM_SUN_TILT_DEGREES


func inner_rect() -> Rect2:
	var inner_size := size - Vector2.ONE * _outline_pixels * 2.0
	return Rect2(Vector2.ONE * _outline_pixels, inner_size.max(Vector2.ZERO))


func filled_rect() -> Rect2:
	var interior := inner_rect()
	return Rect2(interior.position, Vector2(interior.size.x * _progress_ratio, interior.size.y))


func _draw() -> void:
	var outer_rectangle := Rect2(Vector2.ZERO, size)
	draw_style_box(_background_style, outer_rectangle)
	var fill_rectangle := filled_rect()
	if fill_rectangle.size.x > 0.0 and fill_rectangle.size.y > 0.0:
		draw_style_box(_fill_style, fill_rectangle)
	# Draw the rounded border last so labour can never cover the outline.
	draw_style_box(_outline_style, outer_rectangle)


func _create_styles() -> void:
	_background_style = StyleBoxFlat.new()
	_background_style.bg_color = Color.BLACK
	_background_style.set_corner_radius_all(CORNER_RADIUS)

	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = _fill_colour
	_fill_style.set_corner_radius_all(INNER_CORNER_RADIUS)

	_outline_style = StyleBoxFlat.new()
	_outline_style.bg_color = Color.TRANSPARENT
	_outline_style.border_color = Color.WHITE
	_outline_style.set_border_width_all(roundi(_outline_pixels))
	_outline_style.set_corner_radius_all(CORNER_RADIUS)
	_outline_style.draw_center = false
