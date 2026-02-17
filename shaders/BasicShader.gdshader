shader_type spatial;

uniform sampler2D diffuse_tex : source_color, filter_nearest;
uniform vec4 colorTint: source_color = vec4(1.0);
uniform float clippingMask: hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 d = texture(diffuse_tex, UV);
	if (d.a < clippingMask) discard;

	d *= colorTint;
	ALBEDO = d.rgb;
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
