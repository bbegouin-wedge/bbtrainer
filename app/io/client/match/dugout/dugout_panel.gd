class_name DugoutPanel
extends Control

## Le dugout d'une équipe, ancré au viewport : il ne bouge pas avec le terrain.
## Les trois boîtes ne sont pas des lieux du monde mais des états de joueur.

const BOX_ACCENTS := {
	MatchState.Location.RESERVES: Color("4a5568"),
	MatchState.Location.KO: Color("8a5a00"),
	MatchState.Location.INJURED: Color("9b2226"),
}

signal item_drag_requested(item: DugoutItem)

@export var team: MatchState.Team = MatchState.Team.BLUE

var boxes: Array[DugoutBox] = []


func _ready() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	for location: MatchState.Location in MatchState.DUGOUT_LOCATIONS:
		var box := DugoutBox.new()
		box.location = location
		box.team = team
		box.accent = BOX_ACCENTS.get(location, Color("4a5568"))
		box.size_flags_vertical = Control.SIZE_EXPAND_FILL \
			if location == MatchState.Location.RESERVES else Control.SIZE_SHRINK_BEGIN
		column.add_child(box)
		box.item_drag_requested.connect(func(item): item_drag_requested.emit(item))
		boxes.append(box)


## Boîte située sous ce point de l'écran, ou null. Sert aussi bien au dépôt d'une
## vignette du dugout qu'à celui d'une unité venue du terrain.
func box_at_screen_point(point: Vector2) -> DugoutBox:
	for box in boxes:
		if box.accepts_screen_point(point):
			return box
	return null
