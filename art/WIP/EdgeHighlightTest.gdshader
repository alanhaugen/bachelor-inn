shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_disabled;

group_uniforms Animation;
uniform sampler2D diffuse_atlas: source_color, filter_nearest;
uniform sampler2D normal_atlas: hint_normal, filter_nearest;
uniform sampler2D mask_atlas: source_color, filter_nearest;

uniform int frame_index = 0;
uniform int frame_columns = 6;
uniform int frame_rows = 1;

group_uniforms Effects;
uniform bool grey_tint = false;

uniform float hit_effect = 0.0;
uniform vec3 hit_effect_color : source_color = vec3(1.0,1.0,1.0);

group_uniforms Settings;
uniform float edge_strength = 1.0;
uniform vec4 edge_tint : source_color = vec4(1.0);
uniform float normal_tilt : hint_range(0.0, 4.0) = 1.0;
uniform float normal_sensitivity : hint_range(0.0, 1.0) = 0.1;
uniform bool flip_normal_y = true;


vec2 atlas_uv(vec2 uv) {
    int col = frame_index % frame_columns;
    int row = frame_index / frame_columns;

    vec2 frame_size = vec2(
        1.0 / float(frame_columns),
        1.0 / float(frame_rows)
    );

    uv *= frame_size;
    uv += vec2(float(col), float(row)) * frame_size;

    return uv;
}


void fragment() {
    vec2 uv = atlas_uv(UV);

    vec3 n = texture(normal_atlas, uv).rgb * 2.0 - 1.0;
    if (flip_normal_y) {
        n.y = -n.y;
    }
    n = normalize(n * normal_tilt);
    NORMAL = normalize(NORMAL + n * normal_sensitivity);

    vec4 d = texture(diffuse_atlas, uv);
    if (d.a < 0.5) discard;
	
	if (grey_tint)
	{
		vec3 grey_color = vec3(0.338, 0.338, 0.338);
		d.rgb *= grey_color;
	}
	if (hit_effect > 0.0){
		d.rgb = mix(d.rgb, d.rgb * hit_effect_color, hit_effect);
	}

    ALBEDO = d.rgb;
}


void light() {
    float NdotL = max(dot(NORMAL, LIGHT), 0.0);
    float DL = step(0.0, NdotL);
    DIFFUSE_LIGHT += NdotL * LIGHT_COLOR * ATTENUATION;

    float edge = pow(2.0 * NdotL, 4.0);
    float mask = texture(mask_atlas, atlas_uv(UV)).r;

    vec3 edge_light = edge_tint.rgb * edge * edge_strength * mask;
    DIFFUSE_LIGHT += edge_light * ATTENUATION;
}
