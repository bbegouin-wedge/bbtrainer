@tool
extends Panel
class_name NoLabelButton


@export var event_signal: String
@export var button_icon: Texture2D

@onready var _icon: TextureRect = $VBoxContainer/Button/MarginContainer/TextureRect
@onready var _button: Button = $VBoxContainer/Button

func _ready() -> void:
	if button_icon:
		_icon.texture = button_icon
	_button.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("test pressed")
	if event_signal and EventBus.has_signal(event_signal):
		EventBus.emit_signal(event_signal)
