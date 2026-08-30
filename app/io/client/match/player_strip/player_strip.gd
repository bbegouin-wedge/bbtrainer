class_name PlayerStrip
extends Control

## Bandeau des joueurs présents sur le terrain, en bas au centre.
##
## Il sert de raccourci : cliquer une carte sélectionne le joueur et recentre la
## caméra dessus — le joueur peut être hors champ, c'est tout l'intérêt. Les
## remplaçants n'y figurent pas, ils vivent dans les dugouts.

const CARD_SIZE := Vector2(58, 78)
const CARD_GAP := 4
const STATE_BAR := 8

const CONDITION_COLORS := {
	MatchState.Condition.READY: Color("4fa96b"),
	MatchState.Condition.PLAYED: Color("6b7280"),
	MatchState.Condition.PRONE: Color("c98a1e"),
	MatchState.Condition.STUNNED: Color("b5442f"),
}

@export var arena_phase: ArenaPhase
@export var team: MatchState.Team = MatchState.Team.BLUE

var _cards: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()
	MatchState.roster_changed.connect(refresh)
	EventBus.unit_selected.connect(_on_selection_changed.unbind(1))
	EventBus.unit_deselected.connect(_on_selection_changed)
	refresh()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.047, 0.106, 0.137, 0.92)
	style.border_color = Color("2b4450")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", CARD_GAP)
	panel.add_child(_cards)


func refresh() -> void:
	if _cards == null:
		return
	for child in _cards.get_children():
		child.queue_free()

	var entries := MatchState.get_entries_at(MatchState.Location.PITCH, team)
	for entry in entries:
		_cards.add_child(_build_card(entry))

	# Le bandeau se dimensionne sur son contenu et reste centré en bas.
	var count := entries.size()
	var width := maxf(CARD_SIZE.x, count * CARD_SIZE.x + maxi(0, count - 1) * CARD_GAP) + 10.0
	custom_minimum_size = Vector2(width, CARD_SIZE.y + 10.0)
	size = custom_minimum_size
	visible = count > 0
	_recenter()


func _recenter() -> void:
	var viewport := get_viewport_rect().size
	position.x = (viewport.x - size.x) * 0.5


func _build_card(entry: MatchState.Entry) -> Control:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.flat = true
	card.focus_mode = Control.FOCUS_NONE
	card.tooltip_text = "%d — %s · %s" % [
		entry.number, entry.get_display_name(), MatchState.condition_label(entry.condition)]
	card.pressed.connect(_on_card_pressed.bind(entry))

	var selected := GuiState.get_selected_unit() == entry.unit
	var background := StyleBoxFlat.new()
	background.bg_color = Color("1d4356") if selected else Color("14303c")
	background.border_color = Color("ffec9e") if selected else Color("24485a")
	background.set_border_width_all(1)
	background.set_corner_radius_all(3)
	card.add_theme_stylebox_override("normal", background)
	card.add_theme_stylebox_override("hover", background)
	card.add_theme_stylebox_override("pressed", background)

	# Liseré d'état en haut : c'est ce qui rend le bandeau utile d'un coup d'œil.
	var state_bar := ColorRect.new()
	state_bar.color = CONDITION_COLORS.get(entry.condition, Color("6b7280"))
	state_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	state_bar.offset_bottom = STATE_BAR
	card.add_child(state_bar)

	var icon := TextureRect.new()
	icon.texture = Icons.entry(entry)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_top = STATE_BAR + 1
	icon.offset_bottom = -16
	card.add_child(icon)

	var number := Label.new()
	number.text = str(entry.number)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.add_theme_font_size_override("font_size", 12)
	number.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	number.offset_top = -16
	card.add_child(number)

	return card


func _on_card_pressed(entry: MatchState.Entry) -> void:
	if entry.unit == null or not is_instance_valid(entry.unit):
		return
	GuiState.set_selected_unit(entry.unit)
	if arena_phase:
		# Le centre du jeton, pas le coin de sa tuile — et par to_global, pour
		# rester juste quand l'arène est pivotée.
		arena_phase.center_camera_on(
			entry.unit.to_global(Vector2(Unit.TILE_SIZE, Unit.TILE_SIZE) * 0.5))


func _on_selection_changed() -> void:
	refresh()
