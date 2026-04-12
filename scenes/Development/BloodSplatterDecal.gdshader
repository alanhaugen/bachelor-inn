shader_type spatial;
render_mode world_vertex_coords, unshaded;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;
uniform float cube_half_size = 1.0;

uniform float pixels_p_unit = 16.0;

varying mat4 INV_MODEL_MATRIX;

uniform sampler2D d_noise;
uniform float d_Value : hint_range(0.0, 1.0) = 0.0;

void vertex(){
	INV_MODEL_MATRIX = inverse(MODEL_MATRIX);
}

// Credit: https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
vec3 world_pos_from_depth(float depth, vec2 screen_uv, mat4 inverse_proj, mat4 inverse_view) {
	float z = depth;
	
	vec4 clipSpacePosition = vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec4 viewSpacePosition = inverse_proj * clipSpacePosition;
	
	viewSpacePosition /= viewSpacePosition.w;
	
	vec4 worldSpacePosition = inverse_view * viewSpacePosition;
	
	return worldSpacePosition.xyz;
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 world_pos = world_pos_from_depth(depth, SCREEN_UV, INV_PROJECTION_MATRIX, (INV_VIEW_MATRIX));
	world_pos = floor(world_pos * pixels_p_unit) / pixels_p_unit;
	
	vec3 s_pos = floor(world_pos * pixels_p_unit + 0.5) / pixels_p_unit;
	vec4 test_pos = (INV_MODEL_MATRIX * vec4(s_pos, 1.0));
	
	if (abs(test_pos.x) > cube_half_size ||abs(test_pos.y) > cube_half_size || abs(test_pos.z) > cube_half_size) {
		discard;
	}
	vec2 uv = test_pos.xz + 0.5;
	float d = textureLod(d_noise, uv, 0.0).r;
	if (d < d_Value) {
		discard;
	}
	
	if (textureLod(texture_albedo, uv, 0.0).a < 0.5) {
    	discard;
	}
	
	ALBEDO = textureLod(texture_albedo, uv, 0.0).rgb * albedo.rgb;
}
