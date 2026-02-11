extends Button

func _on_run_game_button_pressed() -> void:
#	GameStatusManager.enterPlayerRecruitment()
	EventBus.game_phase_changed.emit(GameStatusManager.GameStatus.RECRUIT_PLAYER)
