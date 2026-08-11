extends SceneTree

const MainScript = preload("res://scripts/main.gd")


func _initialize() -> void:
	var main := MainScript.new()
	var building_texture := main._create_toolbar_icon("building")
	var building_image := building_texture.get_image()
	var black_pixel_count := 0
	# At y=24 only the two vertical walls cross the scanline. An exact four-pixel
	# stroke therefore produces four black pixels per wall and eight in total.
	for pixel_x in building_image.get_width():
		if building_image.get_pixel(pixel_x, 24) == Color.BLACK:
			black_pixel_count += 1
	if black_pixel_count != 8:
		printerr(
			"FAIL: Building icon must use four-pixel strokes; scanline has %d black pixels"
			% black_pixel_count
		)
		main.free()
		quit(1)
		return

	for speed_and_chevrons in [[1, 1], [2, 2], [4, 3]]:
		var speed_value := int(speed_and_chevrons[0])
		var expected_chevrons := int(speed_and_chevrons[1])
		var speed_image := ToolbarIconRenderer.create_icon("simulation_speed_%d" % speed_value).get_image()
		var occupied_column_groups := 0
		var previous_column_occupied := false
		for pixel_x in speed_image.get_width():
			var column_occupied := false
			for pixel_y in speed_image.get_height():
				if speed_image.get_pixel(pixel_x, pixel_y).a > 0.0:
					column_occupied = true
					break
			if column_occupied and not previous_column_occupied:
				occupied_column_groups += 1
			previous_column_occupied = column_occupied
		if occupied_column_groups != expected_chevrons:
			printerr(
				"FAIL: Speed %d icon must show %d chevrons; found %d"
				% [speed_value, expected_chevrons, occupied_column_groups]
			)
			main.free()
			quit(1)
			return
	print("PASS: toolbar icon geometry")
	main.free()
	quit(0)
