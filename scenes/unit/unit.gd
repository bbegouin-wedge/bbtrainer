class_name Unit
extends Area2D

@export var stats: UnitStats : set = set_stats

@onready var skin: Sprite2D = $skin

func set_stats(value: UnitStats) -> void: 
	stats = value
	if value == null:
		return
		
	if not is_node_ready():
		await ready
		
