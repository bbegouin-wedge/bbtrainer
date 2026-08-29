extends "res://tests/lib/test_case.gd"

## Vérifie le câblage de l'arène — ce qu'aucun test unitaire ne peut voir.
##
## En Godot, `_ready()` remonte des enfants vers les parents : la zone de jeu est
## prête AVANT l'arène qui doit lui donner sa grille. Si l'injection se faisait
## au mauvais moment, le terrain s'afficherait normalement et n'accepterait plus
## une seule unité — sans erreur, sans avertissement.
##
## C'est exactement le risque que la carte 1 avait identifié, et le seul test qui
## le couvre.


func test_the_play_area_receives_a_grid_at_startup() -> void:
	var arena := await mount("res://io/client/world/arena.tscn")
	var zone: UnitZone = arena.play_area
	check(zone.unit_grid != null, "la zone de jeu doit avoir reçu une grille")
	equals(zone.unit_grid.size, Pitch.SIZE, "la grille a la taille du terrain")


func test_the_play_area_bounds_match_the_pitch() -> void:
	var arena := await mount("res://io/client/world/arena.tscn")
	var zone: UnitZone = arena.play_area
	is_true(zone.is_tile_in_bounds(Vector2i(0, 0)), "le coin haut-gauche est jouable")
	is_true(
		zone.is_tile_in_bounds(Pitch.SIZE - Vector2i.ONE),
		"le coin bas-droit est jouable"
	)
	is_false(zone.is_tile_in_bounds(Pitch.SIZE), "une case au-delà ne l'est pas")
