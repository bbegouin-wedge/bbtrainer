class_name ArenaPhase
extends Node2D

const TILE_SIZE := 210
const GRID_WIDTH := 26
## 15, pas 16 : c'est la taille réelle de la grille (voir ArenaUnitGrid).
## L'écart faussait le calcul de zoom de 7 %.
const GRID_HEIGHT := 15
const TERRAIN_WIDTH := GRID_WIDTH * TILE_SIZE
const TERRAIN_HEIGHT := GRID_HEIGHT * TILE_SIZE

## Bandes d'écran mangées par le HUD : les colonnes de dugout à gauche et à
## droite, le bandeau de tour en haut, la barre de dés en bas. Le terrain se
## cadre dans ce qu'il reste, pas dans le viewport entier — sinon ses bords
## restent en permanence sous les panneaux.
const HUD_MARGIN_LEFT := 282.0
const HUD_MARGIN_RIGHT := 282.0
const HUD_MARGIN_TOP := 74.0
const HUD_MARGIN_BOTTOM := 114.0

## Part de l'aire du terrain visible au démarrage. Le terrain entier tenait à
## l'écran, ce qui ne laissait rien à explorer et rendait la navigation inutile.
const DEFAULT_VIEW_FRACTION := 0.5

@export var grid_displayed := false

@onready var camera: Camera2D = $Camera2D
@onready var arena: Arena = $Arena
@onready var dugouts: Array[DugoutPanel] = [
	$DugoutLayer/BlueDugout,
	$DugoutLayer/RedDugout,
]

func _ready() -> void:
	arena.dugouts = dugouts
	_setup_camera_for_arena()

func _process(_delta: float) -> void:
	var grid := arena.get_node("grid") as TileMapLayer
	grid.visible = grid_displayed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		GuiState.clear_selection()
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("toggle_grid"):
		grid_displayed = !grid_displayed
	if event.is_action_pressed("toggle_window_orientation"):
		_swap_window_orientation()


## Utilitaire de développement : inverse les dimensions de la fenêtre pour
## éprouver la mise en page en portrait. Écoutait KEY_R en brut, c'est-à-dire la
## même touche que la rotation du terrain (toggle_pitch_orientation) — les deux
## se déclenchaient ensemble. Déplacé sur F9.
func _swap_window_orientation() -> void:
	var window_size := DisplayServer.window_get_size()
	DisplayServer.window_set_size(Vector2i(window_size.y, window_size.x))
	_setup_camera_for_arena()

func _setup_camera_for_arena() -> void:
	var band := get_visible_band()
	var zoom_level := _default_zoom(band.size)
	camera.zoom = Vector2(zoom_level, zoom_level)
	camera.position = _position_centering_terrain(band, zoom_level)
	_apply_camera_limits(zoom_level)


## Rectangle d'écran réellement disponible pour le terrain, HUD déduit.
func get_visible_band() -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Rect2(
		Vector2(HUD_MARGIN_LEFT, HUD_MARGIN_TOP),
		Vector2(
			maxf(1.0, viewport_size.x - HUD_MARGIN_LEFT - HUD_MARGIN_RIGHT),
			maxf(1.0, viewport_size.y - HUD_MARGIN_TOP - HUD_MARGIN_BOTTOM)))


## Position à l'écran d'un point du monde, caméra comprise. Sert aux panneaux
## contextuels, qui doivent rester collés à leur joueur.
func world_to_screen(world: Vector2) -> Vector2:
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	return (world - camera.get_screen_center_position()) * camera.zoom.x + viewport_center


## Zoom tel que la bande visible couvre DEFAULT_VIEW_FRACTION de l'aire du terrain.
func _default_zoom(band_size: Vector2) -> float:
	var terrain_area := float(TERRAIN_WIDTH) * float(TERRAIN_HEIGHT)
	return sqrt(band_size.x * band_size.y / (terrain_area * DEFAULT_VIEW_FRACTION))


## Le centre du terrain doit tomber au centre de la bande, pas du viewport :
## la caméra montre le point `position` au centre de l'écran, il faut donc la
## décaler de l'écart entre les deux centres, ramené en unités monde.
func _position_centering_terrain(band: Rect2, zoom_level: float) -> Vector2:
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var band_center := band.position + band.size * 0.5
	var terrain_center := Vector2(TERRAIN_WIDTH, TERRAIN_HEIGHT) * 0.5
	return terrain_center - (band_center - viewport_center) / zoom_level


## Limites resserrées sur le terrain : les dugouts du monde ont disparu, plus rien
## d'utile ne vit en dehors. La marge vaut la largeur du HUD ramenée en unités
## monde — juste ce qu'il faut pour amener un bord du terrain au bord de la bande.
func _apply_camera_limits(zoom_level: float) -> void:
	camera.limit_left = int(-HUD_MARGIN_LEFT / zoom_level)
	camera.limit_top = int(-HUD_MARGIN_TOP / zoom_level)
	camera.limit_right = TERRAIN_WIDTH + int(HUD_MARGIN_RIGHT / zoom_level)
	camera.limit_bottom = TERRAIN_HEIGHT + int(HUD_MARGIN_BOTTOM / zoom_level)
