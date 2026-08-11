class_name ToolbarIconRenderer
extends RefCounted

const Palette = preload("res://scripts/game_palette.gd")
const UIVisualTokens = preload("res://scripts/ui_visual_tokens.gd")

const ICON_SIZE_PIXELS := 40


static func create_icon(icon_kind: String) -> ImageTexture:
	var icon_image := Image.create(ICON_SIZE_PIXELS, ICON_SIZE_PIXELS, false, Image.FORMAT_RGBA8)
	icon_image.fill(Color.TRANSPARENT)
	if icon_kind in ["population", "population_hover"]:
		if icon_kind == "population_hover":
			_draw_circle(icon_image, Vector2(20, 11), 5.0 + UIVisualTokens.OUTLINE_PIXELS, Color.WHITE)
			_draw_line(icon_image, Vector2(14, 22), Vector2(26, 22), 3.0 + UIVisualTokens.OUTLINE_PIXELS, Color.WHITE)
			_draw_line(icon_image, Vector2(20, 21), Vector2(20, 33), 5.0 + UIVisualTokens.OUTLINE_PIXELS, Color.WHITE)
		_draw_circle(icon_image, Vector2(20, 11), 5.0, Color.BLACK)
		_draw_line(icon_image, Vector2(14, 22), Vector2(26, 22), 3.0, Color.BLACK)
		_draw_line(icon_image, Vector2(20, 21), Vector2(20, 33), 5.0, Color.BLACK)
	elif icon_kind in ["building", "building_hover", "building_active"]:
		var building_polygon := PackedVector2Array([
			Vector2(12, 18), Vector2(20, 10), Vector2(28, 18), Vector2(28, 31), Vector2(12, 31),
		])
		if icon_kind == "building_active":
			_fill_polygon(icon_image, building_polygon, Color.BLACK)
			_draw_building_outline(icon_image, UIVisualTokens.BUILDING_ICON_STROKE_PIXELS, Color.BLACK)
		else:
			if icon_kind == "building_hover":
				_draw_building_outline(
					icon_image,
					UIVisualTokens.BUILDING_ICON_STROKE_PIXELS + UIVisualTokens.OUTLINE_PIXELS * 2.0,
					Color.WHITE
				)
			_draw_building_outline(icon_image, UIVisualTokens.BUILDING_ICON_STROKE_PIXELS, Color.BLACK)
	elif icon_kind in ["greenery", "greenery_hover", "greenery_active"]:
		_draw_tree_icon(
			icon_image,
			icon_kind == "greenery_hover",
			icon_kind == "greenery_active"
		)
	elif icon_kind in ["landscape", "landscape_hover", "landscape_active"]:
		_draw_landscape_icon(
			icon_image,
			icon_kind == "landscape_hover",
			icon_kind == "landscape_active"
		)
	elif icon_kind in ["terrain_add", "terrain_add_hover"]:
		_draw_terrain_tool_icon(icon_image, true, icon_kind == "terrain_add_hover")
	elif icon_kind in ["terrain_remove", "terrain_remove_hover"]:
		_draw_terrain_tool_icon(icon_image, false, icon_kind == "terrain_remove_hover")
	elif icon_kind.begins_with("category_"):
		var category_kind := icon_kind.trim_prefix("category_")
		var category_hover := category_kind.ends_with("_hover")
		var category_active := category_kind.ends_with("_active")
		category_kind = category_kind.trim_suffix("_hover").trim_suffix("_active")
		_draw_build_category_icon(icon_image, category_kind, category_hover, category_active)
	elif icon_kind in [
		"road", "road_hover",
		"rope_bridge", "rope_bridge_hover",
		"suspension_bridge", "suspension_bridge_hover",
		"tunnel", "tunnel_hover",
		"pile_building", "pile_building_hover",
		"warehouse", "warehouse_hover",
		"small_livable", "small_livable_hover",
	]:
		_draw_catalog_building_icon(
			icon_image,
			icon_kind.trim_suffix("_hover"),
			icon_kind.ends_with("_hover")
		)
	elif icon_kind in ["remove_building", "remove_building_hover"]:
		_draw_dotted_building_outline(
			icon_image,
			icon_kind == "remove_building_hover"
		)
	elif icon_kind in ["excavate", "excavate_hover"]:
		if icon_kind == "excavate_hover":
			_draw_line(icon_image, Vector2(27, 7), Vector2(13, 27), 2.2 + UIVisualTokens.OUTLINE_PIXELS, Color.WHITE)
			_draw_line(icon_image, Vector2(10, 26), Vector2(17, 33), 4.0 + UIVisualTokens.OUTLINE_PIXELS, Color.WHITE)
		_draw_line(icon_image, Vector2(27, 7), Vector2(13, 27), 2.2, Palette.ROOF_LOG)
		_draw_line(icon_image, Vector2(10, 26), Vector2(17, 33), 4.0, Palette.TOOL_METAL)
	elif icon_kind in ["support_preview", "support_preview_hover"]:
		_draw_completed_support_preview(icon_image, icon_kind == "support_preview_hover")
	elif icon_kind == "platform":
		for post_x in [12.0, 28.0]:
			_draw_line(icon_image, Vector2(post_x, 17), Vector2(post_x, 32), 2.2, Palette.ROOF_LOG)
		_draw_line(icon_image, Vector2(9, 15), Vector2(31, 15), 4.0, Palette.WOODEN_ROOF)
	elif icon_kind == "pergola":
		for post_x in [12.0, 28.0]:
			_draw_line(icon_image, Vector2(post_x, 16), Vector2(post_x, 32), 2.2, Palette.ROOF_LOG)
		_draw_line(icon_image, Vector2(9, 14), Vector2(31, 14), 3.5, Palette.SUN)
	elif icon_kind == "house":
		_draw_line(icon_image, Vector2(12, 18), Vector2(12, 32), 2.3, Palette.FOG_AND_SHADOW)
		_draw_line(icon_image, Vector2(28, 18), Vector2(28, 32), 2.3, Palette.FOG_AND_SHADOW)
		_draw_line(icon_image, Vector2(12, 31), Vector2(28, 31), 2.3, Palette.FOG_AND_SHADOW)
		_draw_line(icon_image, Vector2(9, 19), Vector2(20, 9), 2.8, Palette.WOMAN_CLOTHING)
		_draw_line(icon_image, Vector2(20, 9), Vector2(31, 19), 2.8, Palette.WOMAN_CLOTHING)
	elif icon_kind.begins_with("simulation_speed_"):
		var speed_value := icon_kind.trim_prefix("simulation_speed_").to_int()
		var chevron_count := 1 if speed_value <= 1 else (2 if speed_value <= 2 else 3)
		var first_x := 20.0 - float(chevron_count - 1) * 6.0
		for chevron_index in chevron_count:
			var chevron_x := first_x + float(chevron_index) * 12.0
			_draw_line(icon_image, Vector2(chevron_x - 4.0, 12.0), Vector2(chevron_x + 3.0, 20.0), 1.6, Color.WHITE)
			_draw_line(icon_image, Vector2(chevron_x + 3.0, 20.0), Vector2(chevron_x - 4.0, 28.0), 1.6, Color.WHITE)
	elif icon_kind == "save_quit":
		# Unequal strokes keep the X hand-drawn. The white silhouette is hover-only.
		_draw_line(icon_image, Vector2(10, 9), Vector2(31, 30), 3.0, Color.BLACK)
		_draw_line(icon_image, Vector2(30, 10), Vector2(9, 31), 2.6, Color.BLACK)
	else:
		_draw_line(icon_image, Vector2(10, 9), Vector2(31, 30), 3.0 + UIVisualTokens.OUTLINE_PIXELS, Color.WHITE)
		_draw_line(icon_image, Vector2(30, 10), Vector2(9, 31), 2.6 + UIVisualTokens.OUTLINE_PIXELS, Color.WHITE)
		_draw_line(icon_image, Vector2(10, 9), Vector2(31, 30), 3.0, Color.BLACK)
		_draw_line(icon_image, Vector2(30, 10), Vector2(9, 31), 2.6, Color.BLACK)
	return ImageTexture.create_from_image(icon_image)


static func create_resource_icon(resource_kind: String, icon_size := 10) -> ImageTexture:
	var resource_image := Image.create(icon_size, icon_size, false, Image.FORMAT_RGBA8)
	resource_image.fill(Color.TRANSPARENT)
	var centre := float(icon_size - 1) * 0.5
	match resource_kind:
		"log":
			_draw_line(
				resource_image,
				Vector2(1.0, centre),
				Vector2(float(icon_size - 2), centre),
				1.5,
				Palette.ROOF_LOG
			)
			_draw_circle(resource_image, Vector2(1.5, centre), 1.0, Palette.HOME_DOORWAY)
			_draw_circle(resource_image, Vector2(float(icon_size) - 2.0, centre), 1.0, Palette.HOME_DOORWAY)
		"calories":
			var berry_radius := maxf(1.0, float(icon_size) * 0.16)
			_draw_circle(resource_image, Vector2(centre - 1.5, centre + 1.0), berry_radius, Palette.WOODEN_ROOF)
			_draw_circle(resource_image, Vector2(centre + 1.5, centre + 1.0), berry_radius, Palette.WOODEN_ROOF)
			_draw_circle(resource_image, Vector2(centre, centre - 1.5), berry_radius, Palette.WOMAN_CLOTHING)
		"stone", "limestone":
			_draw_circle(resource_image, Vector2(centre, centre), float(icon_size) * 0.34, Palette.LIMESTONE_SIDE)
		_:
			_draw_circle(resource_image, Vector2(centre, centre), float(icon_size) * 0.3, Palette.TOOL_METAL)
	return ImageTexture.create_from_image(resource_image)


static func _draw_tree_icon(target_image: Image, draw_hover: bool, draw_active: bool) -> void:
	if draw_hover:
		_draw_line(target_image, Vector2(20, 19), Vector2(20, 33), 3.7, Color.WHITE)
		for crown_centre in [Vector2(14, 16), Vector2(20, 11), Vector2(26, 16)]:
			_draw_circle(target_image, crown_centre, 7.0, Color.WHITE)
	_draw_line(target_image, Vector2(20, 18), Vector2(20, 33), 2.5, Color.BLACK)
	_draw_line(target_image, Vector2(14, 33), Vector2(26, 33), 1.6, Color.BLACK)
	for crown_centre in [Vector2(14, 16), Vector2(20, 11), Vector2(26, 16)]:
		if draw_active:
			_draw_circle(target_image, crown_centre, 5.5, Color.BLACK)
		else:
			_draw_circle_outline(target_image, crown_centre, 5.5, 1.6, Color.BLACK)


static func _draw_landscape_icon(target_image: Image, draw_hover: bool, draw_active: bool) -> void:
	var dirt_pile := PackedVector2Array([
		Vector2(6, 31), Vector2(10, 23), Vector2(15, 19), Vector2(20, 21),
		Vector2(25, 17), Vector2(31, 22), Vector2(35, 31),
	])
	if draw_hover:
		_draw_polygon_outline(target_image, dirt_pile, 3.6, Color.WHITE)
		_draw_line(target_image, Vector2(27, 6), Vector2(18, 24), 3.8, Color.WHITE)
		_draw_line(target_image, Vector2(15, 22), Vector2(20, 27), 4.8, Color.WHITE)
	if draw_active:
		_fill_polygon(target_image, dirt_pile, Palette.LIMESTONE_SIDE)
	_draw_polygon_outline(target_image, dirt_pile, 1.8, Color.BLACK)
	_draw_line(target_image, Vector2(27, 6), Vector2(18, 24), 2.3, Palette.ROOF_LOG if draw_active else Color.BLACK)
	_draw_line(target_image, Vector2(15, 22), Vector2(20, 27), 3.2, Palette.TOOL_METAL if draw_active else Color.BLACK)


static func _draw_terrain_tool_icon(target_image: Image, is_add: bool, draw_hover: bool) -> void:
	var top_face := PackedVector2Array([
		Vector2(20, 8), Vector2(33, 15), Vector2(20, 22), Vector2(7, 15),
	])
	var left_face := PackedVector2Array([
		Vector2(7, 15), Vector2(20, 22), Vector2(20, 35), Vector2(7, 28),
	])
	var right_face := PackedVector2Array([
		Vector2(20, 22), Vector2(33, 15), Vector2(33, 28), Vector2(20, 35),
	])
	if draw_hover:
		for face in [top_face, left_face, right_face]:
			_draw_polygon_outline(target_image, face, 3.4, Color.WHITE)
	_fill_polygon(target_image, top_face, Palette.SAND_SURFACE)
	_fill_polygon(target_image, left_face, Palette.LIMESTONE_SIDE.darkened(0.16))
	_fill_polygon(target_image, right_face, Palette.LIMESTONE_SIDE)
	for face in [top_face, left_face, right_face]:
		_draw_polygon_outline(target_image, face, 1.3, Color.BLACK)
	_draw_line(target_image, Vector2(15, 27), Vector2(25, 27), 1.6, Color.BLACK)
	if is_add:
		_draw_line(target_image, Vector2(20, 22), Vector2(20, 32), 1.6, Color.BLACK)


static func _draw_polygon_outline(
	target_image: Image,
	polygon: PackedVector2Array,
	radius: float,
	colour: Color
) -> void:
	for point_index in polygon.size():
		_draw_line(
			target_image,
			polygon[point_index],
			polygon[(point_index + 1) % polygon.size()],
			radius,
			colour
		)


static func _draw_build_category_icon(
	target_image: Image,
	category_kind: String,
	draw_hover: bool,
	draw_active: bool
) -> void:
	var foreground := Color.BLACK
	if draw_hover:
		_draw_circle(target_image, Vector2(20, 20), 15.0, Color.WHITE)
	if draw_active:
		_draw_circle(target_image, Vector2(20, 20), 14.0, Palette.LIMESTONE_SIDE)
	match category_kind:
		"structure":
			for point in [Vector2(12, 13), Vector2(28, 13), Vector2(12, 29), Vector2(28, 29)]:
				_draw_circle(target_image, point, 2.8, foreground)
			_draw_line(target_image, Vector2(12, 13), Vector2(28, 13), 1.2, foreground)
			_draw_line(target_image, Vector2(12, 29), Vector2(28, 29), 1.2, foreground)
		"path":
			_draw_line(target_image, Vector2(12, 32), Vector2(17, 8), 2.0, foreground)
			_draw_line(target_image, Vector2(27, 32), Vector2(23, 8), 2.0, foreground)
		"storage":
			_draw_line(target_image, Vector2(10, 29), Vector2(30, 29), 2.0, foreground)
			for stone_x in [12.0, 20.0, 28.0]:
				_draw_circle(target_image, Vector2(stone_x, 23), 3.2, foreground)
			_draw_circle(target_image, Vector2(16, 17), 3.2, foreground)
			_draw_circle(target_image, Vector2(24, 17), 3.2, foreground)
		"livable":
			_draw_line(target_image, Vector2(11, 19), Vector2(20, 10), 2.0, foreground)
			_draw_line(target_image, Vector2(20, 10), Vector2(29, 19), 2.0, foreground)
			_draw_line(target_image, Vector2(13, 18), Vector2(13, 31), 2.0, foreground)
			_draw_line(target_image, Vector2(27, 18), Vector2(27, 31), 2.0, foreground)
			_draw_line(target_image, Vector2(13, 31), Vector2(27, 31), 2.0, foreground)
			_draw_line(target_image, Vector2(20, 23), Vector2(20, 31), 2.0, foreground)


static func _draw_catalog_building_icon(target_image: Image, building_kind: String, draw_hover: bool) -> void:
	if draw_hover:
		_draw_circle(target_image, Vector2(20, 20), 17.0, Color.WHITE)
	match building_kind:
		"road":
			for plank_x in [12.0, 17.5, 23.0, 28.5]:
				_draw_line(target_image, Vector2(plank_x - 4.0, 31), Vector2(plank_x + 4.0, 9), 2.3, Palette.WOODEN_ROOF)
		"rope_bridge", "suspension_bridge":
			var sag := 5.0 if building_kind == "rope_bridge" else -2.0
			for side_y in [14.0, 27.0]:
				_draw_line(target_image, Vector2(7, side_y), Vector2(20, side_y + sag), 1.5, Palette.ROOF_LOG)
				_draw_line(target_image, Vector2(20, side_y + sag), Vector2(33, side_y), 1.5, Palette.ROOF_LOG)
			for plank_x in [10.0, 15.0, 20.0, 25.0, 30.0]:
				var centre_sag := sag * (1.0 - absf(plank_x - 20.0) / 13.0)
				_draw_line(
					target_image,
					Vector2(plank_x, 14.0 + centre_sag),
					Vector2(plank_x, 27.0 + centre_sag),
					1.2,
					Palette.WOODEN_ROOF
				)
		"tunnel":
			_draw_circle_outline(target_image, Vector2(20, 24), 12.0, 3.0, Palette.LIMESTONE_SIDE)
			_fill_polygon(target_image, PackedVector2Array([
				Vector2(8, 24), Vector2(32, 24), Vector2(32, 34), Vector2(8, 34),
			]), Palette.LIMESTONE_SIDE)
		"pile_building":
			for stone_position in [Vector2(9, 30), Vector2(31, 30), Vector2(9, 11), Vector2(31, 11)]:
				_draw_circle(target_image, stone_position, 2.8, Palette.LIMESTONE_SIDE)
		"warehouse":
			_draw_line(target_image, Vector2(9, 14), Vector2(31, 14), 3.0, Palette.WOODEN_ROOF)
			for post_x in [11.0, 29.0]:
				_draw_line(target_image, Vector2(post_x, 14), Vector2(post_x, 33), 2.2, Palette.ROOF_LOG)
			_draw_line(target_image, Vector2(20, 22), Vector2(20, 33), 2.4, Palette.HOME_DOORWAY)
		"small_livable":
			_draw_line(target_image, Vector2(8, 18), Vector2(20, 8), 3.0, Palette.WOODEN_ROOF)
			_draw_line(target_image, Vector2(20, 8), Vector2(32, 18), 3.0, Palette.WOODEN_ROOF)
			_draw_line(target_image, Vector2(11, 18), Vector2(11, 33), 2.2, Palette.ROOF_LOG)
			_draw_line(target_image, Vector2(29, 18), Vector2(29, 33), 2.2, Palette.ROOF_LOG)
			_draw_line(target_image, Vector2(11, 33), Vector2(29, 33), 2.2, Palette.ROOF_LOG)
			_draw_line(target_image, Vector2(20, 24), Vector2(20, 33), 3.0, Palette.HOME_DOORWAY)


static func _draw_completed_support_preview(target_image: Image, draw_hover: bool) -> void:
	# A hard-pixel crop of the completed four-Log Support at the closest camera
	# framing. The projected Sand diamond is one standard World Unit. Its broad
	# footprint and fully visible post height read like the maximum-zoom world
	# view rather than an abstract construction glyph.
	var tile := PackedVector2Array([
		Vector2(20, 16), Vector2(38, 27), Vector2(20, 38), Vector2(2, 27),
	])
	if draw_hover:
		_draw_line(target_image, tile[0], tile[1], 2.0, Color.WHITE)
		_draw_line(target_image, tile[1], tile[2], 2.0, Color.WHITE)
		_draw_line(target_image, tile[2], tile[3], 2.0, Color.WHITE)
		_draw_line(target_image, tile[3], tile[0], 2.0, Color.WHITE)
	_fill_polygon(target_image, tile, Palette.SAND_SURFACE)

	var post_segments: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(20.0, 20.0), Vector2(20.7, 7.0)]),
		PackedVector2Array([Vector2(30.5, 26.7), Vector2(30.0, 13.2)]),
		PackedVector2Array([Vector2(9.5, 26.7), Vector2(10.0, 13.0)]),
		PackedVector2Array([Vector2(20.0, 33.0), Vector2(19.5, 19.0)]),
	]
	# Compact contact shadows use the same exact world shadow colour and are
	# painted once, so overlapping pixels never accumulate into a darker shade.
	var shadow_ends: Array[Vector2] = [
		Vector2(26.0, 23.0), Vector2(27.0, 29.0),
		Vector2(15.0, 30.0), Vector2(22.0, 34.0),
	]
	for post_index in post_segments.size():
		var post_segment := post_segments[post_index]
		var post_base := post_segment[0]
		_draw_line(
			target_image,
			post_base,
			shadow_ends[post_index],
			1.15,
			Palette.FOG_AND_SHADOW
		)
	for post_segment in post_segments:
		if draw_hover:
			_draw_line(target_image, post_segment[0], post_segment[1], 3.25, Color.WHITE)
		_draw_line(target_image, post_segment[0], post_segment[1], 2.35, Palette.HOME_DOORWAY)
		_draw_line(
			target_image,
			post_segment[0] + Vector2(-0.55, 0.0),
			post_segment[1] + Vector2(-0.55, 0.0),
			1.25,
			Palette.ROOF_LOG
		)


static func _draw_building_outline(target_image: Image, stroke_width: float, colour: Color) -> void:
	# Five edges only: the slightly overhanging roof replaces the ceiling line.
	var stroke_radius := stroke_width * 0.5
	_draw_line(target_image, Vector2(12, 18), Vector2(12, 31), stroke_radius, colour)
	_draw_line(target_image, Vector2(12, 31), Vector2(28, 31), stroke_radius, colour)
	_draw_line(target_image, Vector2(28, 31), Vector2(28, 18), stroke_radius, colour)
	_draw_line(target_image, Vector2(9, 19), Vector2(20, 9), stroke_radius, colour)
	_draw_line(target_image, Vector2(20, 9), Vector2(31, 19), stroke_radius, colour)


static func _draw_dotted_building_outline(target_image: Image, draw_hover: bool) -> void:
	var edges: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(12, 18), Vector2(12, 31)]),
		PackedVector2Array([Vector2(12, 31), Vector2(28, 31)]),
		PackedVector2Array([Vector2(28, 31), Vector2(28, 18)]),
		PackedVector2Array([Vector2(9, 19), Vector2(20, 9)]),
		PackedVector2Array([Vector2(20, 9), Vector2(31, 19)]),
	]
	for edge in edges:
		if draw_hover:
			_draw_dotted_line(target_image, edge[0], edge[1], 1.9, Color.WHITE)
		_draw_dotted_line(target_image, edge[0], edge[1], 1.0, Color.BLACK)


static func _draw_dotted_line(
	target_image: Image,
	line_start: Vector2,
	line_end: Vector2,
	radius: float,
	colour: Color
) -> void:
	var line_length := line_start.distance_to(line_end)
	var dot_count := maxi(2, ceili(line_length / 4.5) + 1)
	for dot_index in dot_count:
		var progress := float(dot_index) / float(dot_count - 1)
		_draw_circle(target_image, line_start.lerp(line_end, progress), radius, colour)


static func _fill_polygon(target_image: Image, polygon: PackedVector2Array, colour: Color) -> void:
	for pixel_x in target_image.get_width():
		for pixel_y in target_image.get_height():
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			if Geometry2D.is_point_in_polygon(pixel_centre, polygon):
				target_image.set_pixel(pixel_x, pixel_y, colour)


static func _draw_circle(target_image: Image, centre: Vector2, radius: float, colour: Color) -> void:
	for pixel_x in target_image.get_width():
		for pixel_y in target_image.get_height():
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			if pixel_centre.distance_to(centre) <= radius:
				target_image.set_pixel(pixel_x, pixel_y, colour)


static func _draw_circle_outline(
	target_image: Image,
	centre: Vector2,
	radius: float,
	stroke_width: float,
	colour: Color
) -> void:
	var inner_radius := maxf(0.0, radius - stroke_width)
	for pixel_x in target_image.get_width():
		for pixel_y in target_image.get_height():
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			var distance := pixel_centre.distance_to(centre)
			if distance <= radius and distance >= inner_radius:
				target_image.set_pixel(pixel_x, pixel_y, colour)


static func _draw_line(
	target_image: Image,
	line_start: Vector2,
	line_end: Vector2,
	radius: float,
	colour: Color
) -> void:
	var line_offset := line_end - line_start
	var line_length_squared := line_offset.length_squared()
	for pixel_x in target_image.get_width():
		for pixel_y in target_image.get_height():
			var pixel_centre := Vector2(float(pixel_x) + 0.5, float(pixel_y) + 0.5)
			var projection := 0.0
			if line_length_squared > 0.0:
				projection = clampf(
					(pixel_centre - line_start).dot(line_offset) / line_length_squared,
					0.0,
					1.0
				)
			var nearest_point := line_start + line_offset * projection
			if pixel_centre.distance_to(nearest_point) <= radius:
				target_image.set_pixel(pixel_x, pixel_y, colour)
