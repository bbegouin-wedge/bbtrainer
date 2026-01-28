# blood_bowl_data.gd
class_name BloodBowlData
extends Resource

# Classes de données

# Classe pour stocker les icônes de joueur (versions bleue et rouge)
class PlayerIcon:
	var blue: String
	var red: String

	func _init(data):
		if data is Dictionary:
			blue = data.get("blue", "")
			red = data.get("red", "")
		else:
			blue = ""
			red = ""

	func get_blue_texture() -> Texture2D:
		if blue.is_empty():
			return null
		return load("res://" + blue)

	func get_red_texture() -> Texture2D:
		if red.is_empty():
			return null
		return load("res://" + red)

class Team:
	var uid: String
	var name: String
	var reroll_cost: int
	var tier: String
	var special_rules: Array[String]
	var cross_limit: Array
	var allowed_staff: Array[String]
	var available_players: Array[Player]
	var leagues: Array[String]
	var icon: String

	func _init(data: Dictionary):
		uid = data.get("uid", "")
		name = data.get("name", "")
		reroll_cost = data.get("rerollCost", 0)
		tier = data.get("tier", "")
		icon = data.get("icon", "")
		special_rules = []
		if data.has("specialRules"):
			special_rules.assign(data["specialRules"])
		cross_limit = data.get("cross_limit", [])
		allowed_staff = []
		if data.has("allowedStaff"):
			allowed_staff.assign(data["allowedStaff"])
		leagues = []
		if data.has("leagues"):
			leagues.assign(data["leagues"])

		available_players = []
		if data.has("availablePlayers"):
			for player_data in data["availablePlayers"]:
				available_players.append(Player.new(player_data))

	func get_player_by_uid(player_uid: String) -> Player:
		for player in available_players:
			if player.uid == player_uid:
				return player
		return null

	func get_icon_texture() -> Texture2D:
		if icon.is_empty():
			return null
		return load("res://" + icon)

class Player:
	var uid: String
	var position_name: String
	var cost: int
	var MA: int  # Movement Allowance
	var ST: int  # Strength
	var AG: int  # Agility
	var PA: int  # Passing
	var AV: int  # Armor Value
	var skills: Array[String]
	var primary_access: Array[String]
	var secondary_access: Array[String]
	var max_quantity: int
	var icon: PlayerIcon

	func _init(data: Dictionary):
		uid = data.get("uid", "")
		position_name = data.get("positionName", "")
		cost = data.get("cost", 0)
		MA = data.get("MA", 0)
		ST = data.get("ST", 0)
		AG = data.get("AG", 0)
		PA = data.get("PA", 0)
		AV = data.get("AV", 0)

		skills = []
		if data.has("skills"):
			skills.assign(data["skills"])

		primary_access = []
		if data.has("primaryAccess"):
			primary_access.assign(data["primaryAccess"])

		secondary_access = []
		if data.has("secondaryAccess"):
			secondary_access.assign(data["secondaryAccess"])

		max_quantity = data.get("max_quantity", 0)

		icon = PlayerIcon.new(data.get("icon", {}))

	func get_stats_string() -> String:
		return "MA:%d ST:%d AG:%d PA:%d AV:%d" % [MA, ST, AG, PA, AV]

	func get_blue_icon_texture() -> Texture2D:
		return icon.get_blue_texture()

	func get_red_icon_texture() -> Texture2D:
		return icon.get_red_texture()
	
# Données principales
var bloodbowl_version: String
var edition: String
var teams: Array[Team] = []

# Index pour accès rapide
var teams_by_uid: Dictionary = {}
var teams_by_name: Dictionary = {}

func load_from_json(json_path: String) -> bool:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Impossible d'ouvrir le fichier: " + json_path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Erreur de parsing JSON: " + json.get_error_message())
		return false
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Le JSON ne contient pas un dictionnaire racine")
		return false
	
	return parse_data(data)

func parse_data(data: Dictionary) -> bool:
	bloodbowl_version = data.get("bloodbowl_version", "")
	edition = data.get("edition", "")
	
	teams.clear()
	teams_by_uid.clear()
	teams_by_name.clear()
	
	if not data.has("teams"):
		push_error("Le JSON ne contient pas de teams")
		return false
	
	for team_data in data["teams"]:
		var team = Team.new(team_data)
		teams.append(team)
		teams_by_uid[team.uid] = team
		teams_by_name[team.name] = team
	
	print("Chargement réussi: %d équipes" % teams.size())
	return true

func get_team_by_uid(team_uid: String) -> Team:
	return teams_by_uid.get(team_uid, null)

func get_team_by_name(team_name: String) -> Team:
	return teams_by_name.get(team_name, null)

func get_teams_by_league(league: String) -> Array[Team]:
	var result: Array[Team] = []
	for team in teams:
		if league in team.leagues:
			result.append(team)
	return result

func get_teams_by_tier(tier: String) -> Array[Team]:
	var result: Array[Team] = []
	for team in teams:
		if team.tier == tier:
			result.append(team)
	return result

func print_summary():
	print("\n=== Blood Bowl %s - %s ===" % [bloodbowl_version, edition])
	print("Nombre d'équipes: %d\n" % teams.size())
	
	for team in teams:
		print("- %s" % team.to_string())
