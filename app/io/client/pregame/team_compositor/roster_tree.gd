extends Tree

var tree: Tree

func _ready():
#	var team = BloodBowlManager.get_team("OLD_WORLD_ALLIANCE")
#	TeamState.select_team(team)
	_setup_tree()
	EventBus.team_selected.connect(_on_team_selected)
	
func _on_team_selected(team: BloodBowlData.Team):
	_populate_tree(team)

func _setup_tree():
	columns = 11
	column_titles_visible = true
	hide_root = true
	set_column_title(0, "Poste")
	set_column_title(1, "MA")
	set_column_title(2, "ST")
	set_column_title(3, "AG")
	set_column_title(4, "PA")
	set_column_title(5, "AV")
	set_column_title(6, "Compétences")
	set_column_title(7, "Coût")
	set_column_title(8, "+")
	set_column_title(9, "-")
	set_column_title(10, "nombre")
	
	# Largeurs des colonnes
	set_column_custom_minimum_width(0, 150)  # Poste
	set_column_custom_minimum_width(1, 50)   # MA
	set_column_custom_minimum_width(2, 50)   # ST
	set_column_custom_minimum_width(3, 50)   # AG
	set_column_custom_minimum_width(4, 50)   # PA
	set_column_custom_minimum_width(6, 250)  # Compétences

	# Colonnes boutons : fixes et étroites
	set_column_custom_minimum_width(8, 50)
	set_column_custom_minimum_width(9, 50)
	set_column_expand(8, false)
	set_column_expand(9, false)

	custom_minimum_size = Vector2(1200, 300)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func _populate_tree(team: BloodBowlData.Team):
	clear()
	var root = create_item()

	var buttonId = 0;
	for player in team.available_players:
		var item = create_item(root)
		item.set_text(0, player.position_name)
		item.set_text(1, str(player.MA))
		item.set_text(2, str(player.ST))
		item.set_text(3, str(player.AG) + "+")
		item.set_text(4, str(player.PA) + "+" if player.PA > 0 else "-")
		item.set_text(5, str(player.AV) + "+")
		item.set_text(6, _format_skills(player.skills))
		item.set_text(7, _format_cost(player.cost))
		item.set_text(10, "0")

		# Centrer les colonnes de stats
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)  # MA
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)  # ST
		item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)  # AG
		item.set_text_alignment(4, HORIZONTAL_ALIGNMENT_CENTER)  # PA
		item.set_text_alignment(5, HORIZONTAL_ALIGNMENT_CENTER)  # AV
		item.set_text_alignment(7, HORIZONTAL_ALIGNMENT_CENTER)  # Coût
		item.set_text_alignment(8, HORIZONTAL_ALIGNMENT_CENTER)  # Coût
		item.set_text_alignment(9, HORIZONTAL_ALIGNMENT_CENTER)  # Coût
		item.set_text_alignment(10, HORIZONTAL_ALIGNMENT_CENTER)  # Coût
		var butonIcon = preload("res://app/io/client/assets/ui/icons/plus.png")                                                                                                   
		item.add_button(8, butonIcon, buttonId)
		# Icône du joueur
		var butonIconMinus = preload("res://app/io/client/assets/ui/icons/minus.png")     
		item.add_button(9, butonIconMinus, buttonId)
		item.set_icon_max_width(8, 64)  # Limite la largeur pour cette cellule         
		
		var playerIcon = Icons.red(player)
		if playerIcon:
			item.set_icon(0, playerIcon)
			item.set_icon_max_width(0, 32)
		buttonId = buttonId + 1

func _format_cost(cost: int) -> String:
	if cost >= 1000:
		return str(cost / 1000) + "k"
	return str(cost)

func _format_skills(skill_uids: Array[String]) -> String:
	if skill_uids.size() == 0:
		return "-"
	var skill_names: Array[String] = []
	for uid in skill_uids:
		skill_names.append(BloodBowlManager.get_skill_name(uid))
	return ", ".join(skill_names)


func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	var player = TeamState.get_selected_team().get_player_by_index(id)
	if column == 8: 
		TeamState.recruit_player(player)
	if column == 9: 
		TeamState.fire_player(player)
		# Mettre à jour la colonne 10                                                                                                                        
		
	var count = TeamState.get_player_count(player)                                                                                                         
	item.set_text(10, str(count))     
