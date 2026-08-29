class_name MovementRange
extends Node2D

## Portée de déplacement d'un joueur, dessinée sur la pelouse.
##
## L'information va sur le terrain plutôt que dans un panneau : c'est là qu'on
## la lit pour décider. Rien n'est texturé, tout est tracé — même parti que les
## pastilles de compétences et la minimap.

const REACHABLE_FILL := Color(0.29, 0.55, 0.85, 0.30)
const REACHABLE_EDGE := Color(0.66, 0.85, 1.0, 0.75)
const HOVERED_FILL := Color(0.55, 0.82, 1.0, 0.45)
const HOVERED_EDGE := Color(1, 1, 1, 0.9)
const EDGE_WIDTH := 2.0

## Déplacement en 8 directions, une case par pas — la diagonale ne coûte pas
## plus cher à Blood Bowl.
const NEIGHBOURS := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]
## Côtés orthogonaux, pour ne tracer que le pourtour de la zone.
const SIDES := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

@export var pitch: UnitZone
@export var arena: Arena

var _entry: MatchState.Entry = null
var _reachable: Dictionary = {}
var _hovered := Vector2i(-1, -1)


func _ready() -> void:
	set_process(false)
	EventBus.player_action_requested.connect(_on_action_requested)
	EventBus.unit_deselected.connect(cancel)
	EventBus.unit_selected.connect(cancel.unbind(1))


func is_active() -> bool:
	return _entry != null


func _on_action_requested(action: int, unit: Node) -> void:
	if action != PlayerActions.Action.MOVE:
		return
	var entry := MatchState.get_entry_for_unit(unit)
	if entry == null or entry.get_player() == null:
		return
	_entry = entry
	_reachable = _compute_reachable(pitch.unit_grid.get_tile_of(unit), entry.get_player().MA, unit)
	set_process(true)
	# La portée dessine son propre survol : le surligneur de case ferait double.
	GuiState.set_pointer_mode(GuiState.PointerMode.TARGETING)
	queue_redraw()


func cancel() -> void:
	if _entry == null:
		return
	_entry = null
	_reachable.clear()
	_hovered = Vector2i(-1, -1)
	set_process(false)
	GuiState.release_pointer_mode(GuiState.PointerMode.TARGETING)
	queue_redraw()


## Parcours en largeur depuis la case du joueur. Les cases occupées bloquent —
## on ne traverse pas un joueur, adversaire ou non.
func _compute_reachable(from: Vector2i, movement: int, unit: Node) -> Dictionary:
	var costs := { from: 0 }
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var tile: Vector2i = frontier.pop_front()
		var cost: int = costs[tile]
		if cost >= movement:
			continue
		for offset: Vector2i in NEIGHBOURS:
			var next: Vector2i = tile + offset
			if costs.has(next) or not pitch.is_tile_in_bounds(next):
				continue
			if pitch.unit_grid.is_tile_blocked_for(next, unit):
				continue
			costs[next] = cost + 1
			frontier.append(next)
	costs.erase(from)
	return costs


func _process(_delta: float) -> void:
	var tile := pitch.get_hovered_tile()
	if tile != _hovered:
		_hovered = tile
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		return

	var tile := pitch.get_hovered_tile()
	if _reachable.has(tile):
		_move_to(tile)
		get_viewport().set_input_as_handled()
	else:
		# Un clic hors portée sort du mode sans rien déplacer.
		cancel()


func _move_to(tile: Vector2i) -> void:
	var entry := _entry
	cancel()
	if arena and arena.place_entry_on_pitch(entry, tile):
		# Le joueur a consommé son action du tour.
		MatchState.set_condition(entry, MatchState.Condition.PLAYED)


func _draw() -> void:
	if not is_active():
		return
	var tile_size := Vector2(pitch.tile_set.tile_size)

	for tile: Vector2i in _reachable:
		var rect := _tile_rect(tile, tile_size)
		draw_rect(rect, HOVERED_FILL if tile == _hovered else REACHABLE_FILL, true)

	# Seul le pourtour de la zone est tracé : un contour par case donnerait un
	# quadrillage, alors que c'est la silhouette de la portée qui informe.
	for tile: Vector2i in _reachable:
		var rect := _tile_rect(tile, tile_size)
		for side: Vector2i in SIDES:
			if _reachable.has(tile + side):
				continue
			draw_line(_side_start(rect, side), _side_end(rect, side), REACHABLE_EDGE, EDGE_WIDTH)

	if _reachable.has(_hovered):
		draw_rect(_tile_rect(_hovered, tile_size), HOVERED_EDGE, false, EDGE_WIDTH)


func _tile_rect(tile: Vector2i, tile_size: Vector2) -> Rect2:
	return Rect2(pitch.map_to_local(tile) - tile_size * 0.5, tile_size)


func _side_start(rect: Rect2, side: Vector2i) -> Vector2:
	if side.x > 0:
		return Vector2(rect.end.x, rect.position.y)
	if side.y > 0:
		return Vector2(rect.position.x, rect.end.y)
	return rect.position


func _side_end(rect: Rect2, side: Vector2i) -> Vector2:
	if side.x < 0:
		return Vector2(rect.position.x, rect.end.y)
	if side.y < 0:
		return Vector2(rect.end.x, rect.position.y)
	return rect.end
