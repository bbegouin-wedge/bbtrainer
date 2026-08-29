class_name MovementRange
extends Node2D

## Portée de déplacement d'un joueur, dessinée sur la pelouse.
##
## L'information va sur le terrain plutôt que dans un panneau : c'est là qu'on
## la lit pour décider. Rien n'est texturé, tout est tracé — même parti que les
## pastilles de compétences et la minimap.

const REACHABLE_FILL := Color(0.29, 0.55, 0.85, 0.30)
const REACHABLE_EDGE := Color(0.66, 0.85, 1.0, 0.75)
const HOVERED_FILL := Color(0.55, 0.82, 1.0, 0.42)
const HOVERED_EDGE := Color(1, 1, 1, 0.5)
## Épaisseurs en pixels ÉCRAN, converties au tracé. Exprimées en unités monde
## elles étaient divisées par le zoom et tombaient sous le pixel : l'anticrénelage
## n'avait plus de quoi travailler et les bords sortaient inégalement marqués.
const EDGE_WIDTH_PX := 2.0
## Liseré de la case survolée : plus épais que le pourtour de la zone, mais plus
## doux en couleur. Tracé d'une seule polyligne anticrénelée — quatre segments
## séparés retombaient différemment sur la grille de pixels une fois divisés par
## le zoom, d'où des bords inégalement marqués.
const HOVERED_WIDTH_PX := 3.0
const CORNER_RADIUS := 22.0
const CORNER_STEPS := 4

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
var _last_screen_scale := 0.0


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
	var scale_now := _screen_scale()
	if tile != _hovered or not is_equal_approx(scale_now, _last_screen_scale):
		_hovered = tile
		_last_screen_scale = scale_now
		queue_redraw()


## Échelle du terrain à l'écran, zoom caméra compris.
func _screen_scale() -> float:
	if not is_inside_tree():
		return 1.0
	return maxf(0.001, absf((get_viewport_transform() * get_global_transform()).get_scale().x))


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
	# Les épaisseurs sont ramenées en unités monde pour valoir la largeur voulue
	# une fois le zoom appliqué.
	var scale := _screen_scale()
	var edge_width := EDGE_WIDTH_PX / scale
	var hovered_width := HOVERED_WIDTH_PX / scale

	for tile: Vector2i in _reachable:
		var rect := _tile_rect(tile, tile_size)
		if tile == _hovered:
			# Rempli aux mêmes coins arrondis que son liseré, sinon les angles
			# du carré dépasseraient du tracé.
			draw_colored_polygon(_rounded_tile_outline(rect, hovered_width), HOVERED_FILL)
		else:
			draw_rect(rect, REACHABLE_FILL, true)

	# Seul le pourtour de la zone est tracé : un contour par case donnerait un
	# quadrillage, alors que c'est la silhouette de la portée qui informe.
	for tile: Vector2i in _reachable:
		var rect := _tile_rect(tile, tile_size)
		for side: Vector2i in SIDES:
			if _reachable.has(tile + side):
				continue
			draw_line(_side_start(rect, side), _side_end(rect, side), REACHABLE_EDGE, edge_width)

	if _reachable.has(_hovered):
		var outline := _rounded_tile_outline(_tile_rect(_hovered, tile_size), hovered_width)
		draw_polyline(outline, HOVERED_EDGE, hovered_width, true)


## Contour arrondi d'une case, en rentrant d'une demi-épaisseur pour que le
## trait ne déborde pas sur les cases voisines.
func _rounded_tile_outline(rect: Rect2, width: float) -> PackedVector2Array:
	var inner := rect.grow(-width * 0.5)
	var radius := minf(CORNER_RADIUS, minf(inner.size.x, inner.size.y) * 0.5)
	var points := PackedVector2Array()
	# Centres des quatre arcs, dans l'ordre du parcours.
	var corners := [
		{ "center": Vector2(inner.end.x - radius, inner.position.y + radius), "start": -PI * 0.5 },
		{ "center": Vector2(inner.end.x - radius, inner.end.y - radius), "start": 0.0 },
		{ "center": Vector2(inner.position.x + radius, inner.end.y - radius), "start": PI * 0.5 },
		{ "center": Vector2(inner.position.x + radius, inner.position.y + radius), "start": PI },
	]
	for corner: Dictionary in corners:
		for step in CORNER_STEPS + 1:
			var angle: float = corner["start"] + PI * 0.5 * float(step) / float(CORNER_STEPS)
			points.append(corner["center"] + Vector2(cos(angle), sin(angle)) * radius)
	points.append(points[0])
	return points


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
