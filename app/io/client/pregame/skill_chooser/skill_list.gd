extends GridContainer
class_name SkillList

signal skill_toggled(skill_uid: String, is_active: bool)

var _player_skills: Array[String] = []
var _base_skills: Array[String] = []

func set_player_skills(skills: Array[String], base_skills: Array[String]) -> void:
	_player_skills = skills
	_base_skills = base_skills
	_update_button_states()

func display_skills_by_category(category: String) -> void:
	for child in get_children():
		child.queue_free()

	for skill in BloodBowlManager.get_all_skills():
		if skill.category == category:
			var button := Button.new()
			button.text = skill.name
			button.theme_type_variation = "FlatButton"
			button.tooltip_text = skill.description
			button.toggle_mode = true
			button.button_pressed = skill.uid in _player_skills
			button.toggled.connect(_on_skill_toggled.bind(skill.uid))
			add_child(button)

func _on_skill_toggled(is_active: bool, skill_uid: String) -> void:
	skill_toggled.emit(skill_uid, is_active)

func _update_button_states() -> void:
	for button in get_children():
		if button is Button:
			var skill_uid := _find_skill_uid(button.text)
			button.set_pressed_no_signal(skill_uid in _player_skills)
			button.disabled = skill_uid in _base_skills

func _find_skill_uid(skill_name: String) -> String:
	for skill in BloodBowlManager.get_all_skills():
		if skill.name == skill_name:
			return skill.uid
	return ""

func displayGeneralSkills() -> void:
	display_skills_by_category("GENERAL")

func displayAgilitySkills() -> void:
	display_skills_by_category("AGILITY")
	
func displayDeviousSkills() -> void:
	display_skills_by_category("DEVIOUS")
	
func displayStrengthSkills() -> void:
	display_skills_by_category("STRENGTH")

func displayPasskills() -> void:
	display_skills_by_category("PASSING")

func displayMutationSills() -> void:
	display_skills_by_category("MUTATIONS")

func displayTraitsSills() -> void:
	display_skills_by_category("TRAITS")
