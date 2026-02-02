extends Node

enum GameStatus { STARTING, TEAM_SETTINGS, GAME_SETUP, READY_TO_RUN }
signal onStateChanged(newStatus)

var currentState: GameStatus = GameStatus.STARTING;

func _ready():
	print("on ready game status manager")
	
func _changeStatus(newState: GameStatus) -> void:
	currentState = newState
	onStateChanged.emit(newState)
	
func getCurrentStatus() -> GameStatus:
	return currentState
	
func enterTeamSetup() -> void:
	_changeStatus(GameStatus.TEAM_SETTINGS)

func goToGame() -> void:
	_changeStatus(GameStatus.READY_TO_RUN)
	
func isGameStarting() -> bool:
	return currentState == GameStatus.STARTING
	
func isTeamSetup() -> bool:
	return currentState == GameStatus.TEAM_SETTINGS

func isGameReadyToRun() -> bool:
	return currentState == GameStatus.READY_TO_RUN
