extends Label

@onready var team_list = $"../../ScrollContainer/vertical_team_list"

func _ready():
	team_list.team_selected.connect(_on_team_selected)
	
func _on_team_selected(team: BloodBowlData.Team):
	text= team.name
