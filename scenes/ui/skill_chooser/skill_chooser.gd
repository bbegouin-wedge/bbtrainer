extends CanvasLayer

## Pastille de couleur posée sur chaque bouton de catégorie : c'est la légende
## du code couleur repris par les pastilles de compétences.
## Le texte des boutons est centré : la plus étroite des gouttières gauches fait
## 27 px (« Générales »), la pastille doit tenir dedans sans toucher le libellé.
const CATEGORY_SWATCH_RADIUS := 7.0
const CATEGORY_SWATCH_CENTER_X := 15.0

var skillList: SkillList
var team_players: Tree
var _selected_player: BloodBowlData.Player = null
var _selected_index: int = -1

func _ready() -> void:
	skillList = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/skills_panel/MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/ScrollContainer2/MarginContainer/skill_list
	team_players = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/player_list/MarginContainer/HBoxContainer/VBoxContainer/ScrollContainer/team_players
	EventBus.player_selected_for_skill.connect(_on_player_selected)
	skillList.skill_toggled.connect(_on_skill_toggled)
	_decorate_category_buttons()


## Chaque bouton de catégorie porte sa catégorie en métadonnée (voir la scène).
func _decorate_category_buttons() -> void:
	var container := find_child("skill_cat", true, false)
	if container == null:
		push_warning("Conteneur des catégories introuvable : pas de légende de couleurs")
		return
	for button in container.get_children():
		if not button is Button or not button.has_meta("category"):
			continue
		button.add_child(_build_category_swatch(button.get_meta("category")))


func _build_category_swatch(category_id: String) -> SkillBadgeView:
	var swatch := SkillBadgeView.new()
	swatch.radius = CATEGORY_SWATCH_RADIUS
	swatch.setup_category(category_id)
	# Décoratif : le libellé du bouton nomme déjà la catégorie, et on ne veut
	# surtout pas intercepter le clic destiné au bouton.
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Positionné par son centre : la boîte du Control est plus large que le disque.
	var half := swatch.custom_minimum_size.x * 0.5
	swatch.anchor_left = 0.0
	swatch.anchor_right = 0.0
	swatch.anchor_top = 0.5
	swatch.anchor_bottom = 0.5
	swatch.offset_left = CATEGORY_SWATCH_CENTER_X - half
	swatch.offset_right = CATEGORY_SWATCH_CENTER_X + half
	swatch.offset_top = -half
	swatch.offset_bottom = half
	return swatch

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
