extends "res://tests/lib/test_case.gd"

## Caractérise les limites d'une UnitZone avant la suppression de
## `use_painted_cells` (carte 2 du kanban).
##
## Ce drapeau n'est posé à `true` par aucune scène : le chemin « cases peintes »
## n'a jamais été emprunté. Ces tests doivent donc passer à l'identique avant et
## après sa suppression — c'est ce qui prouve qu'on ne retire que du code mort.


func _zone(size: Vector2i) -> UnitZone:
	var grid := track(UnitGrid.new()) as UnitGrid
	grid.size = size
	var zone := track(UnitZone.new()) as UnitZone
	zone.unit_grid = grid
	zone._ready()
	return zone


func test_bounds_come_from_the_grid_size() -> void:
	var zone := _zone(Vector2i(26, 15))
	is_true(zone.is_tile_in_bounds(Vector2i(0, 0)), "le coin haut-gauche est dans le terrain")
	is_true(zone.is_tile_in_bounds(Vector2i(25, 14)), "le coin bas-droit est dans le terrain")


func test_outside_the_grid_is_out_of_bounds() -> void:
	var zone := _zone(Vector2i(26, 15))
	is_false(zone.is_tile_in_bounds(Vector2i(26, 0)), "une colonne au-delà est dehors")
	is_false(zone.is_tile_in_bounds(Vector2i(0, 15)), "une ligne au-delà est dehors")
	is_false(zone.is_tile_in_bounds(Vector2i(-1, 0)), "une coordonnée négative est dehors")


## Sans grille, aucune case n'est valide — et la zone le signale.
func test_a_zone_without_grid_has_no_valid_tile() -> void:
	var zone := track(UnitZone.new()) as UnitZone
	zone._ready()
	is_false(zone.is_tile_in_bounds(Vector2i(0, 0)), "aucune case sans grille")
