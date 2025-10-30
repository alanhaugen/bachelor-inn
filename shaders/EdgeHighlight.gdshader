shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_disabled;

group_uniforms Textures; 
uniform sampler2D diffuse_tex : source_color, filter_nearest;
uniform sampler2D normal_map : hint_normal, filter_nearest;
uniform sampler2D edge_mask : source_color, filter_nearest;

group_uniforms Settings;
uniform float edge_strength = 1.0;
uniform vec4 edge_tint : source_color = vec4(1.0);
uniform float normal_tilt : hint_range(0.0,4.0) = 1.0;
uniform float normal_sensitivity : hint_range(0.0, 1.0) =  0.1;
uniform bool flip_normal_y = true;

void fragment() {
	vec3 n = texture(normal_map, UV).rgb * 2.0 - 1.0;
	if(flip_normal_y) {
		n.y = -n.y;
	}
	n = normalize(vec3(n * normal_tilt));
	
	NORMAL = normalize(NORMAL + n * normal_sensitivity);
	
	vec4 d = texture(diffuse_tex, UV);
	if(d.a < 0.5) discard;
	
	ALBEDO = d.rgb;
}

void light() {

	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float L = step(0.0, NdotL);
	float DL = step(0.0, NdotL);
	DIFFUSE_LIGHT += DL * LIGHT_COLOR * ATTENUATION;

	float edge = pow(2.0 * NdotL, 4.0);

	float mask = texture(edge_mask, UV).r;
	
	vec3 edge_light = vec3(L) * edge_tint.rgb * edge * edge_strength * mask;
	DIFFUSE_LIGHT += edge_light * LIGHT_COLOR * ATTENUATION;
}
