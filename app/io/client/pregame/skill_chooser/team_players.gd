extends Tree

func _ready():
	print("ready")
	_setup_tree();
	EventBus.game_phase_changed.connect(_on_game_phase_changed)
	
func _on_game_phase_changed(phase:  SceneOrchestrator.GameStatus):
	if phase == SceneOrchestrator.GameStatus.SELECT_SKILLS:
		TeamState.expandTeamComposition()
		_populate_tree(TeamState.get_expanded_team());


## Colonne « Ajouts », dessinée en pastilles plutôt qu'en texte.
const ADDED_SKILLS_COLUMN := 4
const BADGE_RADIUS := 13.0
const BADGE_SPACING_RATIO := 2.3
const BADGE_MARGIN := 6.0

func _setup_tree():
	columns = 5
	column_titles_visible = true
	hide_root = true
	select_mode = Tree.SELECT_ROW
	item_selected.connect(_on_item_selected)
	set_column_title(1, "Numero")
	set_column_title(2, "Poste")
	set_column_title(3, "Compétences")
	set_column_title(4, "Ajouts")

	set_column_custom_minimum_width(0, 25)
	set_column_custom_minimum_width(1, 50)
	set_column_custom_minimum_width(2, 100)
	set_column_custom_minimum_width(3, 200)
	set_column_custom_minimum_width(4, 150)

	size_flags_vertical = Control.SIZE_EXPAND_FILL

func _populate_tree(team: Array):
	clear()
	var root:TreeItem = create_item()

	var count:int = 1
	for player_ref in team:
		var item:TreeItem = create_item(root)
		item.set_text(1, str(count))
		item.set_text(2, player_ref.position_name)
		item.set_text(3, _format_skills(player_ref.base_skills))

		# Les compétences acquises reprennent les pastilles affichées sur le terrain.
		var added_skills := _get_added_skills(player_ref)
		item.set_cell_mode(ADDED_SKILLS_COLUMN, TreeItem.CELL_MODE_CUSTOM)
		item.set_custom_draw_callback(ADDED_SKILLS_COLUMN, _draw_added_skills)
		item.set_tooltip_text(ADDED_SKILLS_COLUMN, _format_skills(added_skills))

		# Centrer les colonnes de stats
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)

		item.set_metadata(0, player_ref)
		item.set_metadata(1, count)

		# Icône du joueur
		var icon = Icons.red(player_ref)
		if icon:
			item.set_icon(0, icon)
			item.set_icon_max_width(0, 32)
		count = count + 1

## Dessine la rangée de pastilles dans la cellule « Ajouts ».
## Appelé par le Tree pendant son rendu, donc on dessine sur le Tree lui-même.
func _draw_added_skills(item: TreeItem, rect: Rect2) -> void:
	var player: BloodBowlData.Player = item.get_metadata(0)
	if player == null:
		return
	var added_skills := _get_added_skills(player)
	if added_skills.is_empty():
		return

	var radius := minf(BADGE_RADIUS, rect.size.y * 0.5 - 1.0)
	if radius <= 1.0:
		return
	var pitch := radius * BADGE_SPACING_RATIO
	var center_y := rect.position.y + rect.size.y * 0.5
	# Centré dans la cellule comme les autres colonnes, calé à gauche si ça déborde.
	var total_width := pitch * (added_skills.size() - 1) + radius * 2.0
	var x := rect.position.x + maxf(BADGE_MARGIN, (rect.size.x - total_width) * 0.5) + radius
	var font := get_theme_default_font()

	for skill_uid in added_skills:
		if x + radius > rect.end.x:
			break
		SkillBadge.draw_into(self, Vector2(x, center_y), radius,
			SkillBadge.color_for_skill(skill_uid), SkillBadge.initials_for_skill(skill_uid), font)
		x += pitch


func _on_item_selected() -> void:
	var item := get_selected()
	if item == null:
		return
	var player: BloodBowlData.Player = item.get_metadata(0)
	var index: int = item.get_metadata(1)
	EventBus.player_selected_for_skill.emit(player, index)

func _get_added_skills(player: BloodBowlData.Player) -> Array[String]:
	var added: Array[String] = []
	for uid in player.skills:
		if uid not in player.base_skills:
			added.append(uid)
	return added

func _format_skills(skill_uids: Array[String]) -> String:
	if skill_uids.size() == 0:
		return "-"
	var skill_names: Array[String] = []
	for uid in skill_uids:
		skill_names.append(BloodBowlManager.get_skill_name(uid))
	return ", ".join(skill_names)
