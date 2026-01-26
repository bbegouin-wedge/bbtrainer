class_name CameraRotator
extends Node2D

@export var target: Camera2D

var is_panning: bool = false
var pan_start_position: Vector2

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("toggle_pitch_orientation"):
		target.rotate(PI)
