extends Node2D


@export var grid_displayed = false
var grid_has_changed = false
var is_pitch_vertical = true
@onready var welcomeUi = get_node("WelcomeUI")
@onready var arena = get_node("Arena")
@onready var actionPanel = get_node("ActionPanel")
@onready var teamSetup = get_node("teamChooser")

func _ready():
	print("global game ready !!!")
	GameStatusManager.onStateChanged.connect(_on_state_changed)
	_on_state_changed(GameStatusManager.getCurrentStatus())

func _on_state_changed(new_status) -> void:
	match new_status:
		GameStatusManager.GameStatus.STARTING:
			_reactivate(welcomeUi)
			_deactivate(arena)
			_deactivate(actionPanel)
			_deactivate(teamSetup)
		GameStatusManager.GameStatus.TEAM_SETTINGS:
			_deactivate(welcomeUi)
			_deactivate(arena)
			_deactivate(actionPanel)
			_reactivate(teamSetup)
		GameStatusManager.GameStatus.READY_TO_RUN:
			_deactivate(welcomeUi)
			_deactivate(teamSetup)
			_reactivate(arena)
			_reactivate(actionPanel)


func _process(_delta: float) -> void:
	if grid_displayed:
		var grid = get_node("Arena/grid")
		grid.show()
	else:
		var grid = get_node("Arena/grid")
		grid.hide()

func toggle_grid() -> void:
	print("grid has changed")
	grid_displayed = !grid_displayed

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		#handle_escape()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_grid"):
		toggle_grid()

func handle_escape():
	if GameStatusManager.isGameStarting():
		return
	if GameStatusManager.isTeamSettingUp():
		return
		
func _deactivate(node: Node): 
	node.hide()
	#node.process_mode = Node.PROCESS_MODE_DISABLED       

func _reactivate(node: Node):
	node.show()                                                                                         
	#node.process_mode = Node.PROCESS_MODE_INHERIT  # ou PROCESS_MODE_ALWAYS          
	
	
	
