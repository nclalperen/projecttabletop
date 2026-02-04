extends RefCounted
class_name Tile

enum TileColor { RED, BLUE, BLACK, YELLOW }
enum Kind { NORMAL, FAKE_OKEY }

var color: int
var number: int
var kind: int
var unique_id: int

func _init(p_color: int = TileColor.RED, p_number: int = 1, p_kind: int = Kind.NORMAL, p_unique_id: int = -1) -> void:
	color = p_color
	number = p_number
	kind = p_kind
	unique_id = p_unique_id

func points_value(context: Object = null) -> int:
	if kind == Kind.NORMAL:
		return number
	# For fake okey, prefer context to interpret it.
	if context != null and context.has_method("get_fake_okey_value"):
		return int(context.call("get_fake_okey_value"))
	return 0

