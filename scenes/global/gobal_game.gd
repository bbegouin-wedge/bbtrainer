extends Node2D

enum GameMode {
	WELCOME,
	SETUP,
	PLAYING,
	ENDGAME
}

signal show_config_dialog

@export var current_game_mode = GameMode.WELCOME


func _process(delta: float) -> void:
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
		
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		handle_escape()
		get_viewport().set_input_as_handled()

func handle_escape():
	print("ESC pressé")
	if current_game_mode == GameMode.WELCOME:
		current_game_mode = GameMode.SETUP
		return
	if current_game_mode == GameMode.SETUP:
		current_game_mode = GameMode.WELCOME
		return
