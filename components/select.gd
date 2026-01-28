extends Node

@export var sprite: Sprite2D 

var is_selected := false
var mouse_down_position := Vector2.ZERO
var original_position := Vector2.ZERO
var SELECTION_THRESHOLD := 4.0 

func _ready() -> void:
	sprite.material.set_shader_parameter("width", 0)

func _toggle_selection() -> void:
	if is_selected:
		deselect()
		print("deselected")
	else:
		select()
		print("selected")
	
	get_viewport().set_input_as_handled()

func select() -> void:
	sprite.material.set_shader_parameter("width", 3)
	is_selected = true

func deselect() -> void:
	is_selected = false
	sprite.material.set_shader_parameter("width", 0)
	
func manage_click(event: InputEvent) -> void:
		if event.pressed:
			# Enregistrer la position du clic
			mouse_down_position = sprite.get_global_mouse_position()
			print("Mouse down à: ", mouse_down_position)
		else:
			# Calculer la distance parcourue
			var mouse_up_position = sprite.get_global_mouse_position()
			var distance = mouse_down_position.distance_to(mouse_up_position)  # CORRIGÉ
			
			print("Mouse up à: ", mouse_up_position)
			print("Distance parcourue: ", distance)
			
			# Si le mouvement est minimal, c'est un clic (pas un drag)
			if distance <= SELECTION_THRESHOLD: 
				_toggle_selection()
			else:
				print("Trop de mouvement, pas de sélection (drag détecté)")
	
