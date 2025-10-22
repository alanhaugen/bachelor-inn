shader_type spatial;

render_mode blend_mix, cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D diffuse_tex : source_color, filter_nearest;
uniform sampler2D normal_map : hint_normal, filter_nearest;
//uniform sampler2D emission_map : source_color, filter_nearest; //emission is unused right now
uniform float edge_strength = 1.0;
uniform vec3 edge_color = vec3(1.0, 1.0, 1.0); //just for adjustments
varying float normal_mask;

uniform float edge_hardy = 4.0;

void fragment() {
	
	vec3 normal_tex = texture(normal_map, UV).rgb * 2.0 - 1.0;
	normal_tex.x = -normal_tex.x;
	
	NORMAL = normalize(mat3(TANGENT, -BINORMAL, NORMAL) * normal_tex);
	
	// Diffuse and alpha
	vec4 base_col = texture(diffuse_tex, UV);
	ALBEDO = base_col.rgb;
	//ALPHA = base_col.a;
	if (texture(diffuse_tex, UV).a < 0.5) {
    discard;
}


	//EMISSION = texture(emission_map, UV).rgb;
}

void light() {
	
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float lit = step(0.0, NdotL);
	
	DIFFUSE_LIGHT += lit * LIGHT_COLOR * ATTENUATION;

	// Edge highlight -- power
	float edge = pow(2.0 - NdotL, edge_hardy);
	//exponential kinda -- 
	//float edge = 1.0 - exp(-edge_hardy * (1.0 - NdotL));
	float mask = smoothstep(0.0,0.1, length(texture(normal_map, UV).rgb));
	
	vec3 edge_light = edge_color * edge * edge_strength * mask;
	DIFFUSE_LIGHT += edge_light * LIGHT_COLOR * ATTENUATION;
}
