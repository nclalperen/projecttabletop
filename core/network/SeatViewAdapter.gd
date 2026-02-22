extends RefCounted
class_name SeatViewAdapter

static func _normalize(index: int, player_count: int) -> int:
	if player_count <= 0:
		return 0
	var value: int = index % player_count
	if value < 0:
		value += player_count
	return value

static func to_local(abs_index: int, local_abs_seat: int, player_count: int = 4) -> int:
	if abs_index < 0:
		return abs_index
	return _normalize(abs_index - local_abs_seat, player_count)

static func to_abs(local_index: int, local_abs_seat: int, player_count: int = 4) -> int:
	if local_index < 0:
		return local_index
	return _normalize(local_index + local_abs_seat, player_count)

static func remap_index_array_to_local(indices: Array, local_abs_seat: int, player_count: int = 4) -> Array:
	var out: Array = []
	for idx in indices:
		out.append(to_local(int(idx), local_abs_seat, player_count))
	return out

static func remap_index_array_to_abs(indices: Array, local_abs_seat: int, player_count: int = 4) -> Array:
	var out: Array = []
	for idx in indices:
		out.append(to_abs(int(idx), local_abs_seat, player_count))
	return out

static func rotate_players_to_local(items: Array, local_abs_seat: int) -> Array:
	var count: int = items.size()
	if count <= 0:
		return []
	var out: Array = []
	out.resize(count)
	for local_idx in range(count):
		var abs_idx: int = to_abs(local_idx, local_abs_seat, count)
		out[local_idx] = items[abs_idx]
	return out

static func rotate_players_to_abs(items: Array, local_abs_seat: int) -> Array:
	var count: int = items.size()
	if count <= 0:
		return []
	var out: Array = []
	out.resize(count)
	for abs_idx in range(count):
		var local_idx: int = to_local(abs_idx, local_abs_seat, count)
		out[abs_idx] = items[local_idx]
	return out
