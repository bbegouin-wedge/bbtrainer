extends Node

enum GameStatus { STARTING,
CHOOSE_TEAM,
RECRUIT_PLAYER,
SELECT_INDUCEMENTS,
SELECT_SKILLS,
READY_TO_RUN }
signal onStateChanged(newStatus)

var currentState: GameStatus = GameStatus.STARTING;

func _ready():
	EventBus.game_phase_changed.connect(_on_game_phase_changed)
	
func _on_game_phase_changed(new_phase) -> void:
	currentState = new_phase
	
func _changeStatus(newState: GameStatus) -> void:
	currentState = newState
	onStateChanged.emit(newState)
	
func getCurrentStatus() -> GameStatus:
	return currentState
