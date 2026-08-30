extends Node

## Porte le catalogue et le rend accessible à tous les écrans.
##
## Il ne lit plus les fichiers — c'est le travail de CatalogLoader — et ne
## cherche plus dans les données — c'est celui du catalogue. Il ne reste qu'un
## porteur d'instance et une façade de délégation.

var data: BloodBowlData


func _ready():
	data = CatalogLoader.new().load_all()
	data.print_summary()


func get_team(team_uid: String) -> BloodBowlData.Team:
	return data.get_team_by_uid(team_uid)


func get_all_teams() -> Array[BloodBowlData.Team]:
	return data.get_all_teams()


func get_player(team_uid: String, player_uid: String) -> BloodBowlData.Player:
	var team = get_team(team_uid)
	if team:
		return team.get_player_by_uid(player_uid)
	return null


func get_teams_for_league(league: String) -> Array[BloodBowlData.Team]:
	return data.get_teams_by_league(league)


func search_teams(query: String) -> Array[BloodBowlData.Team]:
	return data.search_teams(query)


func get_affordable_players(team_uid: String, budget: int) -> Array[BloodBowlData.Player]:
	return data.get_affordable_players(team_uid, budget)


func get_skill_name(skill_uid: String) -> String:
	return data.get_skill_name(skill_uid)


func get_skill(skill_uid: String) -> BloodBowlData.Skill:
	return data.get_skill_by_uid(skill_uid)


func get_skill_category_label(category_id: String) -> String:
	return data.get_skill_category_label(category_id)


## Ajouté pour que skill_list.gd cesse d'atteindre `BloodBowlManager.data.skills`
## en traversant la façade.
func get_all_skills() -> Array[BloodBowlData.Skill]:
	return data.get_all_skills()


func get_all_star_players() -> Array[BloodBowlData.StarPlayer]:
	return data.star_players


func get_stars_for_team(team: BloodBowlData.Team) -> Array[BloodBowlData.StarPlayer]:
	return data.get_stars_for_team(team)


func get_star_player(uid: String) -> BloodBowlData.StarPlayer:
	return data.get_star_player_by_uid(uid)
