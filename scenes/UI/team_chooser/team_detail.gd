extends GridContainer

@onready var team_list = $"../team_list"

var tree: Tree

func _ready():
	team_list.team_selected.connect(_on_team_selected)
	_setup_tree()

func _setup_tree():
	tree = Tree.new()
	tree.columns = 8
	tree.column_titles_visible = true
	tree.hide_root = true
	tree.set_column_title(0, "Poste")
	tree.set_column_title(1, "MA")
	tree.set_column_title(2, "ST")
	tree.set_column_title(3, "AG")
	tree.set_column_title(4, "PA")
	tree.set_column_title(5, "AV")
	tree.set_column_title(6, "Compétences")
	tree.set_column_title(7, "Coût")

	# Largeurs des colonnes
	tree.set_column_custom_minimum_width(0, 150)  # Poste
	tree.set_column_custom_minimum_width(6, 200)  # Compétences

	tree.custom_minimum_size = Vector2(1200, 300)
	add_child(tree)

func _on_team_selected(team: BloodBowlData.Team):
	_populate_tree(team)

func _populate_tree(team: BloodBowlData.Team):
	tree.clear()
	var root = tree.create_item()

	for player in team.available_players:
		var item = tree.create_item(root)
		item.set_text(0, player.position_name)
		item.set_text(1, str(player.MA))
		item.set_text(2, str(player.ST))
		item.set_text(3, str(player.AG) + "+")
		item.set_text(4, str(player.PA) + "+" if player.PA > 0 else "-")
		item.set_text(5, str(player.AV) + "+")
		item.set_text(6, _format_skills(player.skills))
		item.set_text(7, _format_cost(player.cost))

		# Centrer les colonnes de stats
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)  # MA
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)  # ST
		item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)  # AG
		item.set_text_alignment(4, HORIZONTAL_ALIGNMENT_CENTER)  # PA
		item.set_text_alignment(5, HORIZONTAL_ALIGNMENT_CENTER)  # AV
		item.set_text_alignment(7, HORIZONTAL_ALIGNMENT_CENTER)  # Coût

		# Icône du joueur
		var icon = player.get_red_icon_texture()
		if icon:
			item.set_icon(0, icon)
			item.set_icon_max_width(0, 32)

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
