extends Node

## Signale le survol de l'unité. L'apparence du contour est décidée par UnitOutline,
## qui arbitre entre survol et sélection.

@export var outline: UnitOutline


func start_hover() -> void:
	if outline:
		outline.set_hovered(true)


func end_hover() -> void:
	if outline:
		outline.set_hovered(false)
