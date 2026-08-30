# blood_bowl_data.gd
class_name BloodBowlData
extends Resource

## Racine sous laquelle vivent les images citées par les JSON.
##
## Les données portent un chemin relatif — « assets/team_icons/humans.png » —
## et ignorent où ce dossier vit dans le projet. C'est ce qui a permis de le
## déplacer sous le client sans réécrire une seule ligne des 348 chemins de
## teams_fr.json.
const ASSETS_ROOT := "res://app/io/client/"

# Classes de données

class Skill:
	var uid: String
	var name: String
	var category: String
	var type: String
	var activation: String
	var description: String

	func _init(data: Dictionary):
		uid = data.get("uid", "")
		name = data.get("name", "")
		category = data.get("category", "")
		type = data.get("type", "")
		activation = data.get("activation", "")
		description = data.get("description", "")

class SkillCategory:
	var id: String
	var label: String

	func _init(data: Dictionary):
		id = data.get("id", "")
		label = data.get("label", "")

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
		return load(ASSETS_ROOT + blue)

	func get_red_texture() -> Texture2D:
		if red.is_empty():
			return null
		return load(ASSETS_ROOT + red)

class StarPlayer:
	var uid: String
	var name: String
	var cost: int
	var MA: int
	var ST: int
	var AG: String
	var PA: String
	var AV: String
	var player_type: String
	var skills: Array[String]
	var special_ability_name: String
	var special_ability_description: String
	var plays_for: Array[String]
	var available_for_rosters: Array[String]
	var icon  # PlayerIcon or Array[PlayerIcon] for duo players

	func _init(data: Dictionary):
		uid = data.get("uid", "")
		name = data.get("name", "")
		cost = data.get("cost", 0)
		MA = data.get("MA", 0)
		ST = data.get("ST", 0)
		AG = str(data.get("AG", ""))
		PA = str(data.get("PA", ""))
		AV = str(data.get("AV", ""))
		player_type = data.get("playerType", "")
		special_ability_name = data.get("specialAbilityName", "")
		special_ability_description = data.get("specialAbilityDescription", "")

		skills = []
		if data.has("skills"):
			skills.assign(data["skills"])
		plays_for = []
		if data.has("playsFor"):
			plays_for.assign(data["playsFor"])
		available_for_rosters = []
		if data.has("availableForRosters"):
			available_for_rosters.assign(data["availableForRosters"])

		var icon_data = data.get("icon", {})
		if icon_data is Array:
			icon = []
			for ic in icon_data:
				icon.append(PlayerIcon.new(ic))
		else:
			icon = PlayerIcon.new(icon_data)

	func get_blue_icon_texture() -> Texture2D:
		if icon is PlayerIcon:
			return icon.get_blue_texture()
		elif icon is Array and icon.size() > 0:
			return icon[0].get_blue_texture()
		return null

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
	
	func get_player_by_index(player_idx: int) -> Player:
		return available_players[player_idx]

	func get_icon_texture() -> Texture2D:
		if icon.is_empty():
			return null
		return load(ASSETS_ROOT + icon)

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
	var base_skills: Array[String]
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

	func duplicate() -> Player:
		var copy := Player.new({})
		copy.uid = uid
		copy.position_name = position_name
		copy.cost = cost
		copy.MA = MA
		copy.ST = ST
		copy.AG = AG
		copy.PA = PA
		copy.AV = AV
		copy.skills = skills.duplicate()
		copy.base_skills = skills.duplicate()
		copy.primary_access = primary_access.duplicate()
		copy.secondary_access = secondary_access.duplicate()
		copy.max_quantity = max_quantity
		copy.icon = icon
		return copy

	func get_blue_icon_texture() -> Texture2D:
		return icon.get_blue_texture()

	func get_red_icon_texture() -> Texture2D:
		return icon.get_red_texture()
	
# Données principales
var bloodbowl_version: String
var edition: String
var teams: Array[Team] = []
var skills: Array[Skill] = []
var skill_categories: Array[SkillCategory] = []
var star_players: Array[StarPlayer] = []

# Index pour accès rapide
var teams_by_uid: Dictionary = {}
var teams_by_name: Dictionary = {}
var skills_by_uid: Dictionary = {}
var skill_categories_by_id: Dictionary = {}
var star_players_by_uid: Dictionary = {}

# Lit un fichier JSON et retourne son dictionnaire racine, ou null en cas d'échec.
func _read_json_dict(json_path: String, what: String) -> Variant:
	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Impossible d'ouvrir le fichier %s: %s" % [what, json_path])
		return null

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("Erreur de parsing JSON %s: %s" % [what, json.get_error_message()])
		return null

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("Le JSON %s ne contient pas un dictionnaire racine" % what)
		return null

	return json.data

func load_from_json(json_path: String) -> bool:
	var data = _read_json_dict(json_path, "teams")
	if data == null:
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

func load_skills_from_json(json_path: String) -> bool:
	var data = _read_json_dict(json_path, "skills")
	if data == null:
		return false

	skills.clear()
	skills_by_uid.clear()

	if not data.has("skills"):
		push_error("Le JSON ne contient pas de skills")
		return false

	for skill_data in data["skills"]:
		var skill = Skill.new(skill_data)
		skills.append(skill)
		skills_by_uid[skill.uid] = skill

	print("Chargement réussi: %d compétences" % skills.size())
	return true

func load_skill_categories_from_json(json_path: String) -> bool:
	var data = _read_json_dict(json_path, "skill_categories")
	if data == null:
		return false

	skill_categories.clear()
	skill_categories_by_id.clear()

	if not data.has("skill_categories"):
		push_error("Le JSON ne contient pas de skill_categories")
		return false

	for category_data in data["skill_categories"]:
		var category = SkillCategory.new(category_data)
		skill_categories.append(category)
		skill_categories_by_id[category.id] = category

	print("Chargement réussi: %d catégories de compétences" % skill_categories.size())
	return true

func load_star_players_from_json(json_path: String) -> bool:
	var data = _read_json_dict(json_path, "star_players")
	if data == null:
		return false

	star_players.clear()
	star_players_by_uid.clear()

	if not data.has("star_players"):
		push_error("Le JSON ne contient pas de star_players")
		return false

	for sp_data in data["star_players"]:
		var sp = StarPlayer.new(sp_data)
		star_players.append(sp)
		star_players_by_uid[sp.uid] = sp

	print("Chargement réussi: %d star players" % star_players.size())
	return true

func get_star_player_by_uid(uid: String) -> StarPlayer:
	return star_players_by_uid.get(uid, null)

func get_skill_by_uid(skill_uid: String) -> Skill:
	return skills_by_uid.get(skill_uid, null)

func get_skill_category(category_id: String) -> SkillCategory:
	return skill_categories_by_id.get(category_id, null)

func get_skill_category_label(category_id: String) -> String:
	var category = get_skill_category(category_id)
	if category:
		return category.label
	return category_id

func get_skill_name(skill_uid: String) -> String:
	var skill = get_skill_by_uid(skill_uid)
	if skill:
		return skill.name
	return skill_uid

func print_summary():
	print("\n=== Blood Bowl %s - %s ===" % [bloodbowl_version, edition])
	print("Nombre d'équipes: %d\n" % teams.size())
	
	for team in teams:
		print("- %s" % team.to_string())
