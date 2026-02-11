extends Node2D

# Terrain dimensions
const TILE_SIZE := 210
const GRID_WIDTH := 26
const GRID_HEIGHT := 16
const TERRAIN_WIDTH := GRID_WIDTH * TILE_SIZE  # 5460
const TERRAIN_HEIGHT := GRID_HEIGHT * TILE_SIZE  # 3360

@export var grid_displayed = false
var grid_has_changed = false
var is_pitch_vertical = true
@onready var welcomeUi = get_node("WelcomeUI")
@onready var arena = get_node("Arena")
@onready var actionPanel = get_node("ActionPanel")
@onready var teamSetup = get_node("teamChooser")
@onready var camera = get_node("Camera2D")
@onready var playerRecruitment = get_node("teamCompositor")

func _ready():
	print("global game ready !!!")
	EventBus.game_phase_changed.connect(_on_state_changed)
	_on_state_changed(GameStatusManager.getCurrentStatus())

func _on_state_changed(new_status) -> void:
	match new_status:
		GameStatusManager.GameStatus.STARTING:
			_reactivate(welcomeUi)
			_deactivate(arena)
			_deactivate(actionPanel)
			_deactivate(teamSetup)
			_deactivate(playerRecruitment)
		GameStatusManager.GameStatus.CHOOSE_TEAM:
			_deactivate(welcomeUi)
			_deactivate(arena)
			_deactivate(actionPanel)
			_reactivate(teamSetup)
			_deactivate(playerRecruitment)
		GameStatusManager.GameStatus.RECRUIT_PLAYER:
			_deactivate(welcomeUi)
			_deactivate(arena)
			_deactivate(actionPanel)
			_deactivate(teamSetup)
			_reactivate(playerRecruitment)
		GameStatusManager.GameStatus.READY_TO_RUN:
			_deactivate(welcomeUi)
			_deactivate(teamSetup)
			_reactivate(arena)
			_reactivate(actionPanel)
			_setup_camera_for_arena()
			_deactivate(playerRecruitment)

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
	node.process_mode = Node.PROCESS_MODE_DISABLED

func _reactivate(node: Node):
	node.process_mode = Node.PROCESS_MODE_INHERIT
	node.show()

func _setup_camera_for_arena() -> void:
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate zoom to fit terrain in viewport
	var zoom_x = viewport_size.x / TERRAIN_WIDTH
	var zoom_y = viewport_size.y / TERRAIN_HEIGHT
	var zoom_level = min(zoom_x, zoom_y)

	camera.zoom = Vector2(zoom_level, zoom_level)

	# Center camera on terrain
	camera.position = Vector2(TERRAIN_WIDTH / 2.0, TERRAIN_HEIGHT / 2.0)          
	
	
	
