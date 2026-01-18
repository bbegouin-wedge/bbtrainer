extends CanvasLayer

@onready var ui_root: Control = $Control

func _ready():
	# S'assurer que le Control prend tout l'écran
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
