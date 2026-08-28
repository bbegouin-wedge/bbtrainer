class_name Unit
extends Area2D

const TILE_SIZE := 210.0
const SKILL_BADGE_RADIUS := 22.0
# Marge entre le bas de la tuile et la rangée de pastilles.
const SKILL_BADGE_MARGIN := 8.0

@export var stats: UnitStats : set = set_stats
@onready var skin: Sprite2D = $skin
@onready var select: Node = $select
@onready var drag_and_drop: DragAndDrop = $drag_and_drop
@onready var hover: Node = $hover

var _player: BloodBowlData.Player
var skill_badges: SkillBadgeRow

## Au-delà de ce trajet entre l'appui et le relâchement, le clic droit était un
## panoramique de caméra, pas un clic. Mesuré à l'écran : en coordonnées monde la
## caméra se déplace elle-même pendant le geste.
const RIGHT_CLICK_THRESHOLD := 4.0

## Le clic droit sert à trois choses selon le contexte — panoramique, annulation
## de glisser, ouverture du panneau d'actions. Ce drapeau n'autorise la troisième
## que si les deux autres n'ont pas eu lieu.
var _right_click_opens_panel := false
var _right_press_screen_position := Vector2.ZERO


func _ready() -> void:
	drag_and_drop.drag_canceled.connect(_on_drag_canceled)

func set_stats(value: UnitStats) -> void:
	stats = value
	if value == null:
		return
	if not is_node_ready():
		await ready

func get_player() -> BloodBowlData.Player:
	return _player

func set_player(player: BloodBowlData.Player) -> void:
	_player = player
	_display_added_skills()

func _display_added_skills() -> void:
	if _player == null:
		return

	var added_skills: Array[String] = []
	for uid in _player.skills:
		if uid not in _player.base_skills:
			added_skills.append(uid)

	if added_skills.is_empty():
		if skill_badges:
			skill_badges.set_skills([])
		return

	if skill_badges == null:
		skill_badges = SkillBadgeRow.new()
		skill_badges.radius = SKILL_BADGE_RADIUS
		skill_badges.max_width = TILE_SIZE
		skill_badges.position = Vector2(
			TILE_SIZE * 0.5,
			TILE_SIZE - SKILL_BADGE_RADIUS - SKILL_BADGE_MARGIN)
		add_child(skill_badges)

	skill_badges.set_skills(added_skills)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		select.manage_click(event)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click(event)


func _handle_right_click(event: InputEventMouseButton) -> void:
	if event.pressed:
		_right_click_opens_panel = true
		_right_press_screen_position = get_viewport().get_mouse_position()
		return
	if not _right_click_opens_panel:
		return
	_right_click_opens_panel = false
	var travelled := _right_press_screen_position.distance_to(get_viewport().get_mouse_position())
	if travelled > RIGHT_CLICK_THRESHOLD:
		return
	EventBus.unit_right_clicked.emit(self)
	get_viewport().set_input_as_handled()


func _on_drag_canceled(_starting_position: Vector2) -> void:
	_right_click_opens_panel = false


func _on_mouse_entered() -> void:
	hover.start_hover()


func _on_mouse_exited() -> void:
	hover.end_hover()
