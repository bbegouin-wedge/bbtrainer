class_name UnitZone
extends TileMapLayer

## Zone de dépôt : un calque de tuiles doublé d'un UnitGrid qui dit qui occupe quoi.
##
## Une seule zone existe aujourd'hui — le terrain. Les réserves, K.O. et blessés
## sont des états de MatchState affichés par le HUD, pas des lieux du monde : les
## calques latéraux de arena.tscn sont purement visuels.

@export var unit_grid: UnitGrid

var bounds: Rect2i


func _ready() -> void:
	if unit_grid:
		bounds = Rect2i(Vector2i.ZERO, unit_grid.size)
	else:
		push_warning("UnitZone sans UnitGrid : aucune case ne sera valide")


func get_tile_from_global(global: Vector2) -> Vector2i:
	return local_to_map(to_local(global))


func get_global_from_tile(tile: Vector2i) -> Vector2:
	return to_global(map_to_local(tile))


## Coin haut-gauche de la case, en coordonnées globales : les unités ont leur
## origine en haut à gauche alors que map_to_local renvoie le centre.
func get_global_top_left_of_tile(tile: Vector2i) -> Vector2:
	return to_global(map_to_local(tile) - Vector2(tile_set.tile_size) * 0.5)


func is_tile_in_bounds(tile: Vector2i) -> bool:
	return bounds.has_point(tile)


func is_tile_free_for(tile: Vector2i, unit: Node) -> bool:
	if unit_grid == null:
		return true
	return not unit_grid.is_tile_blocked_for(tile, unit)


func get_hovered_tile() -> Vector2i:
	return local_to_map(get_local_mouse_position())


func is_hovering() -> bool:
	return is_tile_in_bounds(get_hovered_tile())


func get_coords() -> Vector2:
	return map_to_local(get_hovered_tile())


func get_top_left_tile_coords() -> Vector2:
	return get_coords() - Vector2(tile_set.tile_size) * 0.5
