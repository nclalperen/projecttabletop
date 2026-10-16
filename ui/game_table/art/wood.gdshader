shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

uniform vec4 wood_color : source_color = vec4(0.24, 0.13, 0.075, 1.0);
uniform vec4 wood_highlight : source_color = vec4(0.36, 0.20, 0.11, 1.0);
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = local_position;
	// Organic wood grain flowing along the width of table and rack
	float wave = sin(p.z * 18.0) * 0.015 + sin(p.y * 32.0) * 0.008;
	float coord = (p.z + wave) * 620.0;
	float fine_grain = sin(coord) * 0.06;
	float broad_grain = sin((p.z + wave * 0.5) * 85.0) * 0.12;
	
	float t = clamp(0.5 + fine_grain + broad_grain, 0.0, 1.0);
	vec3 col = mix(wood_color.rgb, wood_highlight.rgb, t);
	
	// Subtle varnished sheen
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	
	ALBEDO = col;
	ROUGHNESS = mix(0.34, 0.24, fresnel);
	SPECULAR = 0.38;
}
