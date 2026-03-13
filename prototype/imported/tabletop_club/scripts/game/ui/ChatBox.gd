extends VBoxContainer

signal message_submitted(message)

const NUM_CHARS_BEFORE_TIMEOUT: int = 1000
const TIMEOUT_WAIT_TIME: float = 1.0

var _num_chars_recent: int = 0
var _time_since_last_msg: float = 0.0

@onready var _chat_text: RichTextLabel = _ensure_chat_text()
@onready var _message_edit: LineEdit = _ensure_message_edit()


func _ready() -> void:
	_message_edit.text_submitted.connect(_on_message_submitted)


func _process(delta: float) -> void:
	_time_since_last_msg += delta


func add_raw_message(raw_message: String, stdout: bool = true) -> void:
	if _time_since_last_msg > TIMEOUT_WAIT_TIME:
		if _num_chars_recent >= NUM_CHARS_BEFORE_TIMEOUT:
			_chat_text.clear()
		_num_chars_recent = 0
	if _num_chars_recent >= NUM_CHARS_BEFORE_TIMEOUT:
		return
	_num_chars_recent += raw_message.length()
	_time_since_last_msg = 0.0
	_chat_text.append_text("\n%s" % raw_message)
	if stdout:
		print(raw_message)


func clear_all() -> void:
	_chat_text.clear()


func prepare_send_message() -> void:
	var msg: String = _message_edit.text.strip_edges()
	_message_edit.clear()
	if msg == "":
		return
	msg = msg.strip_escapes().replace("[", "[ ")
	emit_signal("message_submitted", msg)
	add_raw_message(msg, false)


@rpc("any_peer", "call_local")
func receive_message(_sender_id: int, message: String) -> void:
	var safe: String = message.strip_edges().strip_escapes().replace("[", "[ ")
	if safe != "":
		add_raw_message(safe, false)


func _on_message_submitted(_new_text: String) -> void:
	prepare_send_message()


func _ensure_chat_text() -> RichTextLabel:
	var chat := get_node_or_null("ChatText") as RichTextLabel
	if chat != null:
		return chat
	chat = RichTextLabel.new()
	chat.name = "ChatText"
	chat.custom_minimum_size = Vector2(640, 180)
	chat.fit_content = true
	add_child(chat)
	return chat


func _ensure_message_edit() -> LineEdit:
	var line := get_node_or_null("MessageEdit") as LineEdit
	if line != null:
		return line
	line = LineEdit.new()
	line.name = "MessageEdit"
	line.placeholder_text = "Type message..."
	add_child(line)
	return line

