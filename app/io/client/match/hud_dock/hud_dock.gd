class_name HudDock
extends Control

## Les commandes d'escamotage, regroupées en bas au centre.
##
## Fin et centré, il flotte au-dessus de la pelouse sans réserver de marge : le
## terrain passe de part et d'autre. C'est ce qui permet de le garder visible en
## permanence sans rogner le champ, contrairement à un bandeau pleine largeur.

const BUTTON_HEIGHT := 26

@export var arena_phase: ArenaPhase

var _row: HBoxContainer
var _buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.047, 0.106, 0.137, 0.92)
	style.border_color = Color("2b4450")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 2)
	panel.add_child(_row)


## Appelé par ArenaPhase, qui sait quels panneaux existent.
func populate(entries: Array) -> void:
	for child in _row.get_children():
		child.queue_free()
	_buttons.clear()

	for entry: Dictionary in entries:
		var button := Button.new()
		button.text = str(entry["label"])
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.y = BUTTON_HEIGHT
		button.pressed.connect(_on_pressed.bind(str(entry["key"])))
		_row.add_child(button)
		_buttons[entry["key"]] = button

	await get_tree().process_frame
	_recenter()
	refresh()


func _recenter() -> void:
	size = _row.get_combined_minimum_size() + Vector2(8, 8)
	custom_minimum_size = size
	position.x = (get_viewport_rect().size.x - size.x) * 0.5


## Un panneau déployé est mis en avant ; un panneau rentré s'efface.
func refresh() -> void:
	if arena_phase == null:
		return
	for key in _buttons:
		var shown: bool = arena_phase.is_panel_shown(str(key))
		var button: Button = _buttons[key]
		button.add_theme_color_override("font_color",
			Color("e8e4d8") if shown else Color(0.91, 0.89, 0.85, 0.45))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.14) if shown else Color(0, 0, 0, 0)
		style.set_corner_radius_all(2)
		style.set_content_margin_all(4)
		button.add_theme_stylebox_override("normal", style)


func _on_pressed(key: String) -> void:
	if arena_phase:
		arena_phase.toggle_panel(key)
		refresh()
