@tool
extends Panel
class_name StatCartridge

@export var label_text: String
@export var stat_value: String

@onready var _label_text: Label = $ColorRect/VBoxContainer/ColorRect/MarginContainer/Label
@onready var _stat_text: Label = $ColorRect/VBoxContainer/ColorRect2/Value

func _ready() -> void:
	if label_text:
		_label_text.text = label_text
		_label_text.visible = true
	if stat_value:
		_stat_text.text = stat_value
		_stat_text.visible = true

func set_value(value: String) -> void:
	stat_value = value
	if _stat_text:
		_stat_text.text = value
