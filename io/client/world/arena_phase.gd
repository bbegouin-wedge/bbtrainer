class_name ArenaPhase
extends Node2D

const TILE_SIZE := 210
const TERRAIN_WIDTH := Pitch.SIZE.x * TILE_SIZE
const TERRAIN_HEIGHT := Pitch.SIZE.y * TILE_SIZE

## Bandes d'écran mangées par le HUD quand ses panneaux sont déployés. Le terrain
## se cadre dans ce qu'il reste, pas dans le viewport entier — sinon ses bords
## restent en permanence sous les panneaux. Un panneau escamoté rend sa bande.
## Le dock n'y figure pas : centré et fin, la pelouse passe de part et d'autre.
const HUD_MARGIN_LEFT := 282.0
const HUD_MARGIN_RIGHT := 282.0
const HUD_MARGIN_TOP := 74.0
## Le bandeau et le dock sont remontés de 46 px : collés au bord bas d'une
## fenêtre sans bordure de 1080 px, ils tombaient sous le Dock du système.
const HUD_MARGIN_STRIP := 176.0

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
@onready var _strip: PlayerStrip = $HudLayer/PlayerStrip
@onready var _dock: HudDock = $HudLayer/HudDock
@onready var _minimap: Minimap = $MinimapLayer/Minimap
@onready var _topbar: Control = $GamePanel/TopPanel
@onready var _rotator: CameraRotator = $GameControlManager/CameraRotator
@onready var _staff_panels: Array[StaffPanel] = [
	$DugoutLayer/BlueStaff,
	$DugoutLayer/RedStaff,
]

## Panneaux escamotables, par clé du dock. Chacun sait glisser hors de son bord.
var _panels: Dictionary = {}

func _ready() -> void:
	arena.dugouts = dugouts
	_rotator.rotated.connect(refresh_camera_framing)
	_setup_camera_for_arena()
	call_deferred("_setup_collapsibles")


## Différé d'une frame : Collapsible mémorise la position au repos de chaque
## panneau, il faut donc que la mise en page ait eu lieu.
func _setup_collapsibles() -> void:
	# Une clé peut piloter plusieurs panneaux : le banc s'escamote des deux côtés
	# d'un seul bouton, alors que chaque dugout garde le sien.
	_panels = {
		"blue": [Collapsible.attach(self, dugouts[0], Collapsible.Edge.LEFT)],
		"red": [Collapsible.attach(self, dugouts[1], Collapsible.Edge.RIGHT)],
		"topbar": [Collapsible.attach(self, _topbar, Collapsible.Edge.TOP)],
		"strip": [Collapsible.attach(self, _strip, Collapsible.Edge.BOTTOM)],
		"minimap": [Collapsible.attach(self, _minimap, Collapsible.Edge.BOTTOM)],
		"staff": [
			Collapsible.attach(self, _staff_panels[0], Collapsible.Edge.LEFT),
			Collapsible.attach(self, _staff_panels[1], Collapsible.Edge.RIGHT),
		],
	}
	_dock.populate([
		{ "key": "blue", "label": "Dugout bleu" },
		{ "key": "red", "label": "Dugout rouge" },
		{ "key": "topbar", "label": "Tour" },
		{ "key": "strip", "label": "Joueurs" },
		{ "key": "staff", "label": "Banc" },
		{ "key": "minimap", "label": "Carte" },
	])


func toggle_panel(key: String) -> void:
	if not _panels.has(key):
		return
	for panel: Collapsible in _panels[key]:
		panel.toggle()
	refresh_camera_framing()


func is_panel_shown(key: String) -> bool:
	return _panels.has(key) and not _panels[key][0].collapsed


## Escamoter ne recalcule pas le zoom : à aire visible constante, on ne verrait
## pas plus de terrain, seulement les mêmes cases en plus gros. En gardant le
## zoom, la place rendue devient du champ de vision.
func refresh_camera_framing() -> void:
	_apply_camera_limits(camera.zoom.x)

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


## Emprise du terrain dans le monde, telle qu'il est orienté. Pivoté d'un quart
## de tour il occupe une autre région : des limites figées sur l'orientation
## d'origine laissaient déplacer la vue là où il n'y a plus de terrain.
func get_pitch_world_rect() -> Rect2:
	var transform := arena.play_area.global_transform
	var tile := Vector2(arena.play_area.tile_set.tile_size)
	var local := Rect2(
		Vector2(arena.play_area.bounds.position) * tile,
		Vector2(arena.play_area.bounds.size) * tile)
	var world := Rect2(transform * local.position, Vector2.ZERO)
	for corner: Vector2 in [
			Vector2(local.end.x, local.position.y), local.end,
			Vector2(local.position.x, local.end.y)]:
		world = world.expand(transform * corner)
	return world


## Rectangle d'écran réellement disponible pour le terrain, HUD déduit. Il suit
## l'état d'escamotage : c'est la source unique du cadrage caméra et du rectangle
## de vue dessiné sur la minimap.
func get_visible_band() -> Rect2:
	var viewport_size := get_viewport().get_visible_rect().size
	# La colonne de gauche est occupée dès que le dugout OU le banc y est déployé,
	# les deux partageant la même bande.
	var left := HUD_MARGIN_LEFT if is_panel_shown("blue") or is_panel_shown("staff") else 0.0
	var right := HUD_MARGIN_RIGHT if is_panel_shown("red") or is_panel_shown("staff") else 0.0
	var top := HUD_MARGIN_TOP if is_panel_shown("topbar") else 0.0
	var bottom := HUD_MARGIN_STRIP if is_panel_shown("strip") else 0.0
	return Rect2(
		Vector2(left, top),
		Vector2(
			maxf(1.0, viewport_size.x - left - right),
			maxf(1.0, viewport_size.y - top - bottom)))


## Position à l'écran d'un point du monde, caméra comprise. Sert aux panneaux
## contextuels, qui doivent rester collés à leur joueur.
func world_to_screen(world: Vector2) -> Vector2:
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	return (world - camera.get_screen_center_position()) * camera.zoom.x + viewport_center


## Longueur monde convertie en pixels écran. Les panneaux contextuels s'en
## servent pour s'écarter du bord du jeton et non de son centre — un jeton fait
## une tuile entière, soit une centaine de pixels au zoom courant.
func world_length_to_screen(length: float) -> float:
	return length * camera.zoom.x


## Amène ce point du monde au centre de la bande visible — pas au centre de
## l'écran, qui est masqué par les colonnes quand elles sont déployées.
func center_camera_on(world: Vector2) -> void:
	var band := get_visible_band()
	var band_center := band.position + band.size * 0.5
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	camera.position = world - (band_center - viewport_center) / camera.zoom.x


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
	var pitch := get_pitch_world_rect()
	var terrain_center := pitch.position + pitch.size * 0.5
	return terrain_center - (band_center - viewport_center) / zoom_level


## Limites resserrées sur le terrain : les dugouts du monde ont disparu, plus rien
## d'utile ne vit en dehors. La marge vaut la largeur du HUD ramenée en unités
## monde — juste ce qu'il faut pour amener un bord du terrain au bord de la bande.
func _apply_camera_limits(zoom_level: float) -> void:
	var band := get_visible_band()
	var viewport_size := get_viewport().get_visible_rect().size
	var pitch := get_pitch_world_rect()
	camera.limit_left = int(pitch.position.x - band.position.x / zoom_level)
	camera.limit_top = int(pitch.position.y - band.position.y / zoom_level)
	camera.limit_right = int(pitch.end.x \
		+ (viewport_size.x - band.end.x) / zoom_level)
	camera.limit_bottom = int(pitch.end.y \
		+ (viewport_size.y - band.end.y) / zoom_level)
