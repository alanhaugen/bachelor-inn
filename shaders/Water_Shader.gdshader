// this code working on godot 4.3
shader_type spatial;
render_mode cull_disabled; // specular_schlick_ggx

//Water Color
uniform vec4 color : source_color;
uniform vec4 deep_water: source_color;

uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0;

//Water Speed
uniform float speed: hint_range(-1, 1) = 0.02;


uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;



//depth-fade 
uniform float beer_law_factor = 2.0;
uniform float _distance = 50.0;

//Water foam 
uniform vec4 edge_color: source_color;
uniform float edge_scale = 0.1;
uniform float near = 0.1;
uniform float far = 100.0;

//Water Wave 
uniform vec2 wave_direction = vec2(2.0,0.0); // Direction of wave 1
uniform vec2 wave_direction2 = vec2(0.0,1.0); // Direction of wave 2
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025; // Rate of movement multiplied by TIME
uniform float height_scale = 0.15;
uniform float noise_scale = 10.0;


// Water Noise
uniform float scale = 10.0;
uniform sampler2D noise1: filter_nearest; 
uniform vec3 overlay: source_color;
uniform sampler2D noise2: filter_nearest;
uniform sampler2D wave;
uniform sampler2D normalmap: hint_normal;

// Varying variables
varying float height;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}



float rim(float depth) {
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

float calc_depth_fade(float depth, mat4 projection_matrix, 
						vec4 fragcoord, float beer_factor, float __distance, vec3 vertex) {
	
	float scene_depth = depth;

	scene_depth = scene_depth * 2.0 - 1.0;
	scene_depth = projection_matrix[3][2] / (scene_depth + projection_matrix[2][2]);
	scene_depth = scene_depth + vertex.z; // z is negative
	
	// application of beers law
	scene_depth = exp(-scene_depth * beer_factor);
	
	float screen_depth = fragcoord.z;
	
	float depth_fade = (scene_depth - screen_depth) / __distance;
	
	depth_fade = clamp(depth_fade, 0.0, 1.0);
	
	return depth_fade;
}


void fragment() {
	float time = TIME * speed;
	vec2 uv = world_pos.xz / scale;
	
	vec3 n1 = texture(noise1, vec2(uv.x+ time, uv.y + 0.16 )).rgb;
	vec3 n2 = texture(noise2, vec2(uv.x- time, uv.y )).rgb;
	n2 *= overlay;
	
	float sum = (n1.r + n2.r);
	
	float z_depth = rim(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	
	float z_pos = rim(FRAGCOORD.z);
	
	float diff = z_depth - z_pos;
	
	// depth-fade
	float z_depth_fade = calc_depth_fade(texture(DEPTH_TEXTURE, SCREEN_UV).x, PROJECTION_MATRIX, FRAGCOORD, beer_law_factor, _distance, VERTEX);
	float z_fade = rim(FRAGCOORD.z);
	float fade_diff = z_depth_fade - z_fade;
	vec4 gradientcolor = mix(color, deep_water, z_depth_fade);
	
	//If enable this line 119-120, it can caused bug for edge effect
	vec2 displacement = vec2(sum * 0.01);
	diff += displacement.x * 15.0;
	
	vec4 depth_color_adj = mix(edge_color, gradientcolor, step(edge_scale, diff));
	
	vec4 alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);


	ALBEDO = vec3(sum) + mix(alpha.rgb, gradientcolor.rgb, gradientcolor.a);
	

	
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	
	vec3 pixel_position = upos.xyz / upos.w;
    
	// Adjust the edge foam calculation to include edge_scale
	float foam_mask = 1.0 - smoothstep(
	    pixel_position.z + 0.05,
	    pixel_position.z + 0.05 + edge_scale,
	    VERTEX.z
	);

	ALBEDO = mix(ALBEDO, edge_color.rgb, foam_mask);
	

}
void light() {
    float shadow = ATTENUATION;

    float noise = texture(noise1, world_pos.xz * 0.1).r;

    shadow *= mix(0.2, 1.2, noise);

    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * shadow;
}