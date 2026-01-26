class_name CameraMover
extends Node2D

@export var target: Camera2D
@export var pan_speed: float = 1.0
@export var use_middle_mouse: bool = true
@export var use_edge_pan: bool = false

var is_panning: bool = false
var pan_start_position: Vector2

func _input(event: InputEvent):
	# Pan avec clic du milieu (molette)
	if use_middle_mouse:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.pressed:
					is_panning = true
					pan_start_position = event.position
				else:
					is_panning = false
		
		if event is InputEventMouseMotion and is_panning:
			var delta = (event.position - pan_start_position) * pan_speed
			target.position -= delta / target.zoom
			pan_start_position = event.position

func _process(delta):
	# Pan avec les bords de l'écran (optionnel)
	if use_edge_pan:
		edge_pan(delta)

func edge_pan(delta: float):
	var edge_margin = 20  # pixels depuis le bord
	var edge_speed = 500.0
	
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	
	var pan_direction = Vector2.ZERO
	
	if mouse_pos.x < edge_margin:
		pan_direction.x -= 1
	elif mouse_pos.x > viewport_size.x - edge_margin:
		pan_direction.x += 1
