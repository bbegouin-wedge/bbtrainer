extends Node


var _selectedTeam : BloodBowlData.Team = null;
var _team_composition: Dictionary = {}

func selectTeam(selectedTeam: BloodBowlData.Team) -> void: 
	_selectedTeam = selectedTeam
	_team_composition = {}
	for player in _selectedTeam.available_players:
		_team_composition[player] = 0
	EventBus.team_selected.emit(_selectedTeam)
	
func getSelectedTeam() -> BloodBowlData.Team:
	return _selectedTeam
	
func recruitPlayer(recruit: BloodBowlData.Player) -> void:
	if recruit not in _team_composition.keys(): 
		_team_composition[recruit] = 0;
	_team_composition[recruit] = _team_composition[recruit] + 1;

func firePlayer(recruit: BloodBowlData.Player) -> void:
	if _team_composition[recruit] == 0:
		return
	_team_composition[recruit] = _team_composition[recruit] - 1;

func getPlayerCount(ofType: BloodBowlData.Player) -> int:
	return _team_composition[ofType]

func get_composition() -> Dictionary:
	return _team_composition
