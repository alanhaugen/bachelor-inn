shader_type canvas_item;

uniform float eye_open : hint_range(0.0, 1.0) = 1.0;
uniform vec3 eye_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float pupil_size : hint_range(0.0, 1.0) = 1.0;
uniform float eye_size : hint_range(0.0, 1.0) = 1.0;

// --- Random ---
float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

struct VoronoiData {
	float f1;
	vec2 nearest_vec;
	vec2 cell_id;
};

VoronoiData voronoi(vec2 x) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	
	float md = 8.0;
	vec2 mr = vec2(0.0);
	vec2 cid = vec2(0.0);
	
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; 1 <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = vec2(rand(n + g), rand(n + g + 1.0));
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
				cid = n + g;
			}
		}
	}
	VoronoiData outd;
	outd.f1 = sqrt(md);
	outd.nearest_vec = mr;
	outd.cell_id = cid;
	return outd;
}

/*
// --- Voronoi ---
vec3 voronoi(vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    float md = 8.0;
    vec2 mr = vec2(0.0);

    
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(rand(n + g), rand(n + g + 1.0));
            vec2 r = g + o - f;
            float d = dot(r, r);

            if (d < md) {
                md = d;
                mr = r;
            }
        }
    }

    return vec3(sqrt(md), mr);
}
*/

float eyelid_shape(vec2 uv, float open_amount, float size) {
	float y = uv.y;
	float x = uv.x;
	y *= open_amount;
	y = abs(y) * -1.0;
	x = (x * 2.29);
	x = x * x;
	float shape = y - x + sin(TIME)/10.0;
	return smoothstep(size-0.01, size, shape);
}

float pupil(vec2 uv, float size){
	float p = length(uv);
	return smoothstep(size-0.01, size, p);
}

void fragment() {
	VoronoiData v = voronoi(UV * 5.0);
	float seg_rand = rand(v.cell_id);
	float offset = (seg_rand - 0.5) * 0.3;
	float local = clamp(eye_open + offset, 0.0, 1.0);
	
	vec2 uv = v.nearest_vec;
	float mask = eyelid_shape(uv, local, eye_size) * pupil(uv, pupil_size);
	COLOR = vec4(seg_rand,0 ,0 , 1.0);
}
