class_name UnitGrid
extends Node

## Modèle logique d'une zone : quelle unité occupe quelle case.
##
## Purement logique — aucune position en pixels ici. La conversion case/pixel est
## le travail de UnitZone. Un index inverse unité -> case évite de balayer toute
## la grille pour retrouver un joueur.

signal unit_grid_changed

## Utilisé par UnitZone pour ses limites quand la zone n'a pas de cases peintes
## (le terrain). Sans objet pour une zone déduite de ses cases (les réserves).
@export var size: Vector2i

var _unit_by_tile: Dictionary = {}
var _tile_by_unit: Dictionary = {}


## Place l'unité sur la case, en la retirant d'abord de sa case précédente.
func place_unit(tile: Vector2i, unit: Node) -> void:
	remove_unit(unit)
	_unit_by_tile[tile] = unit
	_tile_by_unit[unit] = tile
	unit_grid_changed.emit()


func remove_unit(unit: Node) -> void:
	if not _tile_by_unit.has(unit):
		return
	_unit_by_tile.erase(_tile_by_unit[unit])
	_tile_by_unit.erase(unit)
	unit_grid_changed.emit()


func get_unit_at(tile: Vector2i) -> Node:
	return _unit_by_tile.get(tile, null)


func is_tile_occupied(tile: Vector2i) -> bool:
	return _unit_by_tile.get(tile, null) != null


## Vrai si la case est prise par quelqu'un d'autre que `unit` : reposer une unité
## sur sa propre case n'est pas une collision.
func is_tile_blocked_for(tile: Vector2i, unit: Node) -> bool:
	var occupant: Node = _unit_by_tile.get(tile, null)
	return occupant != null and occupant != unit


func has_unit(unit: Node) -> bool:
	return _tile_by_unit.has(unit)


## Case occupée par l'unité. À n'appeler qu'après has_unit().
func get_tile_of(unit: Node) -> Vector2i:
	return _tile_by_unit.get(unit, Vector2i.ZERO)


func get_occupied_tiles() -> Array:
	return _unit_by_tile.keys()


func clear() -> void:
	_unit_by_tile.clear()
	_tile_by_unit.clear()
	unit_grid_changed.emit()
