shader_type spatial;
render_mode  skip_vertex_transform;

group_uniforms Tex;
uniform sampler2D albedo: source_color, filter_nearest;

group_uniforms Wind;
uniform float speed = 1.0;
uniform float minStrength : hint_range(0.0, 1.0);
uniform float maxStrength : hint_range(0.0, 1.0);
uniform float interval = 3.5;
uniform float detail = 1.0;
uniform float distortion : hint_range(0.0, 1.0);
uniform vec2 direction = vec2(1.0, 0.0);
uniform float heightOffset = 0.0;

vec3 getWind(mat4 worldMatrix, vec3 vertex, float timer){
	vec4 pos = worldMatrix * mix(vec4(1.0), vec4(vertex, 1.0), distortion);
	float time = timer * speed + pos.x + pos.z;
	float diff = pow(maxStrength - minStrength, 2);
	float strength = clamp(minStrength + diff + sin(time / interval) * diff, minStrength, maxStrength);
	float wind = (sin(time) + cos(time * detail)) * strength * max(0.0, vertex.y - heightOffset);
	vec2 dir = normalize(direction);

	return vec3(wind * dir.x, 0.0, wind * dir.y);
}

void vertex() {
	vec4 worldPos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	worldPos.xyz += getWind(MODEL_MATRIX, VERTEX, TIME);
	VERTEX = (VIEW_MATRIX * worldPos).xyz;
	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;


}

void fragment() {
	vec2 uv = UV;
	vec4 A = texture(albedo, UV);
	ALBEDO = A.rgb;

	ALPHA = A.a;
}