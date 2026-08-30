class_name CameraMover
extends Node2D
#
@export var target: Camera2D
@export var pan_speed: float = 1.0
@export var mouse_pan_enabled: bool = true
## Le clic droit reste le bouton de panoramique : tous les trackpads n'ont pas de
## bouton du milieu. Les collisions avec l'annulation de glisser et le panneau
## d'actions sont levées autrement — on ne panoramique pas pendant un glisser, et
## un clic droit qui a parcouru du chemin n'ouvre pas le panneau.
@export_enum("Droit:2", "Milieu:3") var pan_button: int = MOUSE_BUTTON_RIGHT
@export var use_edge_pan: bool = false

# Pan clavier
@export var keyboard_pan_enabled: bool = true
@export var keyboard_pan_speed: float = 500.0

# Zoom molette
@export var zoom_enabled: bool = true
@export var zoom_step: float = 0.1
@export var zoom_min: float = 0.2
@export var zoom_max: float = 2.0

var is_panning: bool = false
var pan_start_position: Vector2

func _input(event: InputEvent):
	if mouse_pan_enabled and event is InputEventMouseButton and event.button_index == pan_button:
		# Pendant le glisser d'une unité, le clic droit sert à annuler : il ne
		# doit pas déclencher un panoramique en même temps.
		is_panning = event.pressed and not _is_unit_being_dragged()
		if is_panning:
			pan_start_position = event.position

	if zoom_enabled and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom = target.zoom * (1.0 + zoom_step)
			target.zoom = new_zoom.clampf(zoom_min, zoom_max) * Vector2.ONE
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom = target.zoom * (1.0 - zoom_step)
			target.zoom = new_zoom.clampf(zoom_min, zoom_max) * Vector2.ONE

	if event is InputEventMouseMotion and is_panning:
			var delta = (event.position - pan_start_position)
			target.position -= delta / target.zoom
			pan_start_position = event.position

func _is_unit_being_dragged() -> bool:
	return get_tree().get_first_node_in_group("dragging") != null


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
