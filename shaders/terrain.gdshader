shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 surface_color : source_color;
uniform vec4 shadow_color : source_color;
uniform float daylight = 1.0;
uniform vec2 cloud_shadow_offset;
uniform bool cloud_shadows_enabled = false;
uniform int citizen_count = 0;
uniform vec2 citizen_positions[32];
uniform float citizen_clear_radius = 4.4;
uniform float cloud_shadow_cell_size = 0.5;
uniform float cloud_cell_coverage_threshold = 0.5;
uniform int excavated_cell_count = 0;
uniform vec2 excavated_cells[64];
varying vec2 world_xz;

float hash_cell(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float inside_ellipse(vec2 point, vec2 radius) {
	return 1.0 - step(1.0, length(point / radius));
}

float raw_cloud_coverage(vec2 moving_position) {
	const float CELL_SIZE = 34.0;
	vec2 base_cell = floor(moving_position / CELL_SIZE);
	float covered = 0.0;
	for (int x_offset = -1; x_offset <= 1; x_offset++) {
		for (int y_offset = -1; y_offset <= 1; y_offset++) {
			vec2 cell = base_cell + vec2(float(x_offset), float(y_offset));
			float first_seed = hash_cell(cell);
			float second_seed = hash_cell(cell + vec2(19.0, 7.0));
			vec2 centre = (cell + vec2(0.2 + first_seed * 0.6, 0.2 + second_seed * 0.6)) * CELL_SIZE;
			vec2 blob_position = moving_position - centre;
			vec2 radius = vec2(5.5 + first_seed * 5.0, 4.0 + second_seed * 3.5);
			float main_blob = inside_ellipse(blob_position, radius);
			float left_blob = inside_ellipse(blob_position + vec2(radius.x * 0.65, -1.0), radius * vec2(0.62, 0.72));
			float right_blob = inside_ellipse(blob_position - vec2(radius.x * 0.65, 1.0), radius * vec2(0.68, 0.78));
			covered = max(covered, max(main_blob, max(left_blob, right_blob)));
		}
	}
	return covered;
}

float cloud_cell_shadow(vec2 shadow_cell) {
	vec2 cell_origin = shadow_cell * cloud_shadow_cell_size;
	vec2 cell_centre = cell_origin + vec2(cloud_shadow_cell_size * 0.5);
	for (int citizen_index = 0; citizen_index < 32; citizen_index++) {
		if (citizen_index >= citizen_count) {
			break;
		}
		if (distance(cell_centre, citizen_positions[citizen_index]) <= citizen_clear_radius) {
			return 0.0;
		}
	}

	vec2 sample_offset = vec2(cloud_shadow_cell_size * 0.42);
	float covered_weight = raw_cloud_coverage(cell_centre - cloud_shadow_offset) * 4.0;
	covered_weight += raw_cloud_coverage(cell_centre + vec2(-sample_offset.x, -sample_offset.y) - cloud_shadow_offset);
	covered_weight += raw_cloud_coverage(cell_centre + vec2(sample_offset.x, -sample_offset.y) - cloud_shadow_offset);
	covered_weight += raw_cloud_coverage(cell_centre + vec2(-sample_offset.x, sample_offset.y) - cloud_shadow_offset);
	covered_weight += raw_cloud_coverage(cell_centre + sample_offset - cloud_shadow_offset);
	float estimated_coverage = covered_weight / 8.0;
	return step(cloud_cell_coverage_threshold + 0.0001, estimated_coverage);
}

float cloud_coverage(vec2 ground_position) {
	if (!cloud_shadows_enabled) {
		return 0.0;
	}
	// Coverage remains binary, but exposed 90-degree cell corners are clipped
	// to quarter circles like the interpolated fog contour instead of leaving
	// a staircase made exclusively from sharp rectangles.
	vec2 scaled_position = ground_position / cloud_shadow_cell_size;
	vec2 shadow_cell = floor(scaled_position);
	if (cloud_cell_shadow(shadow_cell) < 0.5) {
		return 0.0;
	}
	vec2 local_position = fract(scaled_position);
	const float CORNER_RADIUS = 0.38;
	float west = cloud_cell_shadow(shadow_cell + vec2(-1.0, 0.0));
	float east = cloud_cell_shadow(shadow_cell + vec2(1.0, 0.0));
	float north = cloud_cell_shadow(shadow_cell + vec2(0.0, -1.0));
	float south = cloud_cell_shadow(shadow_cell + vec2(0.0, 1.0));
	if (west < 0.5 && north < 0.5 && local_position.x < CORNER_RADIUS && local_position.y < CORNER_RADIUS && distance(local_position, vec2(CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	if (east < 0.5 && north < 0.5 && local_position.x > 1.0 - CORNER_RADIUS && local_position.y < CORNER_RADIUS && distance(local_position, vec2(1.0 - CORNER_RADIUS, CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	if (west < 0.5 && south < 0.5 && local_position.x < CORNER_RADIUS && local_position.y > 1.0 - CORNER_RADIUS && distance(local_position, vec2(CORNER_RADIUS, 1.0 - CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	if (east < 0.5 && south < 0.5 && local_position.x > 1.0 - CORNER_RADIUS && local_position.y > 1.0 - CORNER_RADIUS && distance(local_position, vec2(1.0 - CORNER_RADIUS)) > CORNER_RADIUS) {
		return 0.0;
	}
	return 1.0;
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 terrain_cell = floor(world_xz);
	for (int excavation_index = 0; excavation_index < 64; excavation_index++) {
		if (excavation_index >= excavated_cell_count) {
			break;
		}
		if (distance(terrain_cell, excavated_cells[excavation_index]) < 0.1) {
			discard;
		}
	}
	ALBEDO = mix(surface_color.rgb, shadow_color.rgb, cloud_coverage(world_xz));
	ROUGHNESS = 1.0;
	EMISSION = ALBEDO * (1.0 - daylight);
}

void light() {
	float binary_light = step(0.5, ATTENUATION);
	// Godot multiplies DIFFUSE_LIGHT by ALBEDO after this function. Supplying
	// the colour ratio makes the final shadow pixel equal shadow_color rather
	// than tinting it with the surface (for example gray becoming brown on sand).
	vec3 shadow_ratio = shadow_color.rgb / max(ALBEDO, vec3(0.001));
	DIFFUSE_LIGHT += mix(shadow_ratio, vec3(1.0), binary_light) * daylight;
}
