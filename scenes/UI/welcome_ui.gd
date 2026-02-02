extends CanvasLayer

@onready var ui_root: Control = $Control
@export var uiEvents: WelcomUIEvents
enum WelcomeUIStatus { START, JOIN_ROOM, CREATE_ROOM }
var currentStatus: WelcomeUIStatus = WelcomeUIStatus.START

func _ready():
	currentStatus = WelcomeUIStatus.START
	uiEvents.goCreateRoom.connect(_onActivateCreateRoom)
	uiEvents.goJoinRoom.connect(_onActivateJoinRoom)
	uiEvents.goWelcome.connect(_onActivateWelcomeScreen)
	_onActivateWelcomeScreen()
	
func _onActivateJoinRoom():
	currentStatus = WelcomeUIStatus.JOIN_ROOM

func _onActivateCreateRoom():
	currentStatus = WelcomeUIStatus.CREATE_ROOM
	var startContainer = get_node("Panel2/MarginContainer/HBoxContainer/VBoxContainer/StartContainer")
	startContainer.hide()
	var createRoomContainer = get_node("Panel2/MarginContainer/HBoxContainer/VBoxContainer/CreateRoomContainer")
	createRoomContainer.show()
	
func _onActivateWelcomeScreen():
	currentStatus = WelcomeUIStatus.START
	var startContainer = get_node("Panel2/MarginContainer/HBoxContainer/VBoxContainer/StartContainer")
	startContainer.show()
	var createRoomContainer = get_node("Panel2/MarginContainer/HBoxContainer/VBoxContainer/CreateRoomContainer")
	createRoomContainer.hide()

func _on_create_room_button_pressed() -> void:
	GameStatusManager.enterTeamSetup()
