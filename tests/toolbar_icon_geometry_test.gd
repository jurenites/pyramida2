extends SceneTree

const MainScript = preload("res://scripts/main.gd")


func _initialize() -> void:
	var main := MainScript.new()
	var building_texture := main._create_toolbar_icon("building")
	var building_image := building_texture.get_image()
	var black_pixel_count := 0
	# At y=24 only the two vertical walls cross the scanline. An exact two-pixel
	# stroke therefore produces two black pixels per wall and four in total.
	for pixel_x in building_image.get_width():
		if building_image.get_pixel(pixel_x, 24) == Color.BLACK:
			black_pixel_count += 1
	if black_pixel_count != 4:
		printerr(
			"FAIL: Building icon must use two-pixel strokes; scanline has %d black pixels"
			% black_pixel_count
		)
		main.free()
		quit(1)
		return
	print("PASS: toolbar icon geometry")
	main.free()
	quit(0)
