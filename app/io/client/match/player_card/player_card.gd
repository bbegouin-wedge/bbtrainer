extends CanvasLayer

## Fiche de joueur, appelée au clic droit sur un jeton.
##
## Le clic gauche est pris par la sélection et le panneau d'actions ; la fiche
## est le geste de consultation. Elle se pose près du joueur et flotte, donc
## elle ne réserve plus de marge de caméra comme quand elle occupait le bord droit.

const SKILL_BADGE_RADIUS := 14.0
const SKILL_ENTRY_SEPARATION := 6


@export var arena_phase: ArenaPhase

@onready var _root: Control = $ColorRect
@onready var _icon: TextureRect = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/icon/TextureRect
@onready var _position_label: Label = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Panel2/MarginContainer/VBoxContainer/Label2
@onready var _skills_grid: GridContainer = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Panel/VBoxContainer
@onready var _mv: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/mouv
@onready var _ag: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/Ag
@onready var _st: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/St
@onready var _pa: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/Pa
@onready var _av: StatCartridge = $ColorRect/VBoxContainer/MarginContainer/VBoxContainer/GridContainer/Av

var _unit: Node = null
var _contextual: ContextualPanel


func _ready() -> void:
	visible = false
	_contextual = ContextualPanel.attach(self, _root, arena_phase)
	EventBus.unit_right_clicked.connect(_on_unit_right_clicked)
	# Sélectionner ou désélectionner referme la fiche : elle appartient au geste
	# de consultation, pas à celui de commande.
	EventBus.unit_selected.connect(_close.unbind(1))
	EventBus.unit_deselected.connect(_close)


func _on_unit_right_clicked(unit: Node) -> void:
	var player := (unit as Unit).get_player()
	if player == null:
		return
	_unit = unit
	_icon.texture = Icons.blue(player)
	_position_label.text = player.position_name
	_mv.set_value(str(player.MA))
	_st.set_value(str(player.ST))
	_ag.set_value(str(player.AG) + "+")
	_pa.set_value(str(player.PA) + "+")
	_av.set_value(str(player.AV) + "+")
	_populate_skills(player)
	visible = true
	_contextual.show_near(unit)


func _close() -> void:
	_unit = null
	visible = false
	if _contextual:
		_contextual.dismiss()


func _populate_skills(player: BloodBowlData.Player) -> void:
	for child in _skills_grid.get_children():
		child.queue_free()
	for skill_uid in player.skills:
		_skills_grid.add_child(_build_skill_entry(skill_uid, _is_added_skill(player, skill_uid)))


## Une pastille suivie du nom de la compétence.
func _build_skill_entry(skill_uid: String, is_added: bool) -> HBoxContainer:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", SKILL_ENTRY_SEPARATION)

	var badge := SkillBadgeView.new()
	badge.radius = SKILL_BADGE_RADIUS
	badge.setup(skill_uid, is_added)
	entry.add_child(badge)

	var label := Label.new()
	label.text = BloodBowlManager.get_skill_name(skill_uid)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.tooltip_text = SkillBadge.tooltip_for_skill(skill_uid)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	entry.add_child(label)

	return entry


## base_skills n'est renseigné que sur les joueurs recrutés (voir Player.duplicate) :
## sans cette information, aucune compétence n'est signalée comme acquise.
func _is_added_skill(player: BloodBowlData.Player, skill_uid: String) -> bool:
	if player.base_skills.is_empty():
		return false
	return skill_uid not in player.base_skills
