class_name RosterDrag
extends Node

## Glisser d'un joueur depuis une boîte du dugout vers le terrain.
##
## Le geste se déroule entièrement sur un calque neutre, en coordonnées écran.
## C'est ce qui permet de traverser la frontière GUI / monde sans conversion en
## cours de route : seul le dépôt décide de l'espace d'arrivée.

const PROXY_SIZE := Vector2(48, 48)

@export var drag_layer: CanvasLayer
@export var arena: Arena
## Toutes les colonnes, y compris celles d'en face : une colonne adverse doit
## intercepter le dépôt, sinon le joueur atterrirait sur le terrain sous le panneau.
@export var dugouts: Array[DugoutPanel] = []

var _entry: MatchState.Entry = null
var _proxy: TextureRect = null


func _ready() -> void:
	set_process(false)
	for dugout in dugouts:
		if dugout:
			dugout.item_drag_requested.connect(_on_item_drag_requested)


func is_dragging() -> bool:
	return _entry != null


func _on_item_drag_requested(item: DugoutItem) -> void:
	begin(item.entry)


func begin(entry: MatchState.Entry) -> void:
	if entry == null or _entry != null or drag_layer == null:
		return
	_entry = entry
	_proxy = TextureRect.new()
	_proxy.texture = entry.get_icon()
	_proxy.size = PROXY_SIZE
	_proxy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_proxy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_proxy.modulate.a = 0.85
	drag_layer.add_child(_proxy)
	set_process(true)
	GuiState.set_pointer_mode(GuiState.PointerMode.DRAGGING)


func _process(_delta: float) -> void:
	if _proxy:
		_proxy.position = get_viewport().get_mouse_position() - PROXY_SIZE * 0.5


func _input(event: InputEvent) -> void:
	if _entry == null:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_finish(get_viewport().get_mouse_position())
		get_viewport().set_input_as_handled()


## Un dépôt qui ne tombe ni sur une boîte ni sur une case libre ne fait rien :
## le joueur reste là où il était.
func _finish(screen_point: Vector2) -> void:
	var entry := _entry
	_entry = null
	set_process(false)
	GuiState.release_pointer_mode(GuiState.PointerMode.DRAGGING)
	if _proxy:
		_proxy.queue_free()
		_proxy = null

	var box := _box_at(screen_point)
	if box:
		# Colonne adverse : le geste est simplement abandonné.
		if box.team == entry.team:
			if arena:
				arena.remove_entry_from_pitch(entry)
			MatchState.set_location(entry, box.location)
		return

	if arena:
		arena.place_entry_on_hovered_tile(entry)


func _box_at(screen_point: Vector2) -> DugoutBox:
	for dugout in dugouts:
		if dugout == null:
			continue
		var box := dugout.box_at_screen_point(screen_point)
		if box:
			return box
	return null
