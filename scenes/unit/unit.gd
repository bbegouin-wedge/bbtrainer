class_name Unit
extends Area2D

const SKILL_ICON_SIZE := 40
const SKILL_ICONS_PATH := "res://assets/skills/"
const SKILL_FALLBACK_ICON := "res://assets/skills/OTHER.png"

@export var stats: UnitStats : set = set_stats
@onready var skin: Sprite2D = $skin
@onready var select: Node = $select
@onready var drag_and_drop: DragAndDrop = $drag_and_drop
@onready var hover: Node = $hover

var _player: BloodBowlData.Player
var skill_icon_container: Node2D

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
		return
	var tile_center := Vector2(105, 105)
	skill_icon_container = Node2D.new()
	skill_icon_container.position = tile_center
	add_child(skill_icon_container)
	for i in added_skills.size():
		var icon_sprite := Sprite2D.new()
		var texture := _load_skill_icon(added_skills[i])
		if texture == null:
			continue
		icon_sprite.texture = texture
		var scale_factor := SKILL_ICON_SIZE / float(texture.get_width())
		icon_sprite.scale = Vector2(scale_factor, scale_factor)
		# Position relative au centre de la tuile
		icon_sprite.position = Vector2(SKILL_ICON_SIZE * i + SKILL_ICON_SIZE / 2.0, SKILL_ICON_SIZE / 2.0) - tile_center
		skill_icon_container.add_child(icon_sprite)

func _load_skill_icon(skill_uid: String) -> Texture2D:
	var path := SKILL_ICONS_PATH + skill_uid + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return load(SKILL_FALLBACK_ICON)



func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		select.manage_click(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		EventBus.unit_right_clicked.emit(self)
		get_viewport().set_input_as_handled()


func _on_mouse_entered() -> void:
	hover.start_hover()


func _on_mouse_exited() -> void:
	hover.end_hover()
