extends Node2D

func _ready() -> void:
	# Deferred so that current_scene is set by the engine first
	SceneOrchestrator.call_deferred("go_to", SceneOrchestrator.Scene.WELCOME)
