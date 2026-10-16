## Base class for tabletop game presentation views (2D and 3D).
## Defines the contract for configuring games, injecting authoritative controllers,
## and managing table/seat configurations.
extends Node
class_name GameTableBase

const TableConfig = preload("res://core/config/TableConfig.gd")
const SeatConfig = preload("res://core/config/SeatConfig.gd")

## The active table configuration defining table dimensions, materials, and seat layout.
var _table_config: TableConfig = null


## Configures the game rules, seed, player count, and bot difficulties.
func configure_game(_rule_config, _game_seed: int, _player_count: int, _bot_difficulties: Array = []) -> void:
	pass


## Injects an external controller (e.g. online or custom match controller).
func inject_controller(_controller) -> void:
	pass


## Returns the active presentation-independent game session (e.g. OkeySession).
func get_session() -> Node:
	return null


## Returns the active table configuration.
func get_table_config() -> TableConfig:
	return _table_config


## Sets a new table configuration and rebuilds the table presentation.
func set_table_config(config: TableConfig) -> void:
	_table_config = config


## Updates the configuration for a specific seat index.
func set_seat_config(seat_index: int, seat: SeatConfig) -> void:
	if seat == null:
		return
	var cfg = get_table_config()
	if cfg == null:
		return
	for i in range(cfg.seats.size()):
		if cfg.seats[i].seat_index == seat_index:
			cfg.seats[i] = seat
			return
	cfg.seats.append(seat)


## Returns the SeatConfig for a given seat index, or null.
func get_seat_config(seat_index: int) -> SeatConfig:
	var cfg = get_table_config()
	if cfg == null:
		return null
	return cfg.get_seat(seat_index)
