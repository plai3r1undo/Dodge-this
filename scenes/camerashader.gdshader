shader_type canvas_item;

uniform float pixelate: hint_range(2, 512, 4) = 256;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;


void fragment() {
	vec2 uv = floor(UV * pixelate) / pixelate;
	COLOR = textureLod(screen_texture, uv, 0.0);
}
