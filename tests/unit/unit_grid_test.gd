extends "res://tests/lib/test_case.gd"

## Tests de caractérisation de UnitGrid.
##
## Écrits AVANT sa conversion en RefCounted et son passage dans core/ (carte 1
## du kanban) : ils figent le comportement observable d'aujourd'hui, pour que la
## conversion se prouve. Écrits après, ils décriraient le comportement nouveau
## et ne prouveraient rien.
##
## Ils ne couvrent que la logique. Le vrai risque de la conversion est ailleurs
## — la propriété `size` écrite dans arena.tscn et l'export câblé par NodePath —
## et aucun test unitaire ne le verra ; c'est le rôle du test d'intégration
## prévu à l'étape 3 de la carte.


## La grille n'est plus un Node : rien à libérer, mais la taille se donne à la
## construction là où elle venait d'un @export renseigné dans la scène.
func _grid() -> UnitGrid:
	return UnitGrid.new(Pitch.SIZE)


func _unit() -> Node:
	return track(Node.new()) as Node


## Reposer une unité ailleurs la déplace : rien ne doit rester sur l'ancienne
## case. C'est l'index inverse qui pourrit en silence si ça casse.
func test_place_moves_instead_of_duplicating() -> void:
	var grid := _grid()
	var unit := _unit()
	grid.place_unit(Vector2i(1, 1), unit)
	grid.place_unit(Vector2i(4, 2), unit)
	is_null(grid.get_unit_at(Vector2i(1, 1)), "l'ancienne case doit être libérée")
	equals(grid.get_unit_at(Vector2i(4, 2)), unit, "l'unité est sur la nouvelle case")
	equals(grid.get_tile_of(unit), Vector2i(4, 2), "l'index inverse suit le déplacement")
	equals(grid.get_occupied_tiles().size(), 1, "une seule case occupée")


## Reposer une unité sur sa propre case n'est pas une collision — la subtilité
## que le commentaire de is_tile_blocked_for signale.
func test_own_tile_is_not_blocked() -> void:
	var grid := _grid()
	var unit := _unit()
	var other := _unit()
	grid.place_unit(Vector2i(3, 3), unit)
	is_false(grid.is_tile_blocked_for(Vector2i(3, 3), unit), "sa propre case ne bloque pas")
	is_true(grid.is_tile_blocked_for(Vector2i(3, 3), other), "elle bloque les autres")
	is_true(grid.is_tile_occupied(Vector2i(3, 3)), "la case est occupée")


func test_clear_empties_both_indexes() -> void:
	var grid := _grid()
	var unit := _unit()
	grid.place_unit(Vector2i(2, 2), unit)
	grid.clear()
	is_null(grid.get_unit_at(Vector2i(2, 2)), "l'index direct est vidé")
	is_false(grid.has_unit(unit), "l'index inverse est vidé")
	equals(grid.get_occupied_tiles().size(), 0, "aucune case occupée")


## Retirer une unité absente ne fait rien ET n'émet pas : un abonné qui se
## redessine à chaque signal le paierait autrement.
func test_removing_an_absent_unit_is_silent() -> void:
	var grid := _grid()
	var counter := _counter(grid)
	grid.remove_unit(_unit())
	equals(counter.count, 0, "aucun signal pour un retrait sans effet")


## Le déplacement émet DEUX fois — place_unit retire d'abord, et le retrait
## émet lui aussi. Comportement figé tel quel, pas approuvé : si la conversion
## le change, ce test le dira.
func test_signal_fires_on_place_remove_and_clear() -> void:
	var grid := _grid()
	var unit := _unit()
	var counter := _counter(grid)
	grid.place_unit(Vector2i(0, 0), unit)
	equals(counter.count, 1, "une émission à la pose")
	grid.place_unit(Vector2i(1, 0), unit)
	equals(counter.count, 3, "deux émissions au déplacement : retrait puis pose")
	grid.remove_unit(unit)
	equals(counter.count, 4, "une émission au retrait")
	grid.clear()
	equals(counter.count, 5, "une émission au vidage")


func test_empty_grid_answers_nothing() -> void:
	var grid := _grid()
	is_null(grid.get_unit_at(Vector2i(9, 9)), "aucune unité sur une case vide")
	is_false(grid.is_tile_occupied(Vector2i(9, 9)), "case vide non occupée")
	is_false(grid.has_unit(_unit()), "unité inconnue absente")


func _counter(grid: UnitGrid) -> RefCounted:
	var counter := track(preload("res://tests/unit/signal_counter.gd").new()) as RefCounted
	grid.unit_grid_changed.connect(counter.increment)
	return counter
