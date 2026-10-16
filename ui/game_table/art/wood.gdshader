shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 wood_color : source_color = vec4(0.29, 0.125, 0.062, 1.0);
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = local_position;
	float waviness = sin(p.x * 22.0) * 0.0008 + sin(p.x * 57.0) * 0.0004;
	float grain = sin((p.z + waviness) * 1400.0) * 0.045;
	float wide_grain = sin((p.z + waviness) * 190.0) * 0.075;
	ALBEDO = wood_color.rgb * (1.0 + grain + wide_grain);
	ROUGHNESS = 0.43;
	SPECULAR = 0.32;
}
