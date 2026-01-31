# blood_bowl_manager.gd (Autoload)
extends Node

var data: BloodBowlData

func _ready():
	load_data()

func load_data():
	data = BloodBowlData.new()

	# Charger les équipes depuis le fichier JSON
	var teams_path = "res://data/teams_fr.json"
	if data.load_from_json(teams_path):
		print("Données Blood Bowl chargées avec succès!")
		data.print_summary()
	else:
		push_error("Échec du chargement des données Blood Bowl")

	# Charger les compétences depuis le fichier JSON
	var skills_path = "res://data/skills_fr.json"
	if data.load_skills_from_json(skills_path):
		print("Compétences Blood Bowl chargées avec succès!")
	else:
		push_error("Échec du chargement des compétences Blood Bowl")

# API d'accès facile
func get_team(team_uid: String) -> BloodBowlData.Team:
	return data.get_team_by_uid(team_uid)

func get_all_teams() -> Array[BloodBowlData.Team]:
	data.teams.sort_custom(func(a, b): return a.name < b.name)
	return data.teams

func get_player(team_uid: String, player_uid: String) -> BloodBowlData.Player:
	var team = get_team(team_uid)
	if team:
		return team.get_player_by_uid(player_uid)
	return null

func get_teams_for_league(league: String) -> Array[BloodBowlData.Team]:
	return data.get_teams_by_league(league)

func search_teams(query: String) -> Array[BloodBowlData.Team]:
	var results: Array[BloodBowlData.Team] = []
	var query_lower = query.to_lower()
	
	for team in data.teams:
		if query_lower in team.name.to_lower() or query_lower in team.uid.to_lower():
			results.append(team)
	
	return results

func get_affordable_players(team_uid: String, budget: int) -> Array[BloodBowlData.Player]:
	var team = get_team(team_uid)
	if not team:
		return []

	var affordable: Array[BloodBowlData.Player] = []
	for player in team.available_players:
		if player.cost <= budget:
			affordable.append(player)

	return affordable

func get_skill_name(skill_uid: String) -> String:
	return data.get_skill_name(skill_uid)

func get_skill(skill_uid: String) -> BloodBowlData.Skill:
	return data.get_skill_by_uid(skill_uid)
