class_name Arena
extends Node2D

## Le terrain, et lui seul, vit dans le monde mobile. Les réserves, K.O. et
## blessés sont des états tenus par MatchState et affichés par le dugout, ancré
## au viewport — d'où l'absence de toute notion de réserve ici.

const UNIT_SCENE = preload("res://app/io/client/world/unit/unit.tscn")

@onready var play_area: UnitZone = $PlayArea

## Renseignées par ArenaPhase : le terrain doit pouvoir renvoyer une unité au dugout.
var dugouts: Array[DugoutPanel] = []

@onready var _drop_zones: Array[UnitZone] = [play_area]


func _ready() -> void:
	play_area.attach_grid(UnitGrid.create(Pitch.SIZE))
	EventBus.game_phase_changed.connect(_on_game_phase_changed)


func _on_game_phase_changed(new_phase: SceneOrchestrator.GameStatus) -> void:
	if new_phase == SceneOrchestrator.GameStatus.READY_TO_RUN:
		_start_match()


## Le terrain démarre vide : c'est au coach de placer son équipe depuis le dugout.
func _start_match() -> void:
	_clear_pitch()
	MatchState.build_from_team_state()


func _clear_pitch() -> void:
	for entry in MatchState.get_entries():
		remove_entry_from_pitch(entry)
	play_area.unit_grid.clear()


## Pose le joueur sur la case actuellement survolée. Renvoie faux si elle est hors
## terrain ou déjà prise — auquel cas rien ne bouge.
func place_entry_on_hovered_tile(entry: MatchState.Entry) -> bool:
	return place_entry_on_pitch(entry, play_area.get_hovered_tile())


func place_entry_on_pitch(entry: MatchState.Entry, tile: Vector2i) -> bool:
	if entry == null or not play_area.is_tile_in_bounds(tile):
		return false
	if not play_area.is_tile_free_for(tile, entry.unit):
		return false

	if entry.unit == null:
		entry.unit = _create_unit(entry)
	entry.unit.position = to_local(play_area.get_global_top_left_of_tile(tile))
	play_area.unit_grid.place_unit(tile, entry.unit)
	MatchState.set_location(entry, MatchState.Location.PITCH)
	return true


func remove_entry_from_pitch(entry: MatchState.Entry) -> void:
	if entry == null or entry.unit == null:
		return
	play_area.unit_grid.remove_unit(entry.unit)
	entry.unit.queue_free()
	entry.unit = null


func _create_unit(entry: MatchState.Entry) -> Unit:
	var unit: Unit = UNIT_SCENE.instantiate()
	add_child(unit)
	# L'arène peut déjà être pivotée : le jeton doit naître droit.
	unit.keep_visuals_upright()
	unit.drag_and_drop.drop_zones = _drop_zones
	unit.drag_and_drop.dugouts = dugouts
	unit.drag_and_drop.dropped_in_dugout.connect(_on_unit_dropped_in_dugout.bind(unit))

	var player := entry.get_player()
	if player:
		unit.skin.texture = player.get_blue_icon_texture()
		unit.set_player(player)
	else:
		unit.skin.texture = entry.get_icon()
	return unit


## Une unité lâchée sur le dugout quitte le terrain et prend l'état de la boîte.
func _on_unit_dropped_in_dugout(box: DugoutBox, unit: Unit) -> void:
	var entry := MatchState.get_entry_for_unit(unit)
	if entry == null or box.team != entry.team:
		return
	remove_entry_from_pitch(entry)
	MatchState.set_location(entry, box.location)
