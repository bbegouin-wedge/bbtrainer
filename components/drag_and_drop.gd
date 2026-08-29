class_name DragAndDrop
extends Node

signal drag_canceled(starting_position: Vector2)
## L'unité a été lâchée sur une boîte du dugout : elle quitte le terrain.
signal dropped_in_dugout(box: DugoutBox)
signal drag_started
signal dropped(starting_position: Vector2)

@export var enabled: bool = true
@export var target: Node2D
@export var ghost_alpha: float = 0.3  # Transparence du fantôme
## Zones où l'unité peut être reposée, essayées dans l'ordre : terrain, réserves.
## Un dépôt hors de toutes ces zones ramène l'unité à son point de départ.
@export var drop_zones: Array[UnitZone] = []
## Dugout ancré au viewport. Un dépôt qui tombe dessus sort l'unité du terrain
## au lieu de la reposer sur une case — d'où l'examen en coordonnées écran.
@export var dugouts: Array[DugoutPanel] = []
## Nœud grossi pendant le glisser. On ne grossit pas l'unité entière : son origine
## est le coin de la tuile, elle s'étirerait vers le bas-droite au lieu de gonfler
## sur place. Le sprite, lui, grandit depuis son centre.
@export var scaled_node: Node2D
## Rapport de grossissement, calé sur celui de la vignette venue du dugout.
@export var drag_scale: float = 1.35
@export var drag_scale_duration: float = 0.12

var starting_position: Vector2
var offset := Vector2.ZERO
var dragging := false
var ghost: Node2D = null  # Le fantôme qui reste à la position de départ

var _rest_scale := Vector2.ONE
var _scale_tween: Tween

func _ready() -> void:
	assert(target, "No target set for DragAndDrop component")
	target.input_event.connect(_on_target_input_event.unbind(1))
	if scaled_node:
		_rest_scale = scaled_node.scale
	
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
	GuiState.release_pointer_mode(GuiState.PointerMode.DRAGGING)
	_tween_scale(1.0)
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
	# Même geste que depuis le dugout : on vise une case de destination.
	GuiState.set_pointer_mode(GuiState.PointerMode.DRAGGING)
	target.z_index = 99
	offset = target.global_position - target.get_global_mouse_position()
	_create_ghost()  # Créer le fantôme avant le grossissement : il reste à taille réelle
	_tween_scale(drag_scale)
	drag_started.emit()
	
func _drop() -> void:
	var screen_point := target.get_viewport().get_mouse_position()
	for dugout in dugouts:
		if dugout == null:
			continue
		var box := dugout.box_at_screen_point(screen_point)
		if box:
			_end_dragging()
			dropped_in_dugout.emit(box)
			return

	if drop_zones.is_empty():
		_end_dragging()
		dropped.emit(starting_position)
		return

	var zone := _zone_under_mouse()
	if zone == null:
		_cancel_dragging()
		return

	var tile := zone.get_hovered_tile()
	if not zone.is_tile_free_for(tile, target):
		_cancel_dragging()
		return

	_register_on(zone, tile)
	target.global_position = zone.get_global_top_left_of_tile(tile)
	_end_dragging()
	dropped.emit(starting_position)


func _zone_under_mouse() -> UnitZone:
	for zone in drop_zones:
		if zone and zone.is_tile_in_bounds(zone.get_hovered_tile()):
			return zone
	return null


## L'unité peut changer de zone (réserves vers terrain et retour) : on la retire
## des grilles des autres zones avant de l'inscrire dans la nouvelle.
func _register_on(zone: UnitZone, tile: Vector2i) -> void:
	for other in drop_zones:
		if other and other != zone and other.unit_grid:
			other.unit_grid.remove_unit(target)
	if zone.unit_grid:
		zone.unit_grid.place_unit(tile, target)
	
	
func _on_target_input_event(_viewport: Node, event: InputEvent) -> void:
	if not enabled:
		return

	var dragging_object := get_tree().get_first_node_in_group("dragging")

	if not dragging and dragging_object:
		return

	if dragging and event.is_action_pressed("cancel_drag"):
		_cancel_dragging()

	elif not dragging and event.is_action_pressed("select"):
		_start_dragging()

	elif dragging and event.is_action_released("select"):
		_drop()


func _tween_scale(factor: float) -> void:
	if scaled_node == null or not is_instance_valid(scaled_node):
		return
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(scaled_node, "scale", _rest_scale * factor, drag_scale_duration) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
