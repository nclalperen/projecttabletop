shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

uniform vec4 felt_color : source_color = vec4(0.040, 0.220, 0.110, 1.0);
uniform vec4 felt_sheen : source_color = vec4(0.080, 0.360, 0.180, 1.0);
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 thread = local_position.xz * 2800.0;
	float weave = sin(thread.x * 6.28318) * sin(thread.y * 6.28318);
	float grain = fract(sin(dot(floor(thread * 1.5), vec2(127.1, 311.7))) * 43758.5453);
	
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 base_felt = mix(felt_color.rgb, felt_sheen.rgb, fresnel * 0.45);
	
	ALBEDO = base_felt * (0.97 + grain * 0.05 + weave * 0.02);
	ROUGHNESS = 0.92;
	SPECULAR = 0.12;
}
