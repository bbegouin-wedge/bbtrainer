class_name StaffPanel
extends PanelContainer

## Le banc d'une équipe : relances, apothicaire, pom-pom girls, assistants.
##
## Même parti que les boîtes du dugout — c'est une vue sur MatchState, qui se
## rafraîchit sur signal. Une ligne dont l'équipe n'a pas le droit reste
## affichée mais grisée, avec sa raison : 4 équipes sur 30 n'ont pas droit à
## l'apothicaire, et le masquer ferait croire à un oubli.

const ROW_HEIGHT := 26
const ACCENT := Color("2f6b8a")
const STEP_SIZE := Vector2(22, 20)

@export var team: MatchState.Team = MatchState.Team.BLUE

var _rows: VBoxContainer
var _title: Label


func _ready() -> void:
	_build()
	MatchState.staff_changed.connect(refresh)
	MatchState.roster_changed.connect(refresh)
	refresh()


func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	add_child(column)

	_title = Label.new()
	_title.text = "Banc"
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", ACCENT.lightened(0.45))
	column.add_child(_title)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 2)
	column.add_child(_rows)


func refresh() -> void:
	if _rows == null:
		return
	for child in _rows.get_children():
		child.queue_free()
	for kind: MatchState.Staff in MatchState.STAFF_ORDER:
		_rows.add_child(_build_row(kind))


func _build_row(kind: MatchState.Staff) -> Control:
	var allowed := MatchState.is_staff_allowed(team, kind)
	var count := MatchState.get_staff(team, kind)

	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.add_theme_constant_override("separation", 4)
	if not allowed:
		row.tooltip_text = "Cette équipe n'y a pas droit"
		row.mouse_filter = Control.MOUSE_FILTER_STOP

	var label := Label.new()
	label.text = MatchState.staff_label(kind)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color",
		Color("e8e4d8") if allowed else Color(0.91, 0.89, 0.85, 0.3))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	row.add_child(_build_step(kind, -1, "−", allowed and count > 0))

	var value := Label.new()
	value.text = str(count) if allowed else "—"
	value.custom_minimum_size.x = 20
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color",
		Color("e8e4d8") if allowed else Color(0.91, 0.89, 0.85, 0.3))
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value)

	row.add_child(_build_step(kind, 1, "+", allowed and count < int(MatchState.STAFF_MAX[kind])))
	return row


## Les boutons se désactivent aux bornes plutôt que de refuser en silence.
func _build_step(kind: MatchState.Staff, delta: int, glyph: String, enabled: bool) -> Button:
	var button := Button.new()
	button.text = glyph
	button.custom_minimum_size = STEP_SIZE
	button.flat = true
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.91, 0.89, 0.85, 0.75))
	button.add_theme_color_override("font_disabled_color", Color(0.91, 0.89, 0.85, 0.18))
	if enabled:
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(1, 1, 1, 0.12)
		hover.set_corner_radius_all(2)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(func(): MatchState.add_staff(team, kind, delta))
	return button
