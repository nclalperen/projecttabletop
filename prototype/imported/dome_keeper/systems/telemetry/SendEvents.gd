extends HTTPRequest

signal completed_send
signal login_needed
signal failed_send(code, reason)

const BACKEND_SCRIPT: Script = preload("res://prototype/imported/dome_keeper/systems/telemetry/Backend.gd")

var file_counter: int = 1
var backend = BACKEND_SCRIPT.new()


func _ready() -> void:
	request_completed.connect(_on_request_completed)


func configure_backend(url: String, session_id: String, enabled: bool = true) -> void:
	backend.configure(url, session_id, enabled)


func do(events: Array) -> Dictionary:
	if not backend.can_send():
		return {"ok": false, "code": "backend_disabled", "reason": "Telemetry backend disabled."}
	var encoded_events: Array = []
	for e in events:
		if e != null and e.has_method("as_dict"):
			encoded_events.append(e.call("as_dict"))
		elif typeof(e) == TYPE_DICTIONARY:
			encoded_events.append((e as Dictionary).duplicate(true))
	var out_json: String = JSON.stringify(encoded_events)
	var body := Marshalls.utf8_to_base64(out_json)
	var headers := PackedStringArray(["Content-Type: text/plain"])
	var folder: String = "/sessions"
	var url: String = "%s/files/binary%s/%s/events-%d.txt" % [
		backend.base_url,
		folder,
		backend.session_id.uri_encode(),
		file_counter
	]
	file_counter += 1
	var err: int = request(url, headers, HTTPClient.METHOD_PUT, body)
	return {"ok": err == OK, "code": err}


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		var txt: String = body.get_string_from_utf8()
		emit_signal("failed_send", response_code, txt)
		if response_code == 401:
			emit_signal("login_needed")
		return
	emit_signal("completed_send")
