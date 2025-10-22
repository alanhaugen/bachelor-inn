shader_type canvas_item;

vec2 rotate2D(vec2 _st, float _angle)
{
    _st -= 0.5;
    _st =  mat2(vec2(cos(_angle),-sin(_angle)),
	vec2(sin(_angle),cos(_angle))) * _st;
    _st += 0.5;
    return _st;
}

vec2 tile(vec2 _st, float _zoom){
    _st *= _zoom;
    return fract(_st);
}

float box(vec2 _st, vec2 _size, float _smoothEdges){
    _size = vec2(0.5)-_size*0.5;
    vec2 aa = vec2(_smoothEdges*0.5);
    vec2 uv = smoothstep(_size,_size+aa,_st);
    uv *= smoothstep(_size,_size+aa,vec2(1.0)-_st);
    return uv.x*uv.y;
}

void vertex()
{
	// Called for every vertex the material is visible on.
}

void fragment()
{
	vec2 st = FRAGCOORD.xy / 600.0f;///u_resolution.xy;
    vec3 color = vec3(0.0);

    // Divide the space in 4
    st = tile(st,7.);

    // Use a matrix to rotate the space 45 degrees
    st = rotate2D(st,PI*0.25 * cos(TIME * 3.0f));

    // Draw a square
    color = vec3(box(st,vec2(0.7) * cos(TIME * 2.0f),0.01));
    // color = vec3(st,0.0);

	if (color.x > 0.1)
	{
		COLOR = vec4(0,0,0,0.0);
	}
	else
	{
    	COLOR = vec4(color,0.4);
	}
}
