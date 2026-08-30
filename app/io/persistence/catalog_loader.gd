class_name CatalogLoader
extends RefCounted

## Lecture des quatre JSON de règles, et rien d'autre.
##
## Ce métier vivait dans le catalogue lui-même, qui savait donc ouvrir des
## fichiers. Le noyau ignore le disque — c'est ce que dit
## `docs/noyau-et-apprenant.html`, et c'est ce que `check-arch` vérifie
## désormais.
##
## Le code ci-dessous est celui d'origine, déplacé sans réécriture : seules les
## références aux champs du catalogue ont été préfixées.

const FICHIERS := {
	"teams": "res://app/io/persistence/teams_fr.json",
	"skills": "res://app/io/persistence/skills_fr.json",
	"categories": "res://app/io/persistence/skill_cat_fr.json",
	"stars": "res://app/io/persistence/star_players_fr.json",
}

var catalogue := BloodBowlData.new()


## Construit le catalogue complet, ou rend celui qu'on a pu bâtir.
func load_all() -> BloodBowlData:
	if not load_from_json(FICHIERS["teams"]):
		push_error("Échec du chargement des équipes")
	if not load_skills_from_json(FICHIERS["skills"]):
		push_error("Échec du chargement des compétences")
	if not load_skill_categories_from_json(FICHIERS["categories"]):
		push_error("Échec du chargement des catégories de compétences")
	if not load_star_players_from_json(FICHIERS["stars"]):
		push_error("Échec du chargement des star players")
	return catalogue


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
	catalogue.bloodbowl_version = data.get("bloodbowl_version", "")
	catalogue.edition = data.get("edition", "")
	
	catalogue.teams.clear()
	catalogue.teams_by_uid.clear()
	catalogue.teams_by_name.clear()
	
	if not data.has("teams"):
		push_error("Le JSON ne contient pas de teams")
		return false
	
	for team_data in data["teams"]:
		var team = BloodBowlData.Team.new(team_data)
		catalogue.teams.append(team)
		catalogue.teams_by_uid[team.uid] = team
		catalogue.teams_by_name[team.name] = team
	
	print("Chargement réussi: %d équipes" % catalogue.teams.size())
	return true

func load_skills_from_json(json_path: String) -> bool:
	var data = _read_json_dict(json_path, "skills")
	if data == null:
		return false

	catalogue.skills.clear()
	catalogue.skills_by_uid.clear()

	if not data.has("skills"):
		push_error("Le JSON ne contient pas de skills")
		return false

	for skill_data in data["skills"]:
		var skill = BloodBowlData.Skill.new(skill_data)
		catalogue.skills.append(skill)
		catalogue.skills_by_uid[skill.uid] = skill

	print("Chargement réussi: %d compétences" % catalogue.skills.size())
	return true

func load_skill_categories_from_json(json_path: String) -> bool:
	var data = _read_json_dict(json_path, "skill_categories")
	if data == null:
		return false

	catalogue.skill_categories.clear()
	catalogue.skill_categories_by_id.clear()

	if not data.has("skill_categories"):
		push_error("Le JSON ne contient pas de skill_categories")
		return false

	for category_data in data["skill_categories"]:
		var category = BloodBowlData.SkillCategory.new(category_data)
		catalogue.skill_categories.append(category)
		catalogue.skill_categories_by_id[category.id] = category

	print("Chargement réussi: %d catégories de compétences" % catalogue.skill_categories.size())
	return true

func load_star_players_from_json(json_path: String) -> bool:
	var data = _read_json_dict(json_path, "star_players")
	if data == null:
		return false

	catalogue.star_players.clear()
	catalogue.star_players_by_uid.clear()

	if not data.has("star_players"):
		push_error("Le JSON ne contient pas de star_players")
		return false

	for sp_data in data["star_players"]:
		var sp = BloodBowlData.StarPlayer.new(sp_data)
		catalogue.star_players.append(sp)
		catalogue.star_players_by_uid[sp.uid] = sp

	print("Chargement réussi: %d star players" % catalogue.star_players.size())
	return true

