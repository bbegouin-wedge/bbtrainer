extends Node2D

enum GameMode {
	WELCOME,
	SETUP,
	PLAYING,
	ENDGAME
}

signal show_config_dialog
@export var current_game_mode = GameMode.WELCOME
@export var grid_displayed = false
var grid_has_changed = false
var is_pitch_vertical = true


func _process(delta: float) -> void:
	# print_tree()
	if current_game_mode == GameMode.WELCOME:
		var ui = get_node("WelcomeUI")
		var arena = get_node("Arena")
		ui.show()
		arena.hide()
	if current_game_mode == GameMode.SETUP:
		var arena = get_node("Arena")
		var ui = get_node("WelcomeUI")
		ui.hide()
		arena.show()
	if grid_displayed:
		var grid = get_node("Arena/grid")
		grid.show()
	if grid_displayed == false:
		var grid = get_node("Arena/grid")
		grid.hide()

func toggle_grid() -> void:
	print("grid has changed")
	grid_displayed = !grid_displayed

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		handle_escape()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_grid"):
		toggle_grid()

func handle_escape():
	if current_game_mode == GameMode.WELCOME:
		current_game_mode = GameMode.SETUP
		return
	if current_game_mode == GameMode.SETUP:
		current_game_mode = GameMode.WELCOME
		return
