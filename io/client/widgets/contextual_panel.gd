class_name ContextualPanel
extends Node

## Pose un panneau à côté d'un jeton et l'y déplie.
##
## Mutualisé parce que la fiche de joueur et le panneau d'actions ont exactement
## le même comportement : s'écarter du BORD du jeton, se retourner quand il est
## près d'un bord d'écran, suivre la caméra, et se déplier depuis le joueur.
##
## C'est la manière dont ce projet fait apparaître un panneau contextuel : tout
## nouveau panneau de ce genre devrait passer par ici plutôt que réinventer le
## placement et l'animation.

## Écart au bord du jeton, et marge minimale aux bords de l'écran.
const GAP := 14.0
const SCREEN_MARGIN := 12.0
## Apparition : glissement depuis le jeton, en s'opacifiant.
const REVEAL_DURATION := 0.14
const REVEAL_SLIDE := 14.0

var _panel: Control
var _arena_phase: ArenaPhase
var _unit: Node = null
## Décalage transitoire de l'apparition, ramené à zéro par le tween. Il s'ajoute
## à la position calculée, qui est recalculée à chaque frame pour suivre la
## caméra — animer `position` directement se ferait écraser au frame suivant.
var _reveal_offset := Vector2.ZERO
var _opens_right := true
var _tween: Tween


static func attach(parent: Node, panel: Control, arena_phase: ArenaPhase) -> ContextualPanel:
	var node := ContextualPanel.new()
	node._panel = panel
	node._arena_phase = arena_phase
	node.name = "ContextualPanel_" + panel.name
	parent.add_child(node)
	return node


func _ready() -> void:
	set_process(false)


## Déplie le panneau à côté de l'unité et l'y maintient.
func show_near(unit: Node) -> void:
	_unit = unit
	set_process(true)
	_place()
	_play_reveal()


func dismiss() -> void:
	_unit = null
	set_process(false)


func _process(_delta: float) -> void:
	# La caméra bouge sous le panneau : il doit rester collé à son joueur.
	_place()


## Le panneau vient du côté où il s'ouvre : le mouvement part toujours du joueur.
func _play_reveal() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_reveal_offset = Vector2(-REVEAL_SLIDE if _opens_right else REVEAL_SLIDE, 0.0)
	_panel.modulate.a = 0.0
	_place()

	_tween = create_tween().set_parallel()
	_tween.tween_property(_panel, "modulate:a", 1.0, REVEAL_DURATION)
	_tween.tween_method(_set_reveal_offset, _reveal_offset, Vector2.ZERO, REVEAL_DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)


func _set_reveal_offset(value: Vector2) -> void:
	_reveal_offset = value
	_place()


func _place() -> void:
	if _arena_phase == null or _unit == null or not is_instance_valid(_unit):
		return
	# to_global et non global_position + offset : l'écart du coin de la tuile à
	# son centre doit tourner AVEC l'unité. Ajouté en coordonnées monde, il
	# pointait à côté dès que l'arène pivotait.
	var anchor := _arena_phase.world_to_screen(
		_unit.to_global(Vector2(Unit.TILE_SIZE, Unit.TILE_SIZE) * 0.5))
	var viewport := _panel.get_viewport_rect().size
	var panel_size := _panel.size
	# Demi-jeton à l'écran : c'est de son bord qu'il faut s'écarter, pas de son
	# centre — un jeton occupe une tuile entière.
	var clearance := _arena_phase.world_length_to_screen(Unit.TILE_SIZE * 0.5) + GAP

	var x := anchor.x + clearance
	_opens_right = true
	if x + panel_size.x > viewport.x - SCREEN_MARGIN:
		x = anchor.x - clearance - panel_size.x
		_opens_right = false
	var y := anchor.y - panel_size.y * 0.5
	_panel.position = Vector2(
		clampf(x, SCREEN_MARGIN, viewport.x - panel_size.x - SCREEN_MARGIN),
		clampf(y, SCREEN_MARGIN, viewport.y - panel_size.y - SCREEN_MARGIN)) + _reveal_offset
