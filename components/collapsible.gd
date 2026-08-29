class_name Collapsible
extends Node

## Fait glisser un panneau hors de l'écran par le bord qu'on lui désigne.
##
## Créé à la volée par ArenaPhase plutôt que posé dans chaque scène : les
## panneaux escamotables viennent de scènes différentes, et leur ajouter à
## chacun un nœud aurait éparpillé la même mécanique en quatre endroits.

enum Edge { LEFT, RIGHT, TOP, BOTTOM }

const DURATION := 0.28

signal collapsed_changed(collapsed: bool)

var collapsed := false

var _target: Control
var _edge: Edge
var _rest_position: Vector2
var _tween: Tween


## `target` doit avoir sa position définitive : c'est elle qui sert de repère.
static func attach(parent: Node, target: Control, edge: Edge) -> Collapsible:
	var node := Collapsible.new()
	node._target = target
	node._edge = edge
	node.name = "Collapsible_" + target.name
	parent.add_child(node)
	return node


func _ready() -> void:
	_rest_position = _target.position


func toggle() -> void:
	set_collapsed(not collapsed)


func set_collapsed(value: bool) -> void:
	if collapsed == value:
		return
	collapsed = value
	_slide_to(_rest_position + (_hidden_offset() if collapsed else Vector2.ZERO))
	collapsed_changed.emit(collapsed)


## Déplacement à parcourir pour sortir complètement du viewport par son bord.
## Une marge d'un pixel évite qu'un liseré reste visible.
func _hidden_offset() -> Vector2:
	var viewport := _target.get_viewport_rect().size
	match _edge:
		Edge.LEFT:
			return Vector2(-(_target.position.x + _target.size.x + 1.0), 0.0)
		Edge.RIGHT:
			return Vector2(viewport.x - _target.position.x + 1.0, 0.0)
		Edge.TOP:
			return Vector2(0.0, -(_target.position.y + _target.size.y + 1.0))
		Edge.BOTTOM:
			return Vector2(0.0, viewport.y - _target.position.y + 1.0)
	return Vector2.ZERO


func _slide_to(target_position: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_target, "position", target_position, DURATION) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
