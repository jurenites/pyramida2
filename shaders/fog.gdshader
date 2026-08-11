shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D fog_mask : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color;

void fragment() {
	// Linear mask interpolation is used only to locate the binary contour.
	// The rendered result still has no fractional alpha: every fragment is
	// either exact fog colour or completely discarded.
	float revealed = texture(fog_mask, UV).r;
	if (revealed >= 0.5) {
		discard;
	}
	ALBEDO = fog_color.rgb;
	ROUGHNESS = 1.0;
}
