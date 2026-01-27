shader_type canvas_item;

uniform vec3 colA : source_color = vec3(0.1, 0.1, 0.1);
uniform vec3 colB : source_color = vec3(0.1, 0.1, 0.1);
uniform vec3 colC : source_color = vec3(0.1, 0.1, 0.1);
uniform float pixelation = 8.0;
uniform bool pixelated = true;
uniform float offsety = 0;
uniform float offsetx = 0;
uniform float speed = 1.0;

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}


float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y);

    return res * res;
}

/*
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f*f*(3.0 - 2.0*f);

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float noise (in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Four corners in 2D of a tile
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}
*/
#define NUM_OCTAVES 5
#define iTime (TIME * speed)
const mat2 mtx = mat2( vec2(0.80, -0.60), vec2(0.60, 0.80) );

/*
float fbm(vec2 p) {
    float f = 0.0;
    f += 0.500000 * noise(p + iTime, t_size); 
		p = mtx * p * 2.02;
    f += 0.031250 * noise(p,t_size);         
		p = mtx * p * 2.01;
    f += 0.250000 * noise(p,t_size);         
		p = mtx * p * 2.03;
    f += 0.125000 * noise(p,t_size);         
		p = mtx * p * 2.01;
    f += 0.062500 * noise(p,t_size);         
		p = mtx * p * 2.04;
    f += 0.015625 * noise(p + sin(iTime),t_size);
    return f / 0.96875;
}
*/
float fbm( vec2 p ){
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);

	mat2 rot = mat2(
		vec2(cos(0.5), -sin(0.5)),
		vec2(sin(0.5), cos(0.5))
	);
	for (int i = 0; i < NUM_OCTAVES; ++i){
		v+= a * noise(p);
		p = rot * p * 2.03 + shift;
		a *=0.5;
	}
	return v;
}


float warp(vec2 p, float strength) {
    return fbm(p) * strength;
}

float triple_warp(vec2 p) {
    float w1 = warp(p, 1.0);
    float w2 = warp(p + w1, 1.0);
    float w3 = warp(p + w2, 1.0);
    return fbm(p + w3);
}

void fragment() {
	vec2 st = SCREEN_UV * 5.0;
	vec2 p_st = floor(st * pixelation) / pixelation;

	vec2 b_st = pixelated ? p_st : st;

	//b_st += b_st * abs(sin( iTime *0.1)*3.0); //translated to GLSL from GLES

	vec3 color = vec3(0.0);

	vec2 q = vec2(0.0);
	q.x = fbm( b_st + 0.00 * iTime);
	q.y = fbm( b_st + vec2(1.0));

	vec2 r = vec2(0.0);
	r.x = fbm( b_st + 1.0*q + vec2(1.7,9.2) + 0.15 * iTime);
	r.y = fbm( b_st + 1.0*q + vec2(8.3,2.8)+ 0.126 * iTime);
	

	float f = triple_warp(b_st+r);

	vec2 c_st = SCREEN_UV * 2.0 - 1.0;
	c_st.y -= offsety / st.y;
	c_st.x -= offsetx / st.x;

	float d = length(c_st);
	float v = smoothstep(0.1, 0.7, length(c_st + r * 1.));
	float cd = 1.0 - v;

	f*= v;

	color = mix(
			vec3(colA),
			vec3(colB),
			clamp((f*f)*4.0,0.0,1.0)
		);
	color = mix(color,
			vec3(colB),
			clamp(length(q),0.0,1.0)
	);
	color = mix(color,
			vec3(colC),
			clamp(length(r.x),0.0,1.0)
	);

	COLOR = vec4((f*f*f+1.0*f*f+0.5*f)*color,1.);
}
