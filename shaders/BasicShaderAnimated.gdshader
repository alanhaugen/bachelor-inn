shader_type spatial;

uniform sampler2D diffuse_tex : source_color, filter_nearest;
uniform vec4 colorTint: source_color = vec4(1.0);


uniform int frame_index = 0;
uniform int frame_columns = 1;
uniform int frame_rows = 1;

//taken from character animator, i think itll just work :3
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
	vec4 d = texture(diffuse_tex, uv);
	ALPHA= d.a;
	d *= colorTint;
	ALBEDO = d.rgb;
	
}


