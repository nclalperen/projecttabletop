shader_type spatial;
render_mode specular_schlick_ggx;

uniform vec4 felt_color : source_color = vec4(0.045, 0.205, 0.225, 1.0);
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 thread = local_position.xz * 2100.0;
	float weave = sin(thread.x * 6.28318) * sin(thread.y * 6.28318);
	float grain = fract(sin(dot(floor(thread * 2.0), vec2(127.1, 311.7))) * 43758.5453);
	ALBEDO = felt_color.rgb * (0.96 + grain * 0.065 + weave * 0.018);
	ROUGHNESS = 0.94;
	SPECULAR = 0.16;
}
