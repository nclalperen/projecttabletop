shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

// Authentic Luxury Game Salon Dark Hardwood Parquet Floor
uniform vec4 floor_wood_base : source_color = vec4(0.022, 0.012, 0.007, 1.0); // Rich dark aged walnut
uniform vec4 floor_wood_rich : source_color = vec4(0.045, 0.026, 0.015, 1.0); // Warm amber-mahogany plank
uniform vec4 floor_seam : source_color = vec4(0.005, 0.003, 0.002, 1.0); // Dark recessed plank bevel groove

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// World-space coordinates in metres
	vec2 p = world_position.xz;
	
	// Plank dimensions: width 0.10m, length 0.50m
	float plank_w = 0.10;
	float plank_l = 0.50;
	
	// Staggered plank grid
	float row_idx = floor(p.x / plank_w);
	float stagger = mod(row_idx, 2.0) * (plank_l * 0.5);
	float col_idx = floor((p.y + stagger) / plank_l);
	
	// Local UV within plank [0, 1]
	vec2 local_uv = vec2(
		fract(p.x / plank_w),
		fract((p.y + stagger) / plank_l)
	);
	
	// Pseudo-random seed per individual plank
	vec2 plank_seed = vec2(row_idx, col_idx);
	float plank_rand = fract(sin(dot(plank_seed, vec2(12.9898, 78.233))) * 43758.5453);
	float plank_rand2 = fract(sin(dot(plank_seed, vec2(93.9898, 67.345))) * 24634.6345);
	
	// 1. Plank bevel seam (dark groove between planks)
	float seam_dist_x = min(local_uv.x, 1.0 - local_uv.x) * plank_w;
	float seam_dist_y = min(local_uv.y, 1.0 - local_uv.y) * plank_l;
	float min_dist = min(seam_dist_x, seam_dist_y);
	float seam_factor = smoothstep(0.0025, 0.0055, min_dist);
	
	// 2. Wood grain running along plank length (Y axis)
	float grain_coord = p.y * 320.0 + sin(p.x * 40.0) * 0.8;
	float fine_grain = sin(grain_coord) * 0.08;
	float broad_grain = sin(p.y * 45.0 + plank_rand * 6.28) * 0.12;
	
	// 3. Plank color variation
	vec3 plank_color = mix(floor_wood_base.rgb, floor_wood_rich.rgb, plank_rand * 0.75 + 0.15);
	vec3 wood_col = plank_color * (0.92 + fine_grain + broad_grain);
	
	// Blend with seam groove
	vec3 final_col = mix(floor_seam.rgb, wood_col, seam_factor);
	
	// 4. Subtle distance vignette darkening away from table center
	float dist_from_center = length(world_position.xz);
	float vignette = smoothstep(2.4, 0.7, dist_from_center);
	final_col *= mix(0.45, 1.0, vignette);
	
	// 5. Satin varnish reflection
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 3.5);
	
	ALBEDO = final_col;
	ROUGHNESS = mix(0.48, 0.32, fresnel) * (1.0 + (1.0 - seam_factor) * 0.4);
	SPECULAR = 0.22;
}
