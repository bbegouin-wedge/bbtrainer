class_name TeamComposition
extends RefCounted

## La composition d'équipe d'avant-match : quelle équipe, combien de chaque
## poste, quelles stars.
##
## Pur : il n'émet rien et ne connaît aucun autoload. C'est `TeamState`, la
## coquille qui le porte, qui prévient l'`EventBus` après l'avoir appelé — même
## partage que le noyau Rust et sa liaison, où le noyau calcule et la coquille
## émet.
##
## Le code vient de `autoload/team_state.gd`, déplacé sans réécriture ; seuls
## les noms sont passés en snake_case, le camelCase d'origine étant le seul du
## projet (faille 7 de l'audit).

var _selected_team: BloodBowlData.Team = null
var _team_composition: Dictionary = {}
var _champions_list: Dictionary = {}
var _expanded_team: Array = []


func select_team(selected_team: BloodBowlData.Team) -> void:
	_selected_team = selected_team
	_team_composition = {}
	for player in _selected_team.available_players:
		_team_composition[player] = 0


func get_selected_team() -> BloodBowlData.Team:
	return _selected_team


func recruit_player(recruit: BloodBowlData.Player) -> void:
	if recruit not in _team_composition.keys():
		_team_composition[recruit] = 0
	_team_composition[recruit] = _team_composition[recruit] + 1


func fire_player(recruit: BloodBowlData.Player) -> void:
	if _team_composition[recruit] == 0:
		return
	_team_composition[recruit] = _team_composition[recruit] - 1


func get_player_count(of_type: BloodBowlData.Player) -> int:
	return _team_composition[of_type]


func get_composition() -> Dictionary:
	return _team_composition


func add_star(champion: BloodBowlData.StarPlayer) -> void:
	_champions_list[champion.uid] = champion


func remove_star(champion: BloodBowlData.StarPlayer) -> void:
	_champions_list.erase(champion.uid)


## Ajouté pour que match_state cesse de lire `TeamState._champions_list`, un
## champ privé atteint depuis l'extérieur.
func get_stars() -> Array:
	return _champions_list.values()


func get_expanded_team() -> Array:
	return _expanded_team


func expand_team_composition() -> void:
	_expanded_team.clear()
	for player_ref in _team_composition.keys():
		for i in range(_team_composition[player_ref]):
			_expanded_team.append(player_ref.duplicate())
