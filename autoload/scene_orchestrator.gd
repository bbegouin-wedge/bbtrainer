extends Node

enum Scene { WELCOME, TEAM_CHOOSER, TEAM_COMPOSITOR, INDUCEMENT_SELECTOR, ARENA }

const SCENE_ORDER := [
	Scene.WELCOME,
	Scene.TEAM_CHOOSER,
	Scene.TEAM_COMPOSITOR,
	Scene.INDUCEMENT_SELECTOR,
	Scene.ARENA,
]

var _current_scene: Scene = Scene.WELCOME
var _registered_scenes: Dictionary = {}  # Scene -> Array[Node]

func register_scene(scene_id: Scene, node: Node) -> void:
	if not _registered_scenes.has(scene_id):
		_registered_scenes[scene_id] = []
	_registered_scenes[scene_id].append(node)

func go_to(scene_id: Scene) -> void:
	_current_scene = scene_id
	_update_visibility()
	_emit_game_phase(scene_id)

func go_next() -> void:
	var idx := SCENE_ORDER.find(_current_scene)
	if idx < SCENE_ORDER.size() - 1:
		go_to(SCENE_ORDER[idx + 1])

func go_back() -> void:
	var idx := SCENE_ORDER.find(_current_scene)
	if idx > 0:
		go_to(SCENE_ORDER[idx - 1])

func get_current_scene() -> Scene:
	return _current_scene

func _update_visibility() -> void:
	for scene_id in _registered_scenes:
		var nodes: Array = _registered_scenes[scene_id]
		for node in nodes:
			if scene_id == _current_scene:
				_reactivate(node)
			else:
				_deactivate(node)

func _deactivate(node: Node) -> void:
	node.hide()
	node.process_mode = Node.PROCESS_MODE_DISABLED

func _reactivate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	node.show()

func _emit_game_phase(scene_id: Scene) -> void:
	var status := _get_game_status(scene_id)
	EventBus.game_phase_changed.emit(status)

func _get_game_status(scene_id: Scene) -> GameStatusManager.GameStatus:
	match scene_id:
		Scene.WELCOME:
			return GameStatusManager.GameStatus.STARTING
		Scene.TEAM_CHOOSER:
			return GameStatusManager.GameStatus.CHOOSE_TEAM
		Scene.TEAM_COMPOSITOR:
			return GameStatusManager.GameStatus.RECRUIT_PLAYER
		Scene.INDUCEMENT_SELECTOR:
			return GameStatusManager.GameStatus.SELECT_INDUCEMENTS
		Scene.ARENA:
			return GameStatusManager.GameStatus.READY_TO_RUN
	return GameStatusManager.GameStatus.STARTING
