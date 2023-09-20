shader_type spatial;
render_mode unshaded;
// render_mode diffuse_toon; // simple toon shader works, but looks too flat to my liking. need further work to improve
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

//resolution must be divisible by pixel_size
const int pixel_size = 6; 

// References to built-in functions 
// https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#fragment-built-ins
void fragment() {
	float x = float(int(FRAGCOORD.x) % pixel_size);
	float y = float(int(FRAGCOORD.y) % pixel_size);

	x = FRAGCOORD.x + floor(float(pixel_size) / 2.0) - x;
	y = FRAGCOORD.y + floor(float(pixel_size) / 2.0) - y;
	
	// set albedo value on the current coordinate based on vec2(x,y) / viewport_size 
	ALBEDO = texture(SCREEN_TEXTURE, vec2(x, y) / VIEWPORT_SIZE).xyz;
}