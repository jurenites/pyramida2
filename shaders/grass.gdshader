shader_type spatial;
render_mode cull_back, depth_draw_opaque, unshaded;

uniform vec4 grass_color : source_color;
uniform float wind_strength = 0.022;
uniform float wind_speed = 1.15;

varying float instance_seed;

float grass_hash(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	vec3 instance_origin = MODEL_MATRIX[3].xyz;
	instance_seed = grass_hash(instance_origin.xz);
	float height_variation = mix(0.82, 1.18, grass_hash(instance_origin.xz + vec2(19.7)));
	float width_variation = mix(0.8, 1.16, grass_hash(instance_origin.zx + vec2(31.3)));
	VERTEX.y *= height_variation;
	VERTEX.x *= width_variation;

	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	float scale_z = length(MODEL_MATRIX[2].xyz);
	vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz);
	vec3 world_up = vec3(0.0, 1.0, 0.0);
	vec3 camera_forward = normalize(cross(camera_right, world_up));
	mat4 billboard_model = mat4(
		vec4(camera_right * scale_x, 0.0),
		vec4(world_up * scale_y, 0.0),
		vec4(camera_forward * scale_z, 0.0),
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_model;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float blade_mask(vec2 uv, float centre, float lean, float height, float base_width, float tip_width, float wind) {
	if (uv.y > height) {
		return 0.0;
	}
	float blade_height = clamp(uv.y / height, 0.0, 1.0);
	float blade_centre = centre + lean * blade_height + wind * blade_height * blade_height;
	float half_width = mix(base_width, tip_width, smoothstep(0.0, 1.0, blade_height));
	return step(abs(uv.x - blade_centre), half_width);
}

void fragment() {
	float wave = sin(TIME * wind_speed + instance_seed * 12.0) * wind_strength;
	float silhouette = 0.0;
	silhouette = max(silhouette, blade_mask(UV, 0.2, -0.08, 0.62, 0.105, 0.026, wave));
	silhouette = max(silhouette, blade_mask(UV, 0.4, -0.025, 0.9, 0.115, 0.026, wave));
	silhouette = max(silhouette, blade_mask(UV, 0.61, 0.035, 0.76, 0.11, 0.025, wave));
	silhouette = max(silhouette, blade_mask(UV, 0.79, 0.075, 0.57, 0.1, 0.024, wave));
	if (silhouette < 0.5) {
		discard;
	}
	ALBEDO = grass_color.rgb;
	ROUGHNESS = 0.92;
}
