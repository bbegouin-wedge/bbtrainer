extends CanvasLayer

var skillList: SkillList
var team_players: Tree
var _selected_player: BloodBowlData.Player = null
var _selected_index: int = -1

func _ready() -> void:
	skillList = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/skills_panel/MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/ScrollContainer2/MarginContainer/skill_list
	team_players = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/player_list/MarginContainer/HBoxContainer/VBoxContainer/ScrollContainer/team_players
	EventBus.player_selected_for_skill.connect(_on_player_selected)
	skillList.skill_toggled.connect(_on_skill_toggled)

func _on_player_selected(player: BloodBowlData.Player, index: int) -> void:
	_selected_player = player
	_selected_index = index
	skillList.set_player_skills(player.skills, player.base_skills)

func _on_skill_toggled(skill_uid: String, is_active: bool) -> void:
	if _selected_player == null:
		return
	var expanded_team := TeamState.get_expanded_team()
	if _selected_index - 1 < 0 or _selected_index - 1 >= expanded_team.size():
		return
	var player: BloodBowlData.Player = expanded_team[_selected_index - 1]
	if is_active and skill_uid not in player.skills:
		player.skills.append(skill_uid)
	elif not is_active and skill_uid in player.skills:
		player.skills.erase(skill_uid)
	team_players._populate_tree(expanded_team)

func _on_select_general_skill() -> void:
	skillList.displayGeneralSkills()

func _on_select_agility_skill() -> void:
	skillList.displayAgilitySkills()
	
func _on_select_devious_skill() -> void:
	skillList.displayDeviousSkills()
	
func _on_select_pass_skill() -> void:
	skillList.displayPasskills()
	
func _on_select_strength_skill() -> void:
	skillList.displayStrengthSkills()
	
func _on_select_mutations_skill() -> void:
	skillList.displayMutationSills()
	
func _on_select_traits_skill() -> void:
	skillList.displayTraitsSills()
