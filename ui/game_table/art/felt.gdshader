shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

// Authentic English tournament gaming baize / Worsted wool cloth
uniform vec4 felt_color : source_color = vec4(0.012, 0.086, 0.048, 1.0); // Rich deep emerald baize
uniform vec4 felt_sheen : source_color = vec4(0.034, 0.205, 0.120, 1.0); // Velvet nap directional sheen
uniform vec4 felt_shadow : source_color = vec4(0.006, 0.044, 0.024, 1.0); // Micro-occlusion under fibers

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = local_position;
	
	// 1. Diagonal twill weave (380 cycles/m - visible fiber structure without subpixel moiré)
	vec2 twill_uv = vec2(p.x + p.z, p.x - p.z) * 360.0;
	float twill = (sin(twill_uv.x * 3.14159) * sin(twill_uv.y * 3.14159)) * 0.035;
	
	// 2. Micro wool fiber nap noise
	float fiber = fract(sin(dot(floor(p.xz * 720.0), vec2(12.9898, 78.233))) * 43758.5453) * 0.045;
	
	// 3. Subtle macro cloth tension variation across the table
	float tension = sin(p.x * 6.0) * cos(p.z * 6.0) * 0.025;
	
	// 4. Soft velvet / cloth rim fuzz (velveteen retro-reflection)
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - ndotv, 2.5);
	
	// Blend base emerald cloth with soft nap sheen
	vec3 col = mix(felt_color.rgb, felt_sheen.rgb, rim * 0.65 + twill + tension);
	col = mix(col, felt_shadow.rgb, fiber * 0.5);
	
	// Micro normal variation to catch directional light on wool fibers
	vec3 perturbed_normal = normalize(NORMAL + vec3(twill * 0.12, 0.0, twill * 0.12));
	
	ALBEDO = col;
	NORMAL = perturbed_normal;
	ROUGHNESS = 0.94;
	SPECULAR = 0.06;
}
