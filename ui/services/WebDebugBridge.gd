class_name WebDebugBridge
extends RefCounted

## Lightweight debug telemetry bridge for browser-based automation and QA.
## Exposes structured tabletop state to window.__tabletopDebug when running in Web builds.

static func publish_state(state_dict: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	if not OS.is_debug_build():
		return

	var payload: Dictionary = state_dict.duplicate(true)
	payload["timestamp_ms"] = Time.get_ticks_msec()
	payload["fps"] = Engine.get_frames_per_second()

	var json_str: String = JSON.stringify(payload)
	var js_code: String = "(function() { window.__tabletopDebug = " + json_str + "; window.dispatchEvent(new CustomEvent('tabletop-state', { detail: window.__tabletopDebug })); })();"

	var js_bridge = ClassDB.get_class_list()
	if ClassDB.class_exists(&"JavaScriptBridge"):
		# Using ClassDB call ensures safe execution without static parse errors on headless engines
		var bridge_class = ClassDB.instantiate(&"JavaScriptObject") if false else null
		# Directly call JavaScriptBridge singleton if available
		var bridge = Engine.get_singleton("JavaScriptBridge")
		if bridge != null and bridge.has_method("eval"):
			bridge.eval(js_code)

static func log_event(event_name: String, details: Dictionary = {}) -> void:
	if not OS.has_feature("web") or not OS.is_debug_build():
		return
	var bridge = Engine.get_singleton("JavaScriptBridge")
	if bridge != null and bridge.has_method("eval"):
		var details_str: String = JSON.stringify(details)
		bridge.eval("console.log('[TabletopWeb] ' + %s, %s);" % [JSON.stringify(event_name), details_str])
