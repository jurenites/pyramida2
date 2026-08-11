shader_type spatial;
render_mode unshaded;

uniform vec4 bright_color : source_color;
uniform vec4 dark_color : source_color;
varying vec3 world_normal;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 key_direction = normalize(vec3(-0.48, 0.78, -0.4));
	float bright_side = step(0.18, dot(normalize(world_normal), key_direction));
	ALBEDO = mix(dark_color.rgb, bright_color.rgb, bright_side);
	ROUGHNESS = 0.94;
}
