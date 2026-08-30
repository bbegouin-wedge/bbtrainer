extends "res://tests/lib/test_case.gd"

## Tests de caractérisation de TeamState, écrits AVANT son extraction.
##
## Ils sont bâtis d'après les onze sites d'appel réels — vertical_team_list,
## roster_tree, champions_list, skill_chooser, team_players — et non d'après
## l'usage qu'on imagine. C'est l'erreur qui, carte 9, avait laissé passer le cas
## de l'unité nulle : les tests avaient été écrits d'après le fichier de test.


func _equipe(nb_joueurs: int) -> BloodBowlData.Team:
	var joueurs := []
	for i in range(nb_joueurs):
		joueurs.append({"uid": "P%d" % i, "positionName": "Poste %d" % i, "cost": 50000 + i})
	var equipe := BloodBowlData.Team.new({"uid": "T", "name": "Essai"})
	for donnee in joueurs:
		equipe.available_players.append(BloodBowlData.Player.new(donnee))
	return equipe


func _etat() -> Node:
	return track(preload("res://autoload/team_state.gd").new()) as Node


## Choisir une équipe initialise la composition à zéro pour chaque poste.
func test_selecting_a_team_zeroes_the_composition() -> void:
	var etat := _etat()
	var equipe := _equipe(3)
	etat.select_team(equipe)
	equals(etat.get_selected_team(), equipe, "l'équipe choisie est retenue")
	for joueur in equipe.available_players:
		equals(etat.get_player_count(joueur), 0, "chaque poste démarre à zéro")


## Recruter incrémente, renvoyer décrémente — et jamais sous zéro.
func test_recruiting_and_firing_move_the_count() -> void:
	var etat := _etat()
	var equipe := _equipe(2)
	etat.select_team(equipe)
	var joueur = equipe.available_players[0]
	etat.recruit_player(joueur)
	etat.recruit_player(joueur)
	equals(etat.get_player_count(joueur), 2, "deux recrutements font deux")
	etat.fire_player(joueur)
	equals(etat.get_player_count(joueur), 1, "un renvoi retire un")
	etat.fire_player(joueur)
	etat.fire_player(joueur)
	equals(etat.get_player_count(joueur), 0, "on ne descend pas sous zéro")


## La composition déployée contient autant d'exemplaires que de recrutements,
## et ce sont des copies — roster_tree et team_players les modifient ensuite.
func test_expanding_duplicates_each_recruit() -> void:
	var etat := _etat()
	var equipe := _equipe(2)
	etat.select_team(equipe)
	etat.recruit_player(equipe.available_players[0])
	etat.recruit_player(equipe.available_players[0])
	etat.recruit_player(equipe.available_players[1])
	etat.expand_team_composition()
	var deployee = etat.get_expanded_team()
	equals(deployee.size(), 3, "trois exemplaires pour trois recrutements")
	is_false(deployee[0] == equipe.available_players[0], "ce sont des copies")


## Déployer deux fois de suite ne cumule pas.
func test_expanding_twice_does_not_accumulate() -> void:
	var etat := _etat()
	var equipe := _equipe(1)
	etat.select_team(equipe)
	etat.recruit_player(equipe.available_players[0])
	etat.expand_team_composition()
	etat.expand_team_composition()
	equals(etat.get_expanded_team().size(), 1, "le déploiement repart de zéro")


## Choisir une autre équipe efface la composition précédente.
func test_choosing_another_team_resets_the_composition() -> void:
	var etat := _etat()
	var premiere := _equipe(2)
	etat.select_team(premiere)
	etat.recruit_player(premiere.available_players[0])
	var seconde := _equipe(2)
	etat.select_team(seconde)
	equals(etat.get_player_count(seconde.available_players[0]), 0, "tout repart à zéro")


## Les stars s'ajoutent et se retirent par leur identifiant.
func test_stars_are_kept_by_uid() -> void:
	var etat := _etat()
	var star := BloodBowlData.StarPlayer.new({"uid": "S1", "name": "Griff"})
	etat.add_star(star)
	equals(etat.get_stars().size(), 1, "la star est retenue")
	etat.remove_star(star)
	equals(etat.get_stars().size(), 0, "et se retire")
