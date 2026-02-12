extends CanvasLayer

enum WelcomeUIStatus { START, JOIN_ROOM, CREATE_ROOM }
var currentStatus: WelcomeUIStatus = WelcomeUIStatus.START

func _ready():
	currentStatus = WelcomeUIStatus.START
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

func _onCreateRoomPressed():
	SceneOrchestrator.go_next()
