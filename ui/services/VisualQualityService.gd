extends RefCounted
class_name VisualQualityService

const PROFILE_LOW: String = "low"
const PROFILE_MEDIUM: String = "medium"
const PROFILE_HIGH: String = "high"
const PROFILE_ULTRA: String = "ultra"

const AA_OFF: String = "off"
const AA_FXAA: String = "fxaa"
const AA_TAA: String = "taa"
const AA_FSR2: String = "fsr2" # Optional. Falls back to FXAA when unavailable.

const PROFILE_SET: PackedStringArray = [
	PROFILE_LOW,
	PROFILE_MEDIUM,
	PROFILE_HIGH,
	PROFILE_ULTRA,
]

const AA_SET: PackedStringArray = [
	AA_OFF,
	AA_FXAA,
	AA_TAA,
	AA_FSR2,
]


static func default_profile_for_platform() -> String:
	return PROFILE_MEDIUM if OS.get_name() == "Android" else PROFILE_HIGH


static func default_settings() -> Dictionary:
	var profile: String = default_profile_for_platform()
	return _defaults_for_profile(profile)


static func defaults_for_profile(profile: String) -> Dictionary:
	return _defaults_for_profile(profile)


static func sanitize(raw: Dictionary) -> Dictionary:
	var profile: String = str(raw.get("graphics_profile", default_profile_for_platform())).to_lower()
	if not PROFILE_SET.has(profile):
		profile = default_profile_for_platform()
	var out: Dictionary = _defaults_for_profile(profile)
	out["graphics_profile"] = profile

	var aa_mode: String = str(raw.get("aa_mode", _default_aa_for_profile(profile))).to_lower()
	if not AA_SET.has(aa_mode):
		aa_mode = _default_aa_for_profile(profile)
	out["aa_mode"] = aa_mode

	var ssao_quality: int = clampi(int(raw.get("ssao_quality", _default_ssao_for_profile(profile))), 0, 3)
	out["ssao_quality"] = ssao_quality
	out["ssr_enabled"] = bool(raw.get("ssr_enabled", profile == PROFILE_HIGH or profile == PROFILE_ULTRA))
	out["resolution_scale"] = clampf(float(raw.get("resolution_scale", _default_resolution_scale_for_profile(profile))), 0.55, 1.20)
	out["postfx_strength"] = clampf(float(raw.get("postfx_strength", _default_postfx_for_profile(profile))), 0.0, 1.0)
	out["shadow_quality"] = clampi(int(raw.get("shadow_quality", _default_shadow_quality_for_profile(profile))), 0, 3)
	if OS.get_name() == "Android" and str(raw.get("presentation_mode", "2d")).to_lower() == "3d":
		# Keep Android 3D opt-in conservative to reduce thermal and stability risk on mid-tier devices.
		out["aa_mode"] = AA_FXAA
		out["ssao_quality"] = mini(int(out["ssao_quality"]), 1)
		out["ssr_enabled"] = false
		out["resolution_scale"] = minf(float(out["resolution_scale"]), 0.90)
		out["postfx_strength"] = minf(float(out["postfx_strength"]), 0.45)
		out["shadow_quality"] = mini(int(out["shadow_quality"]), 1)
	return out


static func _defaults_for_profile(profile: String) -> Dictionary:
	var p: String = profile.to_lower()
	if not PROFILE_SET.has(p):
		p = default_profile_for_platform()
	return {
		"graphics_profile": p,
		"aa_mode": _default_aa_for_profile(p),
		"ssao_quality": _default_ssao_for_profile(p),
		"ssr_enabled": p == PROFILE_HIGH or p == PROFILE_ULTRA,
		"resolution_scale": _default_resolution_scale_for_profile(p),
		"postfx_strength": _default_postfx_for_profile(p),
		"shadow_quality": _default_shadow_quality_for_profile(p),
	}


static func apply_to_viewport(viewport: Viewport, settings: Dictionary) -> void:
	if viewport == null:
		return
	var s: Dictionary = sanitize(settings)
	var profile: String = str(s["graphics_profile"])
	var aa_mode: String = str(s["aa_mode"])

	var msaa: int = Viewport.MSAA_DISABLED
	match profile:
		PROFILE_MEDIUM, PROFILE_HIGH:
			msaa = Viewport.MSAA_2X
		PROFILE_ULTRA:
			msaa = Viewport.MSAA_4X
		_:
			msaa = Viewport.MSAA_DISABLED
	viewport.set("msaa_3d", msaa)

	var screen_space_aa: int = Viewport.SCREEN_SPACE_AA_DISABLED
	var taa_enabled: bool = false
	match aa_mode:
		AA_OFF:
			screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		AA_TAA:
			taa_enabled = true
			screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		AA_FSR2:
			# Optional path. Keep deterministic fallback to FXAA.
			screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		_:
			screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	viewport.set("screen_space_aa", screen_space_aa)
	viewport.set("use_taa", taa_enabled)
	viewport.set("scaling_3d_scale", float(s["resolution_scale"]))


static func apply_to_environment(env: Environment, settings: Dictionary) -> void:
	if env == null:
		return
	var s: Dictionary = sanitize(settings)
	var profile: String = str(s["graphics_profile"])
	var ssao_quality: int = int(s["ssao_quality"])
	var postfx_strength: float = float(s["postfx_strength"])
	var ssr_enabled: bool = bool(s["ssr_enabled"])

	env.set("ssao_enabled", ssao_quality > 0)
	env.set("ssao_radius", lerpf(0.35, 1.10, float(ssao_quality) / 3.0))
	env.set("ssao_intensity", lerpf(0.18, 0.48, float(ssao_quality) / 3.0))
	env.set("ssao_power", 1.00)
	env.set("ssao_detail", 0.28)
	env.set("ssao_sharpness", 0.72)

	env.set("ssil_enabled", ssao_quality >= 2 and profile != PROFILE_LOW)
	env.set("ssil_radius", 0.65)
	env.set("ssil_intensity", lerpf(0.06, 0.18, postfx_strength))
	env.set("ssil_sharpness", 0.88)

	env.set("ssr_enabled", ssr_enabled and profile != PROFILE_LOW)
	env.set("ssr_max_steps", 56 if profile == PROFILE_ULTRA else 32)
	env.set("ssr_fade_in", 0.14)
	env.set("ssr_fade_out", 1.55)
	env.set("ssr_depth_tolerance", 0.24)

	var glow_enabled: bool = postfx_strength > 0.45 and (profile == PROFILE_HIGH or profile == PROFILE_ULTRA)
	env.set("glow_enabled", glow_enabled)
	env.set("glow_levels/2", glow_enabled)
	env.set("glow_levels/3", glow_enabled and profile == PROFILE_ULTRA)
	env.set("glow_levels/4", glow_enabled and profile == PROFILE_ULTRA)
	env.set("glow_intensity", lerpf(0.32, 0.52, postfx_strength))
	env.set("glow_strength", lerpf(0.30, 0.52, postfx_strength))
	env.set("glow_bloom", lerpf(0.01, 0.07, postfx_strength))

	env.set("dof_blur_near_enabled", false)
	env.set("dof_blur_far_enabled", false)

	env.set("adjustment_enabled", true)
	env.set("adjustment_brightness", lerpf(1.03, 1.10, postfx_strength))
	env.set("adjustment_contrast", lerpf(0.99, 1.02, postfx_strength))
	env.set("adjustment_saturation", lerpf(0.98, 1.02, postfx_strength))


static func apply_to_lights(key_light: Light3D, rim_light: Light3D, fill_light: Light3D, settings: Dictionary) -> void:
	var s: Dictionary = sanitize(settings)
	var profile: String = str(s["graphics_profile"])
	var postfx: float = float(s["postfx_strength"])
	var shadow_quality: int = int(s["shadow_quality"])
	var key_energy: float = 1.20
	var rim_energy: float = 0.52
	var fill_energy: float = 0.34
	match profile:
		PROFILE_LOW:
			key_energy = 1.08
			rim_energy = 0.40
			fill_energy = 0.26
		PROFILE_MEDIUM:
			key_energy = 1.24
			rim_energy = 0.60
			fill_energy = 0.40
		PROFILE_HIGH:
			key_energy = 1.34
			rim_energy = 0.68
			fill_energy = 0.41
		PROFILE_ULTRA:
			key_energy = 1.42
			rim_energy = 0.76
			fill_energy = 0.47
	key_energy += postfx * 0.05
	rim_energy += postfx * 0.03
	fill_energy += postfx * 0.03
	if key_light != null:
		key_light.light_energy = key_energy
		key_light.shadow_enabled = shadow_quality > 0 and profile != PROFILE_LOW
		key_light.shadow_blur = lerpf(3.0, 1.2, float(shadow_quality) / 3.0) if shadow_quality > 0 else 0.0
		var key_dir: DirectionalLight3D = key_light as DirectionalLight3D
		if key_dir != null:
			key_dir.directional_shadow_max_distance = lerpf(6.0, 20.0, float(shadow_quality) / 3.0) if shadow_quality > 0 else 2.5
			key_dir.directional_shadow_split_1 = 0.12
			key_dir.directional_shadow_split_2 = 0.28
			key_dir.directional_shadow_split_3 = 0.55
			match shadow_quality:
				3:
					key_dir.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
				2:
					key_dir.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				_:
					key_dir.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	if rim_light != null:
		rim_light.light_energy = rim_energy
	if fill_light != null:
		fill_light.light_energy = fill_energy


static func _default_aa_for_profile(profile: String) -> String:
	match profile:
		PROFILE_LOW:
			return AA_OFF
		PROFILE_ULTRA:
			return AA_TAA
		_:
			return AA_FXAA


static func _default_ssao_for_profile(profile: String) -> int:
	match profile:
		PROFILE_LOW:
			return 0
		PROFILE_MEDIUM:
			return 1
		PROFILE_HIGH:
			return 2
		PROFILE_ULTRA:
			return 3
		_:
			return 2


static func _default_resolution_scale_for_profile(profile: String) -> float:
	match profile:
		PROFILE_LOW:
			return 0.75
		PROFILE_MEDIUM:
			return 0.90
		PROFILE_HIGH:
			return 1.00
		PROFILE_ULTRA:
			return 1.05
		_:
			return 1.0


static func _default_postfx_for_profile(profile: String) -> float:
	match profile:
		PROFILE_LOW:
			return 0.15
		PROFILE_MEDIUM:
			return 0.30
		PROFILE_HIGH:
			return 0.50
		PROFILE_ULTRA:
			return 0.68
		_:
			return 0.50


static func _default_shadow_quality_for_profile(profile: String) -> int:
	match profile:
		PROFILE_LOW:
			return 0
		PROFILE_MEDIUM:
			return 1
		PROFILE_HIGH:
			return 2
		PROFILE_ULTRA:
			return 3
		_:
			return 2
