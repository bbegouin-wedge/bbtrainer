extends CanvasLayer

@onready var _icon: TextureRect = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/icon/TextureRect
@onready var _position_label: Label = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Panel2/MarginContainer/VBoxContainer/Label2
@onready var _mv: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/mouv
@onready var _ag: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/Ag
@onready var _st: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/St
@onready var _pa: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/Pa
@onready var _av: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/Av


func _ready() -> void:
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.unit_deselected.connect(_on_unit_deselected)


func _on_unit_selected(unit: Node) -> void:
	visible = true
	var player := (unit as Unit).get_player()
	if player == null:
		return
	_icon.texture = player.get_blue_icon_texture()
	_position_label.text = player.position_name
	_mv.set_value(str(player.MA))
	_st.set_value(str(player.ST))
	_ag.set_value(str(player.AG) + "+")
	_pa.set_value(str(player.PA) + "+")
	_av.set_value(str(player.AV) + "+")


func _on_unit_deselected() -> void:
	visible = false
