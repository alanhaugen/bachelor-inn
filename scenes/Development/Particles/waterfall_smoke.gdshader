shader_type spatial;

void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(uv.y, uv.y, uv.y);
	
	ALPHA = uv.y;
}

