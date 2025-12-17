shader_type spatial;

uniform sampler2D albedo : source_color, filter_nearest;
uniform vec2 tile_scale = vec2(2, 2);
uniform float fade_dist = 4.0;
varying vec3 world_position;

void vertex()
{
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1)).xyz;
}
void fragment() {
    vec2 uv = world_position.xz * tile_scale;
    uv = fract(uv);
	float dist = length(world_position.xz);
	float fade = 1.0 - smoothstep(0.0, fade_dist, dist);
    ALBEDO = texture(albedo, uv).rgb * fade;
}
