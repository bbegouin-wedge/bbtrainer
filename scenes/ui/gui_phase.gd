extends Node

@onready var _phases := {
	SceneOrchestrator.Scene.WELCOME: $WelcomeUI,
	SceneOrchestrator.Scene.TEAM_CHOOSER: $TeamChooser,
	SceneOrchestrator.Scene.TEAM_COMPOSITOR: $TeamCompositor,
	SceneOrchestrator.Scene.INDUCEMENT_SELECTOR: $InducementSelector,
}

func _ready() -> void:
	SceneOrchestrator.register_gui_phase(self)
	show_phase(SceneOrchestrator.get_current_scene())

func show_phase(scene_id: SceneOrchestrator.Scene) -> void:
	for id in _phases:
		_phases[id].visible = (id == scene_id)
