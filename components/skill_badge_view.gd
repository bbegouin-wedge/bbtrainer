class_name SkillBadgeView
extends Control

## Une pastille de compétence utilisable dans l'UI (conteneurs, grilles, listes).
## Pendant Control de SkillBadgeRow, qui sert lui au terrain.
## L'infobulle donne le nom complet et la catégorie.

const DEFAULT_RADIUS := 16.0
## Épaisseur de l'anneau signalant une compétence acquise, en fraction du rayon.
const ADDED_RING_RATIO := 0.16
const ADDED_RING_COLOR := Color(1, 1, 1, 0.85)

@export var radius: float = DEFAULT_RADIUS : set = set_radius
## Marque la pastille comme compétence acquise plutôt que native au poste.
@export var is_added: bool = false : set = set_is_added
@export var font: Font

var _skill_uid: String = ""
var _category: String = ""


func setup(skill_uid: String, added: bool = false) -> void:
	_skill_uid = skill_uid
	_category = ""
	is_added = added
	tooltip_text = SkillBadge.tooltip_for_skill(skill_uid)
	queue_redraw()


## Pastille muette représentant une catégorie entière : sert de légende du code couleur.
func setup_category(category_id: String) -> void:
	_category = category_id
	_skill_uid = ""
	is_added = false
	tooltip_text = BloodBowlManager.get_skill_category_label(category_id)
	queue_redraw()


func get_skill_uid() -> String:
	return _skill_uid


func set_radius(value: float) -> void:
	radius = value
	custom_minimum_size = Vector2(_outer_radius() * 2.0, _outer_radius() * 2.0)
	update_minimum_size()
	queue_redraw()


func set_is_added(value: bool) -> void:
	is_added = value
	queue_redraw()


func _init() -> void:
	# PASS laisse passer les clics au conteneur parent tout en gardant l'infobulle.
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(_outer_radius() * 2.0, _outer_radius() * 2.0)


func _draw() -> void:
	var center := size * 0.5

	if not _category.is_empty():
		SkillBadge.draw_into(self, center, radius,
			SkillBadge.color_for_category(_category), "", null)
		return

	if _skill_uid.is_empty():
		return

	SkillBadge.draw_into(self, center, radius, SkillBadge.color_for_skill(_skill_uid),
		SkillBadge.initials_for_skill(_skill_uid),
		font if font != null else ThemeDB.fallback_font)

	if is_added:
		var ring_width := maxf(1.5, radius * ADDED_RING_RATIO)
		draw_arc(center, radius + ring_width, 0.0, TAU, 32, ADDED_RING_COLOR, ring_width, true)


func _outer_radius() -> float:
	return radius + maxf(1.5, radius * ADDED_RING_RATIO) * 2.0
