extends CanvasLayer

@onready var player_action_panel: VBoxContainer = $VBoxContainer2

func _ready() -> void:
	player_action_panel.visible = false
	EventBus.unit_right_clicked.connect(_on_unit_right_clicked)

func _on_unit_right_clicked(_unit: Node) -> void:
	player_action_panel.visible = not player_action_panel.visible
