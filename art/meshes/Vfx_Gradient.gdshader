shader_type spatial;
render_mode cull_disabled;


uniform sampler2D noiseTex: source_color, filter_nearest;
uniform vec4 colorTint: source_color = vec4(1.0);
uniform vec2 timeMovement = vec2(1.0,0.0);

void fragment() {
	vec2 uv = UV;
	vec2 tuv = UV + timeMovement * TIME;
	vec4 tex = texture(noiseTex, tuv);

	tex *= uv.y / 2.0;
	
	ALBEDO = vec3(colorTint.xyz);
	ALPHA = tex.a;
}


