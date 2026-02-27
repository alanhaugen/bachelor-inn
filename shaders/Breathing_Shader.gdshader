shader_type spatial;
render_mode cull_disabled;


uniform sampler2D noiseTex: source_color, filter_nearest;
uniform vec4 colorTint: source_color = vec4(1.0);
uniform vec2 timeMovement = vec2(1.0,0.0);
uniform sampler2D breathTex: source_color, filter_nearest;

void fragment() {
	vec2 uv = UV;
	vec2 tuv = UV + timeMovement * TIME;
	vec4 tex = texture(noiseTex, tuv);
	vec4 bt = texture(breathTex, UV);
	//tex *= uv.y / 2.0;

	float s = (sin(TIME) + 1.0) * 0.5;
	if (bt.b <= s){
		discard;
	} else {
		bt.b = 1.0;
	}
	//bt.b = max(bt.b, (sin(TIME) + 1.0) * 0.5);


	ALBEDO = vec3(1,1,1);
	ALPHA = bt.b;
}
