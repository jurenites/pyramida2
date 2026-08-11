shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_block_size = 2.0;

void fragment() {
	vec2 block_uv = SCREEN_PIXEL_SIZE * pixel_block_size;
	vec2 sampled_uv = (floor(SCREEN_UV / block_uv) + vec2(0.5)) * block_uv;
	COLOR = textureLod(screen_texture, sampled_uv, 0.0);
}
