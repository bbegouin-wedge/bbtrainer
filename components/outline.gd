class_name UnitOutline
extends Node

## Unique propriétaire du contour de l'unité.
##
## Le survol et la sélection sont deux états indépendants qui se peignent au même
## endroit : tant que chaque composant écrivait directement `width` et `fade`, le
## dernier à parler effaçait l'autre. Ils déclarent maintenant leur état ici, et
## c'est cette classe seule qui en déduit l'apparence.
##
## Rappel sur le shader (fade_outline.gdshader) : `fade` multiplie l'alpha du
## contour, donc `fade = 0` le rend invisible quelle que soit sa largeur.

const HOVER_WIDTH := 3.0
const HOVER_FADE := 0.55
const SELECTED_WIDTH := 4.5
const SELECTED_FADE := 1.0

@export var sprite: Sprite2D
@export var fade_duration: float = 0.2

var _hovered := false
var _selected := false
var _tween: Tween
var _material: ShaderMaterial


func _ready() -> void:
	if sprite:
		_material = sprite.material as ShaderMaterial
	if _material == null:
		push_warning("UnitOutline sans ShaderMaterial : le contour restera inerte")
		return
	_set_width(0.0)
	_material.set_shader_parameter("fade", 0.0)


func set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	_apply()


func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	_apply()


## La sélection prime sur le survol : survoler une unité déjà sélectionnée
## ne change rien, et la désélectionner sous le curseur retombe sur le survol.
func _apply() -> void:
	if _material == null:
		return

	var target_fade := 0.0
	var target_width := 0.0
	if _selected:
		target_fade = SELECTED_FADE
		target_width = SELECTED_WIDTH
	elif _hovered:
		target_fade = HOVER_FADE
		target_width = HOVER_WIDTH

	if _tween and _tween.is_valid():
		_tween.kill()

	# La largeur s'applique tout de suite pour que le fondu ait quelque chose à
	# révéler ; elle n'est ramenée à zéro qu'une fois le fondu sortant terminé,
	# sinon le contour disparaîtrait d'un coup au lieu de s'estomper.
	if target_width > 0.0:
		_set_width(target_width)

	_tween = create_tween()
	_tween.tween_property(_material, "shader_parameter/fade", target_fade, fade_duration) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	if is_zero_approx(target_width):
		_tween.tween_callback(_set_width.bind(0.0))


## Une largeur nulle coupe la recherche de voisins du shader, dont le coût croît
## avec le carré de la largeur : on ne la laisse pas traîner sur les unités inertes.
func _set_width(value: float) -> void:
	if _material:
		_material.set_shader_parameter("width", value)
