class_name PlayerActions
extends Control

## Panneau d'actions d'un joueur, appelé au clic gauche sur son jeton.
##
## Contextuel : il se pose à côté du joueur et se retourne quand celui-ci est
## près d'un bord. Il flotte, donc il ne réserve aucune marge de caméra —
## contrairement à un bandeau fixe, qui rognerait le terrain en permanence.

enum Action { MOVE, PASS, FOUL, SECURE_BALL, HAND_OFF }

## `blocked_by` nomme le prérequis manquant. Une action grisée qui dit pourquoi
## vaut mieux qu'un bouton qui ne fait rien sans l'avouer.
const ACTIONS := [
	{ "id": Action.MOVE, "label": "Mouvement", "color": Color("4fa96b"), "blocked_by": "" },
	{ "id": Action.PASS, "label": "Passe", "color": Color("1d4e89"),
		"blocked_by": "aucune balle sur le terrain" },
	{ "id": Action.FOUL, "label": "Faute", "color": Color("9b2226"),
		"blocked_by": "aucune équipe adverse" },
	{ "id": Action.SECURE_BALL, "label": "Sécuriser la balle", "color": Color("8a5a00"),
		"blocked_by": "aucune balle sur le terrain" },
	{ "id": Action.HAND_OFF, "label": "Transmission", "color": Color("5b21b6"),
		"blocked_by": "aucune balle sur le terrain" },
]

## Le thème ne définit rien pour un Button simple : ces lignes tombaient sur la
## police de secours de Godot à sa taille par défaut. On impose donc une des
## polices du projet, dont les réglages d'import portent l'anticrénelage et le
## positionnement sous-pixel, à une taille lisible.
const FONT_PATH := "res://assets/fonts/Oregano-Regular.ttf"
const FONT_SIZE := 20
const ROW_HEIGHT := 34
const GLYPH_RADIUS := 5.0
## Écart entre la pastille et son libellé, et marge latérale de la ligne.
const GLYPH_GAP := 10
const ROW_PADDING := 10

const TEXT_COLOR := Color(0.91, 0.89, 0.85, 0.80)
const TEXT_HOVER := Color("e8e4d8")
const TEXT_DISABLED := Color(0.91, 0.89, 0.85, 0.28)

@export var arena_phase: ArenaPhase

var _unit: Node = null
var _rows: VBoxContainer
## Placement et apparition sont délégués : la fiche de joueur fait exactement
## la même chose.
var _contextual: ContextualPanel
var _font: Font


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	await get_tree().process_frame
	size = _rows.get_combined_minimum_size() + Vector2(14, 14)
	custom_minimum_size = size
	_contextual = ContextualPanel.attach(self, self, arena_phase)
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
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	panel.add_child(_rows)

	for action: Dictionary in ACTIONS:
		_rows.add_child(_build_row(action))


func _build_row(action: Dictionary) -> Button:
	var blocked := str(action["blocked_by"]) != ""

	# Le contenu est ancré dans le bouton, pas empilé dedans : sa taille minimale
	# ne compte donc pas le libellé, il faut la calculer.
	var font := _label_font()
	var text_width := font.get_string_size(
		str(action["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x

	var button := Button.new()
	button.custom_minimum_size = Vector2(
		ROW_PADDING * 2.0 + GLYPH_RADIUS * 2.0 + GLYPH_GAP + text_width, ROW_HEIGHT)
	button.flat = true
	button.disabled = blocked
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Indisponible : " + str(action["blocked_by"]) if blocked else ""
	if not blocked:
		button.add_theme_stylebox_override("hover", _hover_style())
		button.add_theme_stylebox_override("pressed", _hover_style())
	button.pressed.connect(_on_action_pressed.bind(action["id"]))

	# Pastille et libellé sont posés dans un HBox : l'ancienne version décalait
	# le texte par des espaces et posait la pastille en absolu par-dessus, d'où
	# les deux qui se touchaient.
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = ROW_PADDING
	row.offset_right = -ROW_PADDING
	row.add_theme_constant_override("separation", GLYPH_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)

	var dot := ColorDot.new()
	dot.radius = GLYPH_RADIUS
	dot.color = action["color"] if not blocked else Color(action["color"], 0.3)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)

	var label := Label.new()
	label.text = str(action["label"])
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", TEXT_DISABLED if blocked else TEXT_COLOR)
	row.add_child(label)

	# Le libellé étant un nœud à part, le survol du bouton ne le recolore pas
	# tout seul.
	if not blocked:
		button.mouse_entered.connect(
			func(): label.add_theme_color_override("font_color", TEXT_HOVER))
		button.mouse_exited.connect(
			func(): label.add_theme_color_override("font_color", TEXT_COLOR))
	return button


## Police du projet plutôt que celle de secours : ses réglages d'import portent
## l'anticrénelage gris et le positionnement sous-pixel.
func _label_font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) as Font
	return _font


## Survol d'une ligne : le rollover doit être franc, le panneau est petit.
func _hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.11)
	style.set_corner_radius_all(2)
	return style


func _on_unit_selected(unit: Node) -> void:
	_unit = unit
	visible = true
	_contextual.show_near(unit)
	GuiState.set_pointer_mode(GuiState.PointerMode.CHOOSING_ACTION)


func _on_unit_deselected() -> void:
	_unit = null
	_close()


## L'action choisie, le panneau s'efface : il recouvrait justement les cases
## qu'on s'apprête à viser. L'unité reste sélectionnée.
func _on_action_pressed(action: Action) -> void:
	var unit := _unit
	_close()
	if unit:
		EventBus.player_action_requested.emit(action, unit)


func _close() -> void:
	visible = false
	_contextual.dismiss()
	if GuiState.get_pointer_mode() == GuiState.PointerMode.CHOOSING_ACTION:
		GuiState.set_pointer_mode(GuiState.PointerMode.BROWSE)
