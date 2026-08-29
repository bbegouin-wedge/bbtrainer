class_name PlayerActions
extends Control

## Panneau d'actions d'un joueur, appelé au clic gauche sur son jeton.
##
## Contextuel : il se pose à côté du joueur et se retourne quand celui-ci est
## près d'un bord. Il flotte, donc il ne réserve aucune marge de caméra —
## contrairement à un bandeau fixe, qui rognerait le terrain en permanence.

enum Action { MOVE, PASS, FOUL, SECURE_BALL, HAND_OFF }

const ACTIONS := [
	{ "id": Action.MOVE,        "label": "Mouvement",          "color": Color("4fa96b") },
	{ "id": Action.PASS,        "label": "Passe",              "color": Color("1d4e89") },
	{ "id": Action.FOUL,        "label": "Faute",              "color": Color("9b2226") },
	{ "id": Action.SECURE_BALL, "label": "Sécuriser la balle", "color": Color("8a5a00") },
	{ "id": Action.HAND_OFF,    "label": "Transmission",       "color": Color("5b21b6") },
]

## Écart entre le jeton et le panneau, et marge minimale aux bords de l'écran.
const GAP := 18.0
const SCREEN_MARGIN := 12.0
const GLYPH_SIZE := 10.0

@export var arena_phase: ArenaPhase

var _unit: Node = null
var _rows: VBoxContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	await get_tree().process_frame
	size = _rows.get_combined_minimum_size() + Vector2(8, 8)
	custom_minimum_size = size
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.unit_deselected.connect(_on_unit_deselected)
	# Consulter la fiche referme les actions : les deux panneaux se disputeraient
	# la même place à côté du jeton.
	EventBus.unit_right_clicked.connect(_on_unit_deselected.unbind(1))


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.047, 0.106, 0.137, 0.96)
	style.border_color = Color("2b4450")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(3)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 2)
	panel.add_child(_rows)

	for action: Dictionary in ACTIONS:
		_rows.add_child(_build_row(action))


func _build_row(action: Dictionary) -> Button:
	var button := Button.new()
	button.text = "   " + str(action["label"])
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", Color(0.91, 0.89, 0.85, 0.78))
	button.add_theme_color_override("font_hover_color", Color("e8e4d8"))
	button.pressed.connect(_on_action_pressed.bind(action["id"]))

	# Pastille de couleur, dessinée plutôt que texturée — même parti que les
	# pastilles de compétences.
	var glyph := ColorRect.new()
	glyph.color = action["color"]
	glyph.custom_minimum_size = Vector2(GLYPH_SIZE, GLYPH_SIZE)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	glyph.offset_left = 8.0
	glyph.offset_right = 8.0 + GLYPH_SIZE
	glyph.offset_top = -GLYPH_SIZE * 0.5
	glyph.offset_bottom = GLYPH_SIZE * 0.5
	button.add_child(glyph)
	return button


func _on_unit_selected(unit: Node) -> void:
	_unit = unit
	visible = true
	_place_near_unit()


func _on_unit_deselected() -> void:
	_unit = null
	visible = false


func _process(_delta: float) -> void:
	# La caméra peut bouger sous le panneau (panoramique, recentrage) : il doit
	# rester collé à son joueur.
	if visible and _unit:
		_place_near_unit()


func _place_near_unit() -> void:
	if arena_phase == null or _unit == null or not is_instance_valid(_unit):
		return
	var anchor := arena_phase.world_to_screen(_unit.global_position + _unit_center_offset())
	var viewport := get_viewport_rect().size
	var panel_size := size

	# On sort du côté opposé au bord le plus proche.
	var x := anchor.x + GAP
	if x + panel_size.x > viewport.x - SCREEN_MARGIN:
		x = anchor.x - GAP - panel_size.x
	var y := anchor.y - panel_size.y * 0.5
	position = Vector2(
		clampf(x, SCREEN_MARGIN, viewport.x - panel_size.x - SCREEN_MARGIN),
		clampf(y, SCREEN_MARGIN, viewport.y - panel_size.y - SCREEN_MARGIN))


func _unit_center_offset() -> Vector2:
	return Vector2(Unit.TILE_SIZE, Unit.TILE_SIZE) * 0.5


func _on_action_pressed(action: Action) -> void:
	if _unit:
		EventBus.player_action_requested.emit(action, _unit)
