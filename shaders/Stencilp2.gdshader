// second shader draws the character's silhouette if behind a wall

shader_type spatial;
render_mode unshaded, blend_mix, depth_test_inverted, depth_draw_never;
stencil_mode read, write, compare_not_equal, 1;

uniform sampler2D diffuse_tex : source_color, filter_nearest;
uniform float dot_size = 0.1; // radius of each dot
uniform float grid_density = 16.0; // number of dots per axis
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform vec3 shadow_colour:source_color = vec3(0.7,0.7,0.9);

void fragment() {
	vec2 grid_uv = SCREEN_UV * grid_density;
    vec2 cell = fract(grid_uv); // local position inside each grid cell
    vec2 center = vec2(0.5);    // center of the cell
	if (texture(diffuse_tex, UV).a < 0.5) {
    discard;
	}
    float dist = distance(cell, center);
    float mask = step(dist, dot_size); // 1.0 inside dot, 0.0 outside
	
	
	
    ALBEDO = mix(shadow_colour, vec3(1.0), mask); 
	
}