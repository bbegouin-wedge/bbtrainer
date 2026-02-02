class_name CameraRotator
extends Node2D

@export var target: Node2D  # L'Arena à faire tourner

var is_panning: bool = false
var pan_start_position: Vector2

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("toggle_pitch_orientation"):
		print("Rotation avant: ", target.rotation)
		var terrain_center = Vector2(512, 384)
		target.position = terrain_center
		target.rotate(PI/2)
		print("Rotation après: ", target.rotation)
