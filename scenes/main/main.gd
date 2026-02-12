extends Node2D

# Terrain dimensions
const TILE_SIZE := 210
const GRID_WIDTH := 26
const GRID_HEIGHT := 16
const TERRAIN_WIDTH := GRID_WIDTH * TILE_SIZE  # 5460
const TERRAIN_HEIGHT := GRID_HEIGHT * TILE_SIZE  # 3360

@export var grid_displayed = false
var is_pitch_vertical = true

@onready var welcomeUi = get_node("WelcomeUI")
@onready var arena = get_node("Arena")
@onready var actionPanel = get_node("ActionPanel")
@onready var teamSetup = get_node("teamChooser")
@onready var camera = get_node("Camera2D")
@onready var playerRecruitment = get_node("teamCompositor")
@onready var inducements = get_node("inducements")

func _ready():
	SceneOrchestrator.register_scene(SceneOrchestrator.Scene.WELCOME, welcomeUi)
	SceneOrchestrator.register_scene(SceneOrchestrator.Scene.TEAM_CHOOSER, teamSetup)
	SceneOrchestrator.register_scene(SceneOrchestrator.Scene.TEAM_COMPOSITOR, playerRecruitment)
	SceneOrchestrator.register_scene(SceneOrchestrator.Scene.INDUCEMENT_SELECTOR, inducements)
	SceneOrchestrator.register_scene(SceneOrchestrator.Scene.ARENA, arena)
	SceneOrchestrator.register_scene(SceneOrchestrator.Scene.ARENA, actionPanel)

	EventBus.game_phase_changed.connect(_on_game_phase_changed)
	SceneOrchestrator.go_to(SceneOrchestrator.Scene.WELCOME)

func _on_game_phase_changed(new_phase) -> void:
	if new_phase == GameStatusManager.GameStatus.READY_TO_RUN:
		_setup_camera_for_arena()

func _process(_delta: float) -> void:
	if grid_displayed:
		var grid = get_node("Arena/grid")
		grid.show()
	else:
		var grid = get_node("Arena/grid")
		grid.hide()

func toggle_grid() -> void:
	grid_displayed = !grid_displayed

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_grid"):
		toggle_grid()

func _setup_camera_for_arena() -> void:
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate zoom to fit terrain in viewport
	var zoom_x = viewport_size.x / TERRAIN_WIDTH
	var zoom_y = viewport_size.y / TERRAIN_HEIGHT
	var zoom_level = min(zoom_x, zoom_y)

	camera.zoom = Vector2(zoom_level, zoom_level)

	# Center camera on terrain
	camera.position = Vector2(TERRAIN_WIDTH / 2.0, TERRAIN_HEIGHT / 2.0)
