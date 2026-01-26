extends Node

@export var sprite: Sprite2D 
@export var fade_duration: float = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.material.set_shader_parameter("width", 3.5)


func start_hover() -> void:
	var tween = create_tween()
	tween.tween_property(sprite.material, "shader_parameter/fade", 1.0, fade_duration)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_OUT)
	sprite.material.set_shader_parameter("width", 3.5)


func end_hover() -> void:
	var tween = create_tween()
	tween.tween_property(sprite.material, "shader_parameter/fade", 0.0, fade_duration)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN)
	sprite.material.set_shader_parameter("width", 0)
