# blood_bowl_data.gd
class_name BloodBowlData
extends Resource

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

## Recherches remontées de BloodBowlManager : ce sont des recherches dans le
## catalogue, pas de l'orchestration.

func get_all_teams() -> Array[Team]:
	teams.sort_custom(func(a, b): return a.name < b.name)
	return teams

func search_teams(query: String) -> Array[Team]:
	var results: Array[Team] = []
	var query_lower = query.to_lower()
	
	for team in teams:
		if query_lower in team.name.to_lower() or query_lower in team.uid.to_lower():
			results.append(team)
	
	return results

func get_affordable_players(team_uid: String, budget: int) -> Array[Player]:
	var team = get_team_by_uid(team_uid)
	if not team:
		return []

	var affordable: Array[Player] = []
	for player in team.available_players:
		if player.cost <= budget:
			affordable.append(player)

	return affordable

func get_stars_for_team(team: Team) -> Array[StarPlayer]:
	var result: Array[StarPlayer] = []
	for sp in star_players:
		if team.uid in sp.available_for_rosters:
			result.append(sp)
	return result


func get_all_skills() -> Array[Skill]:
	return skills


func print_summary():
	print("\n=== Blood Bowl %s - %s ===" % [bloodbowl_version, edition])
	print("Nombre d'équipes: %d\n" % teams.size())
	
	for team in teams:
		print("- %s" % team.to_string())
