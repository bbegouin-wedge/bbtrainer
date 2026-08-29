extends Node

## Sélection de l'unité au clic. L'apparence du contour est décidée par UnitOutline,
## qui arbitre entre survol et sélection.

## Au-delà de cette distance entre l'appui et le relâchement, le geste est un
## déplacement et non une sélection.
const SELECTION_THRESHOLD := 4.0

@export var sprite: Sprite2D
@export var outline: UnitOutline

var is_selected := false

var _mouse_down_position := Vector2.ZERO


func select() -> void:
	is_selected = true
	_refresh_outline()
	GuiState.set_selected_unit(get_parent())


func deselect() -> void:
	is_selected = false
	_refresh_outline()
	GuiState.clear_selection()


## Retire la sélection sans repasser par GuiState : appelé par GuiState lui-même
## quand une autre unité prend la main.
func force_deselect() -> void:
	is_selected = false
	_refresh_outline()


## Pendant symétrique : allume la sélection sans rappeler GuiState, qui est déjà
## en train de la poser. Sans lui, une sélection venue d'ailleurs que du clic —
## le bandeau de joueurs, par exemple — n'allumerait aucun contour.
func force_select() -> void:
	is_selected = true
	_refresh_outline()


func manage_click(event: InputEvent) -> void:
	if event.pressed:
		_mouse_down_position = sprite.get_global_mouse_position()
		return

	var travelled := _mouse_down_position.distance_to(sprite.get_global_mouse_position())
	if travelled <= SELECTION_THRESHOLD:
		_toggle_selection()


func _toggle_selection() -> void:
	if is_selected:
		deselect()
	else:
		select()
	get_viewport().set_input_as_handled()


func _refresh_outline() -> void:
	if outline:
		outline.set_selected(is_selected)
