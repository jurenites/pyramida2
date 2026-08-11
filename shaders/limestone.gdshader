shader_type spatial;
render_mode unshaded;

uniform vec4 top_color : source_color;
uniform vec4 side_color : source_color;
uniform vec3 sun_direction_world = vec3(0.0, 1.0, 0.0);
uniform float daylight = 1.0;
varying vec3 world_normal;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float is_top = step(0.7, world_normal.y);
	float sun_facing = max(dot(normalize(world_normal), normalize(sun_direction_world)), 0.0);
	float side_band = 0.68;
	side_band += 0.16 * step(0.18, sun_facing);
	side_band += 0.16 * step(0.62, sun_facing);
	float night_factor = mix(0.58, 1.0, daylight);
	vec3 shaded_side = side_color.rgb * side_band * night_factor;
	ALBEDO = mix(shaded_side, top_color.rgb, is_top);
	ROUGHNESS = 0.92;
}
