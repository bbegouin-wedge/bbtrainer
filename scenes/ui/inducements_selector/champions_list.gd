extends GridContainer

const SELECTED_COLOR := Color(0.9, 0.75, 0.2, 0.4)
const SELECTED_BORDER := Color(0.9, 0.75, 0.2, 0.8)
const HOVER_COLOR := Color(1, 1, 1, 0.15)

var selected_champions: Dictionary = {}  # uid -> bool

func _ready():
	columns = 8
	EventBus.team_selected.connect(_on_team_selected)

func _on_team_selected(team: BloodBowlData.Team):
	for child in get_children():
		child.queue_free()
	selected_champions.clear()
	var star_players: Array[BloodBowlData.StarPlayer] = BloodBowlManager.get_stars_for_team(team)
	for sp in star_players:
		var panel := ChampionItemFactory.create(sp)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.gui_input.connect(_on_item_input.bind(panel))
		panel.mouse_entered.connect(_on_item_hover.bind(panel, true))
		panel.mouse_exited.connect(_on_item_hover.bind(panel, false))
		add_child(panel)

func _on_item_input(event: InputEvent, panel: PanelContainer):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var uid: String = panel.get_meta("uid")
		if selected_champions.has(uid):
			selected_champions.erase(uid)
			TeamState.remove_star(BloodBowlManager.get_star_player(uid))
		else:
			selected_champions[uid] = true
			TeamState.add_star(BloodBowlManager.get_star_player(uid))
		_update_panel_style(panel)

func _on_item_hover(panel: PanelContainer, hovered: bool):
	var uid: String = panel.get_meta("uid")
	if not selected_champions.has(uid):
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
		style.bg_color = HOVER_COLOR if hovered else Color.TRANSPARENT

func _update_panel_style(panel: PanelContainer):
	var uid: String = panel.get_meta("uid")
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
	var is_selected = selected_champions.has(uid)

	style.bg_color = SELECTED_COLOR if is_selected else Color.TRANSPARENT
	style.border_color = SELECTED_BORDER if is_selected else Color.TRANSPARENT
	var border = 2 if is_selected else 0
	style.border_width_bottom = border
	style.border_width_top = border
	style.border_width_left = border
	style.border_width_right = border
