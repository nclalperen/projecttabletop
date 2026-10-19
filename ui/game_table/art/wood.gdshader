shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

uniform vec4 wood_color : source_color = vec4(0.24, 0.13, 0.075, 1.0);
uniform vec4 wood_highlight : source_color = vec4(0.36, 0.20, 0.11, 1.0);
uniform float grain_scale = 180.0;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = local_position;
	// Off-center plank cut from tree trunk: avoids concentric bullseye on end caps
	// and produces natural linear grain along X.
	float ring_dist = length(vec2((p.y + 0.22) * 1.4, (p.z - 0.18) * 1.6));
	float ring_noise = sin(p.x * 16.0) * 0.005 + sin(p.x * 4.5) * 0.010;
	float ring_coord = (ring_dist + ring_noise) * grain_scale;
	
	float rings = sin(ring_coord) * 0.20;
	float micro_grain = sin(ring_coord * 3.5) * 0.06;
	float fibers = sin((p.x + p.z * 0.15) * 480.0) * 0.04;
	
	float t = clamp(0.5 + rings + micro_grain + fibers, 0.0, 1.0);
	vec3 col = mix(wood_color.rgb, wood_highlight.rgb, t);
	
	// Natural wood pores / dark grain lines
	float pore_line = pow(clamp(sin(ring_coord * 2.0), 0.0, 1.0), 8.0) * 0.18;
	col -= col * pore_line;
	
	// Subtle satin lacquer sheen with Fresnel specular response
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.5);
	
	ALBEDO = col;
	ROUGHNESS = mix(0.36, 0.22, fresnel);
	SPECULAR = 0.40;
}
