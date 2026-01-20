shader_type spatial;
group_uniforms SpriteSheet;
uniform sampler2D SpriteSheet: source_color, filter_nearest;
uniform float SpriteSheetWidth = 4.0;
uniform float SpriteSheetHeight = 4.0;

void fragment() {
	// Called for every pixel the material is visible on.
}

