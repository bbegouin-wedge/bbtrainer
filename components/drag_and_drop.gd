class_name DragAndDrop
extends Node

signal drag_canceled(starting_position: Vector2)
signal drag_started
signal dropped(starting_position: Vector2)

@export var enabled: bool = true
@export var target: Node2D
@export var ghost_alpha: float = 0.3  # Transparence du fantôme
@export var tilemap_layer: TileMapLayer

var starting_position: Vector2
var offset := Vector2.ZERO
var dragging := false
var ghost: Node2D = null  # Le fantôme qui reste à la position de départ

func _ready() -> void:
	assert(target, "No target set for DragAndDrop component")
	target.input_event.connect(_on_target_input_event.unbind(1))
	
func _process(_delta: float) -> void:
	if dragging and target:
		target.global_position = target.get_global_mouse_position() + offset

func _create_ghost() -> void:
	# Créer une copie du target comme fantôme
	ghost = target.duplicate()
	ghost.modulate.a = ghost_alpha
	
	# Désactiver les interactions avec le fantôme
	ghost.input_pickable = false
	if ghost.has_signal("input_event"):
		ghost.set_process_input(false)
	
	# Ajouter le fantôme à la même position dans le parent
	target.get_parent().add_child(ghost)
	ghost.global_position = starting_position
	ghost.z_index = target.z_index - 1  # Derrière l'objet draggé

func _remove_ghost() -> void:
	if ghost:
		ghost.queue_free()
		ghost = null
		
func _end_dragging() -> void: 
	dragging = false
	target.remove_from_group("dragging")
	target.z_index = 0
	_remove_ghost()
	
func _cancel_dragging() -> void: 
	_end_dragging()
	target.global_position = starting_position
	drag_canceled.emit(starting_position)
	
func _start_dragging() -> void: 
	dragging = true
	starting_position = target.global_position
	target.add_to_group("dragging")
	target.z_index = 99
	offset = target.global_position - target.get_global_mouse_position()
	_create_ghost()  # Créer le fantôme au démarrage
	drag_started.emit()
	
func _drop() -> void:
	_end_dragging()
	dropped.emit(starting_position)
	
	
func _on_target_input_event(_viewport: Node, event: InputEvent) -> void:
	if not enabled: 
		return 
		
	var dragging_object := get_tree().get_first_node_in_group("dragging")
	
	if not dragging and dragging_object:
		return
		
	if dragging and event.is_action_pressed("cancel_drag"):
		_cancel_dragging()
		#get_viewport().set_input_as_handled()
		
	elif not dragging and event.is_action_pressed("select"):
		_start_dragging()
		#get_viewport().set_input_as_handled()
	elif dragging and event.is_action_released("select"):
		_drop()
		#get_viewport().set_input_as_handled()
