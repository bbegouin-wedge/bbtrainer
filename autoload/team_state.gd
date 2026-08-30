extends Node

## Porte la composition d'équipe et prévient les écrans quand elle change.
##
## Il ne contient plus de logique : elle vit dans `TeamComposition`, côté noyau.
## Ce qui reste ici est ce qu'un noyau ne peut pas faire — connaître l'`EventBus`.

var composition := TeamComposition.new()


func select_team(selected_team: BloodBowlData.Team) -> void:
	composition.select_team(selected_team)
	EventBus.team_selected.emit(selected_team)


func get_selected_team() -> BloodBowlData.Team:
	return composition.get_selected_team()


func recruit_player(recruit: BloodBowlData.Player) -> void:
	composition.recruit_player(recruit)


func fire_player(recruit: BloodBowlData.Player) -> void:
	composition.fire_player(recruit)


func get_player_count(of_type: BloodBowlData.Player) -> int:
	return composition.get_player_count(of_type)


func get_composition() -> Dictionary:
	return composition.get_composition()


func add_star(champion: BloodBowlData.StarPlayer) -> void:
	composition.add_star(champion)
	EventBus.star_selected.emit(champion)


func remove_star(champion: BloodBowlData.StarPlayer) -> void:
	composition.remove_star(champion)
	EventBus.star_deselected.emit(champion)


func get_stars() -> Array:
	return composition.get_stars()


func get_expanded_team() -> Array:
	return composition.get_expanded_team()


func expand_team_composition() -> void:
	composition.expand_team_composition()
