shader_type canvas_item;

/* ============================================================
   Eye controls
   ============================================================ */
uniform float eye_open : hint_range(0.0, 1.0) = 1.0;
uniform float pupil_size : hint_range(0.0, 1.0) = 0.25;
uniform float eye_size : hint_range(0.0, 1.0) = 1.0;

/* ============================================================
   Noise controls (UNCHANGED)
   ============================================================ */
uniform vec3 colA : source_color = vec3(0.1, 0.1, 0.1);
uniform vec3 colB : source_color = vec3(0.1, 0.1, 0.1);
uniform vec3 colC : source_color = vec3(0.1, 0.1, 0.1);
uniform float pixelation = 8.0;
uniform bool pixelated = true;
uniform float offsety = 0.0;
uniform float offsetx = 0.0;
uniform float speed = 1.0;

/* ============================================================
   Shared random
   ============================================================ */
float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

/* ============================================================
   Voronoi (UNCHANGED)
   ============================================================ */
vec3 voronoi(vec2 x) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    float md = 8.0;
    vec2 mr = vec2(0.0);

    for (int j = -1; j <= 1; j++) {
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

/* ============================================================
   Eye shapes (UNCHANGED)
   ============================================================ */
float eyelid_shape(vec2 uv, float open_amount, float size) {
    float y = uv.y;
    float x = uv.x;

    y *= open_amount;
    y = abs(y) * -1.0;

    x = (x * 2.29);
    x = x * x;

    float shape = y - x + 1.0 + sin(TIME) / 10.0;
    return smoothstep(size - 0.01, size, shape);
}

float pupil(vec2 uv, float size) {
    float p = length(uv);
    float shape = size + sin(TIME) / 10.0;
    return smoothstep(shape - 0.11, shape - 0.1, p);
}

/* ============================================================
   Noise (UNCHANGED)
   ============================================================ */
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x)
         + (c - a) * u.y * (1.0 - u.x)
         + (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5
#define iTime (TIME * speed)

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);

    mat2 rot = mat2(
        vec2(cos(0.5), -sin(0.5)),
        vec2(sin(0.5), cos(0.5))
    );

    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(p);
        p = rot * p * 2.0 + shift;
        a *= 0.5;
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

/* ============================================================
   Fragment
   ============================================================ */
void fragment() {

    /* ---------- Background noise (UNCHANGED) ---------- */
    vec2 st = SCREEN_UV * 5.0;
    vec2 p_st = floor(st * pixelation) / pixelation;
    vec2 b_st = pixelated ? p_st : st;

    vec2 q;
    q.x = fbm(b_st + 0.00 * iTime);
    q.y = fbm(b_st + vec2(1.0));

    vec2 r;
    r.x = fbm(b_st + q + vec2(1.7, 9.2) + 0.15 * iTime);
    r.y = fbm(b_st + q + vec2(8.3, 2.8) + 0.126 * iTime);

    float f = triple_warp(b_st * r);

    vec2 c_st = SCREEN_UV * 2.0 - 1.0;
    c_st.y -= offsety / st.y;
    c_st.x -= offsetx / st.x;

    float v = smoothstep(0.1, 0.7, length(c_st + r));
    f *= v;

    vec3 bg_color = mix(colA, colB, clamp(f * f * 4.0, 0.0, 1.0));
    bg_color = mix(bg_color, colC, clamp(length(r), 0.0, 1.0));
    bg_color *= (f * f * f + f * f + 0.5 * f);

    /* ---------- Screen‑space pixel‑locked eye ---------- */
    vec2 screen_px = floor(SCREEN_UV * pixelation) / pixelation;
    vec2 eye_uv = (screen_px - SCREEN_UV) + UV;

    eye_uv = voronoi(eye_uv * 5.0).yz;

    float eyelid = eyelid_shape(eye_uv, eye_open, eye_size);
    float pupil_out = pupil(eye_uv, pupil_size);
    float pupil_in = 1.0 - pupil_out;

    /* ---------- Compose ---------- */
    vec3 color = bg_color;
    color = mix(color, vec3(1.0), eyelid);
    color = mix(color, vec3(0.0), pupil_in * eyelid);

    COLOR = vec4(color, 1.0);
}
