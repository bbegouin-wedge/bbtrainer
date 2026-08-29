extends Node

enum Scene { WELCOME, TEAM_CHOOSER, TEAM_COMPOSITOR, INDUCEMENT_SELECTOR, SKILL_CHOOSER, ARENA }

const SCENE_ORDER := [
	Scene.WELCOME,
	Scene.TEAM_CHOOSER,
	Scene.TEAM_COMPOSITOR,
	Scene.INDUCEMENT_SELECTOR,
	Scene.SKILL_CHOOSER,
	Scene.ARENA,
]

const GUI_SCENES := [Scene.WELCOME, Scene.TEAM_CHOOSER, Scene.TEAM_COMPOSITOR, Scene.INDUCEMENT_SELECTOR, Scene.SKILL_CHOOSER]
const GUI_PHASE_PATH := "res://io/client/bootstrap/gui_phase.tscn"
const ARENA_PHASE_PATH := "res://io/client/world/arena_phase.tscn"

var _current_scene: Scene = Scene.WELCOME
var _gui_phase: Node = null

func register_gui_phase(node: Node) -> void:
	_gui_phase = node

func go_to(scene_id: Scene) -> void:
	_current_scene = scene_id
	if scene_id in GUI_SCENES:
		if _gui_phase and is_instance_valid(_gui_phase):
			_gui_phase.show_phase(scene_id)
		else:
			_full_swap(GUI_PHASE_PATH)
			# gui_phase._ready() will call register_gui_phase + show_phase
	else:
		_gui_phase = null
		_full_swap(ARENA_PHASE_PATH)
	call_deferred("_emit_game_phase", scene_id)

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

func _full_swap(scene_path: String) -> void:
	var old := get_tree().current_scene
	if old:
		old.queue_free()
	var packed := load(scene_path) as PackedScene
	var new_scene := packed.instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

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
		Scene.SKILL_CHOOSER:
			return GameStatusManager.GameStatus.SELECT_SKILLS
		Scene.ARENA:
			return GameStatusManager.GameStatus.READY_TO_RUN
	return GameStatusManager.GameStatus.STARTING
