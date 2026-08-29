class_name Minimap
extends Control

## Carte schématique du terrain, dessinée au trait — aucune texture.
##
## Elle travaille en coordonnées locales au terrain, pas en coordonnées monde :
## quand l'arène pivote de 90°, la carte reste droite et lisible au lieu de
## basculer avec elle.
##
## Elle sert aussi de navigateur : le terrain ne tient plus à l'écran, cliquer
## dedans y amène la caméra.

const BACKDROP_COLOR := Color(0, 0, 0, 0.72)
const PITCH_COLOR := Color(0.16, 0.33, 0.20)
const LINE_COLOR := Color(1, 1, 1, 0.30)
const BORDER_COLOR := Color(0, 0, 0, 0.65)
const VIEW_RECT_COLOR := Color(1, 0.94, 0.6, 0.9)
const UNIT_OUTLINE := Color(0.05, 0.05, 0.07, 0.85)
const TEAM_COLORS := {
	MatchState.Team.BLUE: Color("2f6fd0"),
	MatchState.Team.RED: Color("c0392b"),
}

const UNIT_RADIUS := 4.0
const VIEW_RECT_WIDTH := 1.5
## Découpage tactique du terrain, en cases : ligne médiane, lignes d'en-but,
## et les deux lignes qui délimitent les zones larges.
const HALFWAY_COLUMN := 13
const ENDZONE_COLUMNS := [1, 25]
const WIDE_ZONE_ROWS := [4, 11]

@export var camera: Camera2D
@export var arena_phase: ArenaPhase
@export var pitch: UnitZone

var _scale := 1.0
var _origin := Vector2.ZERO
var _last_camera := Vector3.ZERO
var _was_dragging := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_update_projection)
	MatchState.roster_changed.connect(queue_redraw)
	if pitch and pitch.unit_grid:
		pitch.unit_grid.unit_grid_changed.connect(queue_redraw)
	_update_projection()


## Ni le déplacement de la caméra ni le glisser d'une unité n'émettent de signal :
## on les surveille, à peu de frais, pour ne redessiner que lorsqu'ils bougent.
func _process(_delta: float) -> void:
	if camera == null:
		return
	var signature := Vector3(camera.global_position.x, camera.global_position.y, camera.zoom.x)
	var dragging := get_tree().get_first_node_in_group("dragging") != null
	if signature != _last_camera or dragging or _was_dragging:
		_last_camera = signature
		_was_dragging = dragging
		queue_redraw()


func _draw() -> void:
	if pitch == null:
		return
	# Fond plein sur tout le contrôle : sans lui le terrain transparaît et la
	# carte se confond avec ce qu'elle est censée résumer.
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP_COLOR, true)
	var pitch_rect := _project_rect(_pitch_local_rect())
	draw_rect(pitch_rect, PITCH_COLOR, true)
	_draw_pitch_lines()
	_draw_units()
	_draw_view_rect()
	draw_rect(pitch_rect, BORDER_COLOR, false, 1.0)


func _draw_pitch_lines() -> void:
	var tile := float(pitch.tile_set.tile_size.x)
	var rows := float(pitch.bounds.size.y)
	var columns := float(pitch.bounds.size.x)

	var vertical_lines: Array[int] = [HALFWAY_COLUMN]
	vertical_lines.append_array(ENDZONE_COLUMNS)
	for column in vertical_lines:
		var x := float(column) * tile
		draw_line(_project(Vector2(x, 0.0)), _project(Vector2(x, rows * tile)), LINE_COLOR, 1.0)
	for row: int in WIDE_ZONE_ROWS:
		var y := float(row) * tile
		draw_line(_project(Vector2(0.0, y)), _project(Vector2(columns * tile, y)), LINE_COLOR, 1.0)


## Les positions viennent des nœuds, pas des cases : une unité en cours de glisser
## suit ainsi le curseur sur la carte au lieu de rester collée à sa case de départ.
func _draw_units() -> void:
	for entry in MatchState.get_entries_at(MatchState.Location.PITCH):
		if entry.unit == null or not is_instance_valid(entry.unit):
			continue
		var center := _project(pitch.to_local(entry.unit.global_position) + _unit_center_offset())
		draw_circle(center, UNIT_RADIUS, UNIT_OUTLINE, true, -1.0, true)
		var color: Color = TEAM_COLORS.get(entry.team, Color.WHITE)
		draw_circle(center, UNIT_RADIUS - 1.0, color, true, -1.0, true)


## L'origine d'une unité est le coin de sa tuile : on vise son centre.
func _unit_center_offset() -> Vector2:
	return Vector2(pitch.tile_set.tile_size) * 0.5


func _draw_view_rect() -> void:
	var view := get_view_rect_on_map()
	if view.size.x <= 0.0 or view.size.y <= 0.0:
		return
	draw_rect(view, VIEW_RECT_COLOR, false, VIEW_RECT_WIDTH)


## Emprise de la caméra telle qu'elle est tracée sur la carte, bornée au terrain.
##
## Sans cette borne, au zoom le plus large la vue déborde le terrain : le
## rectangle sortait alors entièrement de la carte — ses quatre bords au-delà
## des siens, donc plus rien de visible dedans, et un tracé par-dessus
## l'interface voisine.
func get_view_rect_on_map() -> Rect2:
	var view := _visible_pitch_rect().intersection(_pitch_local_rect())
	if view.size.x <= 0.0 or view.size.y <= 0.0:
		return Rect2()
	return _project_rect(view)


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	var dragged := false
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		pressed = button.button_index == MOUSE_BUTTON_LEFT and button.pressed
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		dragged = (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if pressed or dragged:
		_center_camera_on((event as InputEventMouse).position)
		accept_event()


## Amène le point cliqué au centre de la bande visible — pas au centre de l'écran,
## qui est masqué par les colonnes de dugout.
func _center_camera_on(map_point: Vector2) -> void:
	if camera == null or arena_phase == null:
		return
	var world := pitch.to_global(_unproject(map_point))
	var band := arena_phase.get_visible_band()
	var band_center := band.position + band.size * 0.5
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	camera.position = world - (band_center - viewport_center) / camera.zoom.x


func _pitch_local_rect() -> Rect2:
	var tile := Vector2(pitch.tile_set.tile_size)
	return Rect2(Vector2(pitch.bounds.position) * tile, Vector2(pitch.bounds.size) * tile)


## Portion du terrain réellement visible à l'écran, en coordonnées locales au terrain.
func _visible_pitch_rect() -> Rect2:
	if camera == null or arena_phase == null:
		return Rect2()
	var band := arena_phase.get_visible_band()
	var zoom := camera.zoom.x
	if is_zero_approx(zoom):
		return Rect2()
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var view_center := camera.get_screen_center_position()
	var top_left := view_center + (band.position - viewport_center) / zoom
	var corner_a := pitch.to_local(top_left)
	var corner_b := pitch.to_local(top_left + band.size / zoom)
	return Rect2(corner_a, corner_b - corner_a).abs()


func _update_projection() -> void:
	if pitch == null or pitch.tile_set == null:
		return
	var local := _pitch_local_rect()
	if local.size.x <= 0.0 or local.size.y <= 0.0:
		return
	_scale = minf(size.x / local.size.x, size.y / local.size.y)
	_origin = (size - local.size * _scale) * 0.5 - local.position * _scale
	queue_redraw()


func _project(local: Vector2) -> Vector2:
	return local * _scale + _origin


func _project_rect(local: Rect2) -> Rect2:
	return Rect2(_project(local.position), local.size * _scale)


func _unproject(map_point: Vector2) -> Vector2:
	return (map_point - _origin) / _scale
