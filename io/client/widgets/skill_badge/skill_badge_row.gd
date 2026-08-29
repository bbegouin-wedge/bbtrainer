class_name SkillBadgeRow
extends Node2D

## Rangée de pastilles de compétences, centrée sur l'origine du nœud.
## Utilisée sur les unités du terrain pour afficher les compétences ajoutées.

const DEFAULT_RADIUS := 22.0
# Entraxe entre deux pastilles, en multiples du rayon.
const SPACING_RATIO := 2.3

@export var radius: float = DEFAULT_RADIUS : set = set_radius
## Largeur maximale de la rangée ; 0 signifie aucune contrainte.
## Au-delà, les pastilles se resserrent au lieu de déborder de la tuile.
@export var max_width: float = 0.0 : set = set_max_width
@export var font: Font

var _skill_uids: Array[String] = []
var _last_screen_scale := 0.0


func _ready() -> void:
	set_process(not _skill_uids.is_empty())


# Le zoom caméra ne provoque pas de redessin : on le surveille pour réévaluer
# la lisibilité des initiales.
func _process(_delta: float) -> void:
	var scale_now := _screen_scale()
	if not is_equal_approx(scale_now, _last_screen_scale):
		_last_screen_scale = scale_now
		queue_redraw()


func set_skills(skill_uids: Array[String]) -> void:
	_skill_uids = skill_uids.duplicate()
	set_process(not _skill_uids.is_empty())
	queue_redraw()


func get_skills() -> Array[String]:
	return _skill_uids.duplicate()


func set_radius(value: float) -> void:
	radius = value
	queue_redraw()


func set_max_width(value: float) -> void:
	max_width = value
	queue_redraw()


func _draw() -> void:
	if _skill_uids.is_empty():
		return

	var used_font := font if font != null else ThemeDB.fallback_font
	var pitch := _badge_pitch()
	var start_x := -pitch * (_skill_uids.size() - 1) * 0.5
	var screen_scale := _screen_scale()

	for i in _skill_uids.size():
		var uid := _skill_uids[i]
		SkillBadge.draw_into(self, Vector2(start_x + pitch * i, 0.0), radius,
			SkillBadge.color_for_skill(uid), SkillBadge.initials_for_skill(uid),
			used_font, screen_scale)


func _badge_pitch() -> float:
	var pitch := radius * SPACING_RATIO
	if max_width <= 0.0 or _skill_uids.size() < 2:
		return pitch
	var needed := pitch * (_skill_uids.size() - 1) + radius * 2.0
	if needed <= max_width:
		return pitch
	# On laisse les pastilles se chevaucher plutôt que de sortir de la tuile.
	return maxf(radius * 0.6, (max_width - radius * 2.0) / float(_skill_uids.size() - 1))


## Échelle du nœud à l'écran, zoom de la caméra inclus.
func _screen_scale() -> float:
	if not is_inside_tree():
		return 1.0
	return absf((get_viewport_transform() * get_global_transform()).get_scale().x)
