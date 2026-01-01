shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D diffuse_tex : source_color, filter_nearest;
uniform sampler2D normal_map : hint_normal, filter_nearest;
uniform sampler2D edge_mask : source_color, filter_nearest;

uniform float edge_strength = 1.0;
uniform vec4 edge_tint : source_color = vec4(1.0);
uniform float normal_tilt = 1.0;
uniform float normal_sensitivity = 0.1;
uniform bool flip_normal_y = true;

varying vec3 local_normal;

void fragment() {
    vec3 n = texture(normal_map, UV).rgb * 2.0 - 1.0;
    if (flip_normal_y) n.y = -n.y;

    n = normalize(n * normal_tilt);
    local_normal = normalize(NORMAL + n * normal_sensitivity);

    vec4 d = texture(diffuse_tex, UV);
    if (d.a < 0.5) discard;

    ALBEDO = d.rgb;
}

void light() {
    float NdotL = max(dot(local_normal, LIGHT), 0.0);
    DIFFUSE_LIGHT += NdotL * LIGHT_COLOR * ATTENUATION;

    float edge = pow(NdotL, 4.0);
    float mask = texture(edge_mask, UV).r;

    vec3 edge_light = edge_tint.rgb * edge * edge_strength * mask;
    DIFFUSE_LIGHT += edge_light * LIGHT_COLOR * ATTENUATION;
}
