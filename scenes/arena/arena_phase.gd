extends Node2D

const TILE_SIZE := 210
const GRID_WIDTH := 26
const GRID_HEIGHT := 16
const TERRAIN_WIDTH := GRID_WIDTH * TILE_SIZE
const TERRAIN_HEIGHT := GRID_HEIGHT * TILE_SIZE

const TERRAIN_LIMIT_LEFT := -979
const TERRAIN_LIMIT_TOP := -954
const TERRAIN_LIMIT_RIGHT := 6437
const TERRAIN_LIMIT_BOTTOM := 4094

@export var grid_displayed := false

@onready var camera: Camera2D = $Camera2D
@onready var arena: Arena = $Arena

func _ready() -> void:
	_setup_camera_for_arena()

func _process(_delta: float) -> void:
	var grid := arena.get_node("grid") as TileMapLayer
	grid.visible = grid_displayed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		GuiState.clear_selection()
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_grid"):
		grid_displayed = !grid_displayed
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		var win_size := DisplayServer.window_get_size()
		DisplayServer.window_set_size(Vector2i(win_size.y, win_size.x))
		_setup_camera_for_arena()

func _setup_camera_for_arena() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var zoom_x := viewport_size.x / TERRAIN_WIDTH
	var zoom_y := viewport_size.y / TERRAIN_HEIGHT
	var zoom_level: float = min(zoom_x, zoom_y) * 0.8
	camera.zoom = Vector2(zoom_level, zoom_level)
	camera.position = viewport_size / (2.0 * zoom_level)

	camera.limit_left = TERRAIN_LIMIT_LEFT
	camera.limit_top = TERRAIN_LIMIT_TOP
	camera.limit_right = TERRAIN_LIMIT_RIGHT
	camera.limit_bottom = TERRAIN_LIMIT_BOTTOM
