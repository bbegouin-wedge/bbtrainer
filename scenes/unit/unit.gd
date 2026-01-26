class_name Unit
extends Area2D

@export var stats: UnitStats : set = set_stats
@onready var skin: Sprite2D = $skin
@onready var select: Node = $select
@onready var drag_and_drop: DragAndDrop = $drag_and_drop
@onready var hover: Node = $hover


	
func set_stats(value: UnitStats) -> void: 
	stats = value
	if value == null:
		return
		
	if not is_node_ready():
		await ready
		


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		select.manage_click(event)


func _on_mouse_entered() -> void:
	hover.start_hover()


func _on_mouse_exited() -> void:
	hover.end_hover()
