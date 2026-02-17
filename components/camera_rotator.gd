class_name CameraRotator
extends Node2D

@export var target: Node2D  # L'Arena à faire tourner

var _terrain_center: Vector2

func _ready():
	_terrain_center = _compute_terrain_center()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("toggle_pitch_orientation"):
		_rotate_around_center(PI / 2)

func _rotate_around_center(angle: float) -> void:
	var pivot_global = target.to_global(_terrain_center)
	target.rotation += angle
	var new_pivot_global = target.to_global(_terrain_center)
	target.global_position += pivot_global - new_pivot_global
	_counter_rotate_units(-angle)

func _counter_rotate_units(angle: float) -> void:
	for child in target.get_children():
		if child is Unit:
			child.skin.rotation += angle
			if child.skill_icon_container:
				child.skill_icon_container.rotation += angle

func _compute_terrain_center() -> Vector2:
	var terrain: TileMapLayer = target.get_node("visuals/terrain")
	var rect = terrain.get_used_rect()
	var ts = Vector2(terrain.tile_set.tile_size)
	var center_in_terrain = Vector2(
		(rect.position.x + rect.size.x / 2.0) * ts.x,
		(rect.position.y + rect.size.y / 2.0) * ts.y
	)
	return target.to_local(terrain.to_global(center_in_terrain))
