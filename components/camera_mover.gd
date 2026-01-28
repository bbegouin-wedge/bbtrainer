class_name CameraMover
extends Node2D
#
@export var target: Camera2D
@export var pan_speed: float = 1.0
@export var use_middle_mouse: bool = true
@export var use_edge_pan: bool = false

# Pan clavier
@export var keyboard_pan_enabled: bool = true
@export var keyboard_pan_speed: float = 500.0

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
			var delta = (event.position - pan_start_position)
			target.position -= delta / target.zoom
			pan_start_position = event.position

func _process(delta):
	# Pan clavier (diagonal supporté)
	if keyboard_pan_enabled:
		keyboard_pan(delta)
	
	# Pan avec les bords de l'écran (optionnel)
	if use_edge_pan:
		edge_pan(delta)

func keyboard_pan(delta: float):
	var pan_direction = Vector2.ZERO
	
	# Capturer les 4 directions
	if Input.is_action_pressed("ui_left"):
		pan_direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		pan_direction.x += 1
	if Input.is_action_pressed("ui_up"):
		pan_direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		pan_direction.y += 1
	
	# Normaliser pour vitesse constante en diagonal
	if pan_direction.length() > 0:
		pan_direction = pan_direction.normalized()
		target.position += pan_direction * keyboard_pan_speed * delta / target.zoom.x

func edge_pan(delta: float):
	var edge_margin = 20  # pixels depuis le bord
	var edge_speed = 500.0
	
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size
	
	var pan_direction = Vector2.ZERO
	
	#
