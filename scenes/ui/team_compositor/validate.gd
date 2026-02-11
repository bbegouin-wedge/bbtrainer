extends Button

func _on_button_up() -> void:
	EventBus.game_phase_changed.emit(GameStatusManager.GameStatus.READY_TO_RUN)
