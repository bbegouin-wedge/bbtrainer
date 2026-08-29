class_name DugoutBox
extends PanelContainer

## Une boîte du dugout — réserves, K.O. ou blessés. C'est une vue sur MatchState :
## elle affiche les joueurs dont la localisation correspond à la sienne, et sert
## de cible de dépôt.

const COLUMNS := 4
const TITLE_FONT_SIZE := 14

signal item_drag_requested(item: DugoutItem)

@export var location: MatchState.Location = MatchState.Location.RESERVES
@export var team: MatchState.Team = MatchState.Team.BLUE
@export var accent: Color = Color("4a5568")

var _title: Label
var _items: GridContainer


func _ready() -> void:
	_build()
	MatchState.roster_changed.connect(refresh)
	refresh()


func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title.add_theme_color_override("font_color", accent.lightened(0.45))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_title)

	_items = GridContainer.new()
	_items.columns = COLUMNS
	_items.add_theme_constant_override("h_separation", 4)
	_items.add_theme_constant_override("v_separation", 4)
	_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_items)


func refresh() -> void:
	if _items == null:
		return
	for child in _items.get_children():
		child.queue_free()

	var entries := MatchState.get_entries_at(location, team)
	_title.text = "%s (%d)" % [MatchState.location_label(location), entries.size()]
	for entry in entries:
		var item := DugoutItem.new()
		_items.add_child(item)
		item.setup(entry)
		item.drag_requested.connect(_on_item_drag_requested)


## Vrai si ce point de l'écran tombe dans la boîte : c'est ce qui décide de
## l'acceptation d'un dépôt, quel que soit l'espace d'où vient l'unité.
func accepts_screen_point(point: Vector2) -> bool:
	return get_global_rect().has_point(point)


func _on_item_drag_requested(item: DugoutItem) -> void:
	item_drag_requested.emit(item)
