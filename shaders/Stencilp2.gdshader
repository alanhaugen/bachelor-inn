shader_type spatial;
render_mode unshaded, blend_mix, depth_test_inverted, depth_draw_never;
stencil_mode read, compare_not_equal, 1;

group_uniforms Animation;
uniform sampler2D mask_atlas : source_color, filter_nearest;

uniform int frame_index = 0;
uniform int frame_columns = 6;
uniform int frame_rows = 1;

uniform vec3 outline_color : source_color = vec3(1.0);

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

    float outline = texture(mask_atlas, uv).r;
    if (outline <= 0.1) discard;

    ALBEDO = outline_color * outline;

}
