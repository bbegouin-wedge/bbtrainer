class_name ColorDot
extends Control

## Pastille de couleur pleine, dessinée et anticrénelée.
##
## Un ColorRect donnerait un carré aux bords durs, qui accentue la sensation de
## pixelisation à côté d'un texte. Ici c'est un disque tracé, dans la même
## langue visuelle que les pastilles de compétences.

@export var color: Color = Color.WHITE : set = set_color
@export var radius: float = 5.0 : set = set_radius


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()


func set_color(value: Color) -> void:
	color = value
	queue_redraw()


func set_radius(value: float) -> void:
	radius = value
	_fit()
	queue_redraw()


func _fit() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)


func _draw() -> void:
	draw_circle(size * 0.5, radius, color, true, -1.0, true)
