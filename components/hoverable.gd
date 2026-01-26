extends Node

@export var sprite: Sprite2D 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.material.set_shader_parameter("width", 0)


func start_hover() -> void:
	sprite.material.set_shader_parameter("width", 3)
	print("Pièce sélectionnée: ", sprite.name)

func end_hover() -> void:
	sprite.material.set_shader_parameter("width", 0)
	print("Pièce désélectionnée: ", sprite.name)
