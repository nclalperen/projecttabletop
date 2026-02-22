extends RefCounted
class_name Protocol

const PROTOCOL_VERSION: int = 1

const C_HELLO: String = "HELLO"
const C_ACTION_REQUEST: String = "ACTION_REQUEST"
const C_PING: String = "PING"
const C_REJOIN_REQUEST: String = "REJOIN_REQUEST"
const C_REQUEST_NEW_ROUND: String = "REQUEST_NEW_ROUND"

const S_WELCOME: String = "WELCOME"
const S_ACTION_RESULT: String = "ACTION_RESULT"
const S_STATE_SNAPSHOT: String = "STATE_SNAPSHOT"
const S_PONG: String = "PONG"
const S_REJOIN_SNAPSHOT: String = "REJOIN_SNAPSHOT"
const S_MATCH_EVENT: String = "MATCH_EVENT"

static func wrap(message_type: String, payload: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {
		"protocol": PROTOCOL_VERSION,
		"type": String(message_type),
	}
	for k in payload.keys():
		out[k] = payload[k]
	return out

static func validate_client_message(msg: Dictionary) -> Dictionary:
	var base: Dictionary = _validate_base(msg)
	if not bool(base.get("ok", false)):
		return base
	var t: String = String(msg.get("type", ""))
	match t:
		C_HELLO:
			return _require_keys(msg, ["match_id", "puid", "client_version"]) 
		C_ACTION_REQUEST:
			var r: Dictionary = _require_keys(msg, ["seq", "turn_id", "action"])
			if not bool(r.get("ok", false)):
				return r
			if typeof(msg.get("action", null)) != TYPE_DICTIONARY:
				return _fail("invalid_action", "action must be a dictionary")
			return _ok()
		C_PING:
			return _require_keys(msg, ["t_client_ms"])
		C_REJOIN_REQUEST:
			return _require_keys(msg, ["match_id", "last_turn_id_seen"])
		C_REQUEST_NEW_ROUND:
			return _require_keys(msg, ["match_id"])
		_:
			return _fail("unknown_type", "Unknown client message type")

static func validate_host_message(msg: Dictionary) -> Dictionary:
	var base: Dictionary = _validate_base(msg)
	if not bool(base.get("ok", false)):
		return base
	var t: String = String(msg.get("type", ""))
	match t:
		S_WELCOME:
			return _require_keys(msg, ["match_id", "host_puid", "ruleset_id", "seats", "match_seed"])
		S_ACTION_RESULT:
			return _require_keys(msg, ["seq", "ok", "code", "reason"]) 
		S_STATE_SNAPSHOT:
			return _require_keys(msg, ["turn_id", "state"])
		S_PONG:
			return _require_keys(msg, ["t_client_ms", "t_host_ms"])
		S_REJOIN_SNAPSHOT:
			return _require_keys(msg, ["turn_id", "state"])
		S_MATCH_EVENT:
			return _require_keys(msg, ["event", "payload"])
		_:
			return _fail("unknown_type", "Unknown host message type")

static func _validate_base(msg: Dictionary) -> Dictionary:
	if typeof(msg) != TYPE_DICTIONARY:
		return _fail("invalid_message", "message must be a dictionary")
	if int(msg.get("protocol", -1)) != PROTOCOL_VERSION:
		return _fail("protocol_mismatch", "protocol version mismatch")
	if String(msg.get("type", "")) == "":
		return _fail("missing_type", "missing type")
	return _ok()

static func _require_keys(msg: Dictionary, keys: Array) -> Dictionary:
	for k in keys:
		if not msg.has(k):
			return _fail("missing_field", "missing field: %s" % String(k))
	return _ok()

static func _ok() -> Dictionary:
	return {"ok": true, "code": "ok", "reason": ""}

static func _fail(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason}
