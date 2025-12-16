shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform vec2 tile_scale = vec2(2, 2); // how many times to repeat per UV unit
uniform float fade_dist = 4.0;
varying vec3 world_position;

void vertex()
{
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1)).xyz;
}

void fragment() {
    // Scale UVs
    vec2 uv = world_position.xz * tile_scale;

    // Wrap into 0..1 range so it repeats infinitely
    uv = fract(uv);

	float dist = length(world_position.xz);
	float fade = 1.0 - smoothstep(0.0, fade_dist, dist);

    ALBEDO = texture(albedo_tex, uv).rgb * fade;
}
