## Configuration resource for a game table.
## Describes the table's physical dimensions, visual theme, seat layout,
## and functional positions (deck, indicator, meld lanes).
extends Resource
class_name TableConfig

## Unique identifier for this table configuration.
@export var table_id: StringName = &"default"

## Human-readable name for display.
@export var display_name: String = "Table"

## Number of seats at this table.
@export var seat_count: int = 4

# ─── Physical Dimensions (meters) ───

## Width of the table body.
@export var table_width: float = 1.0

## Depth of the table body.
@export var table_depth: float = 1.0

## Height/thickness of the table body.
@export var table_height: float = 0.075

## Width of the felt play surface.
@export var felt_width: float = 0.80

## Depth of the felt play surface.
@export var felt_depth: float = 0.80

# ─── Rack Dimensions ───

## Length of a player rack.
@export var rack_length: float = 0.82

## Depth of a player rack.
@export var rack_depth: float = 0.15

## Height of a player rack.
@export var rack_height: float = 0.11

## Gap between rack edge and felt edge.
@export var rack_gap_to_felt: float = 0.005

# ─── Tile Dimensions ───

## Tile width.
@export var tile_width: float = 0.045

## Tile height.
@export var tile_height: float = 0.065

## Tile depth/thickness.
@export var tile_depth: float = 0.009

# ─── Visual Theme ───

## Felt surface color.
@export var felt_color: Color = Color(0.16, 0.34, 0.28)

## Table wood color.
@export var wood_color: Color = Color(0.31, 0.19, 0.12)

## Player rack wood color.
@export var rack_color: Color = Color(0.52, 0.39, 0.28)

## Opponent rack wood color.
@export var opponent_rack_color: Color = Color(0.56, 0.42, 0.31)

## Tile face color.
@export var tile_face_color: Color = Color(0.95, 0.93, 0.88)

## Tile back color.
@export var tile_back_color: Color = Color(0.84, 0.80, 0.72)

## Whether to use the procedural table art builder.
@export var use_procedural_art: bool = true

# ─── Seats ───

## Array of seat configurations.
@export var seats: Array[SeatConfig] = []

# ─── Deck & Indicator ───

## Table-local 2D position of the draw deck.
@export var deck_position: Vector2 = Vector2(-0.12, -0.27)

## Gap between indicator tile and deck.
@export var indicator_gap: float = 0.012


## Returns the computed rack center distance from table center.
func rack_center() -> float:
	return table_width * 0.5 - rack_depth * 0.5 - rack_gap_to_felt


## Returns the felt half-extent (used for layout calculations).
func felt_half() -> float:
	return felt_width * 0.5


## Returns the SeatConfig for the given seat index, or null.
func get_seat(index: int) -> SeatConfig:
	for seat in seats:
		if seat.seat_index == index:
			return seat
	return null


## Returns the local player's SeatConfig, or null.
func get_local_seat() -> SeatConfig:
	for seat in seats:
		if seat.is_local_player:
			return seat
	return null
