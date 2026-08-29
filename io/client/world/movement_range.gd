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

	# Le pourtour de la zone est tracé comme un chemin fermé et non côté par
	# côté : c'est ce qui donne des sommets à arrondir, et une épaisseur
	# constante là où quatre segments séparés se recouvraient aux angles.
	for loop: PackedVector2Array in _region_loops(tile_size):
		draw_polyline(_rounded_path(loop, CORNER_RADIUS), REACHABLE_EDGE, edge_width, true)

	if _reachable.has(_hovered):
		var outline := _rounded_tile_outline(_tile_rect(_hovered, tile_size), hovered_width)
		draw_polyline(outline, HOVERED_EDGE, hovered_width, true)


## Boucles fermées formant la frontière de la zone, en coordonnées locales.
##
## Chaque case expose ses côtés dont le voisin n'est pas atteignable, orientés
## dans le sens horaire ; les segments se chaînent alors bout à bout. Les trous
## laissés par les cases occupées ressortent comme des boucles à part.
func _region_loops(tile_size: Vector2) -> Array:
	var next_of := {}
	for tile: Vector2i in _reachable:
		for side: Vector2i in SIDES:
			if _reachable.has(tile + side):
				continue
			var corners := _side_corners(tile, side)
			next_of[corners[0]] = corners[1]

	var loops := []
	while not next_of.is_empty():
		var start: Vector2i = next_of.keys()[0]
		var corner_loop: Array[Vector2i] = []
		var current := start
		while next_of.has(current):
			corner_loop.append(current)
			var following: Vector2i = next_of[current]
			next_of.erase(current)
			current = following
		if corner_loop.size() >= 4:
			loops.append(_to_local_path(_drop_collinear(corner_loop), tile_size))
	return loops


## Extrémités d'un côté, en indices de coins de grille, dans le sens horaire.
func _side_corners(tile: Vector2i, side: Vector2i) -> Array:
	if side.y < 0:
		return [tile, tile + Vector2i(1, 0)]
	if side.x > 0:
		return [tile + Vector2i(1, 0), tile + Vector2i(1, 1)]
	if side.y > 0:
		return [tile + Vector2i(1, 1), tile + Vector2i(0, 1)]
	return [tile + Vector2i(0, 1), tile]


## Un sommet aligné entre ses voisins n'est pas un coin : le garder ferait
## arrondir le milieu des côtés.
func _drop_collinear(corner_loop: Array[Vector2i]) -> Array[Vector2i]:
	var kept: Array[Vector2i] = []
	var count := corner_loop.size()
	for i in count:
		var before: Vector2i = corner_loop[(i - 1 + count) % count]
		var here: Vector2i = corner_loop[i]
		var after: Vector2i = corner_loop[(i + 1) % count]
		if (here - before) != (after - here):
			kept.append(here)
	return kept


func _to_local_path(corner_loop: Array[Vector2i], tile_size: Vector2) -> PackedVector2Array:
	var path := PackedVector2Array()
	var origin := pitch.map_to_local(Vector2i.ZERO) - tile_size * 0.5
	for corner: Vector2i in corner_loop:
		path.append(origin + Vector2(corner) * tile_size)
	return path


## Remplace chaque sommet d'un polygone fermé par un arc de cercle. Le rayon est
## rogné à la moitié du plus court côté adjacent, pour ne jamais se croiser.
func _rounded_path(points: PackedVector2Array, radius: float) -> PackedVector2Array:
	var count := points.size()
	if count < 3:
		return points
	var path := PackedVector2Array()
	for i in count:
		var here := points[i]
		var before := points[(i - 1 + count) % count]
		var after := points[(i + 1) % count]
		var incoming := (here - before)
		var outgoing := (after - here)
		var turn := incoming.cross(outgoing)
		if is_zero_approx(turn):
			path.append(here)
			continue

		var r := minf(radius, minf(incoming.length(), outgoing.length()) * 0.5)
		var from := here - incoming.normalized() * r
		var to := here + outgoing.normalized() * r
		var sign := signf(turn)
		var center := from + incoming.normalized().rotated(sign * PI * 0.5) * r
		var start_angle := (from - center).angle()
		for step in CORNER_STEPS + 1:
			var angle := start_angle + sign * PI * 0.5 * float(step) / float(CORNER_STEPS)
			path.append(center + Vector2(cos(angle), sin(angle)) * r)
	path.append(path[0])
	return path


func _tile_rect(tile: Vector2i, tile_size: Vector2) -> Rect2:
	return Rect2(pitch.map_to_local(tile) - tile_size * 0.5, tile_size)


## Contour arrondi d'une case, en rentrant d'une demi-épaisseur pour que le
## trait ne déborde pas sur les voisines.
func _rounded_tile_outline(rect: Rect2, width: float) -> PackedVector2Array:
	var inner := rect.grow(-width * 0.5)
	var square := PackedVector2Array([
		inner.position,
		Vector2(inner.end.x, inner.position.y),
		inner.end,
		Vector2(inner.position.x, inner.end.y),
	])
	return _rounded_path(square, CORNER_RADIUS)
