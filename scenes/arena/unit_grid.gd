class_name UnitGrid
extends Node

signal unit_grid_changed

@export var size: Vector2i

var units: Dictionary

func  _ready() -> void:
	for i in size.x:
		for j in size.y:
			units[Vector2i(i,j)] = null
	#add_unit(Vector2i(2,3),$"../../Unit")
	
func add_unit(tile: Vector2i, unit: Node) -> void:
	units[tile] = unit
	unit_grid_changed.emit()

func is_tile_occupied(tile: Vector2i) -> bool:
	return units[tile] != null
	
