shader_type canvas_item;

// Frosted glass for StyleBoxFlat panels. COLOR carries the stylebox color:
// translucent fill pixels become blurred backdrop tinted by the fill, while
// opaque border pixels are kept as-is so chunky outlines stay crisp.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 6.0) = 3.2;
uniform float border_alpha_threshold : hint_range(0.0, 1.0) = 0.92;

void fragment() {
	vec4 src = COLOR;
	vec3 blurred = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb;
	float is_border = step(border_alpha_threshold, src.a);
	vec3 glass = mix(blurred, src.rgb, src.a);
	COLOR = vec4(mix(glass, src.rgb, is_border), 1.0);
}
