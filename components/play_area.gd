class_name PlayArea
extends TileMapLayer

@export var unit_grid: UnitGrid
var bounds: Rect2i

func _ready() -> void:
	bounds = Rect2i(Vector2.ZERO, unit_grid.size)

func get_tile_from_global(global: Vector2) -> Vector2i:
	return local_to_map(to_local(global))
	
func get_global_from_tile(tile: Vector2i) -> Vector2:
	return to_global(map_to_local(tile))

func is_tile_in_bounds(tile:Vector2i) -> bool:
	return bounds.has_point(tile)

func get_hovered_tile() -> Vector2i:
	return local_to_map(get_local_mouse_position())
	
func get_coords()-> Vector2:
	return map_to_local(get_hovered_tile())

func get_top_left_tile_coords()-> Vector2:
	var localCoords = get_coords()
	return Vector2(localCoords.x - 105, localCoords.y - 105)
