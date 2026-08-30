extends Node

## Ce que le curseur est en train de faire. Le surligneur de case indique une
## DESTINATION : il n'a de sens que lorsqu'on s'apprête à poser un joueur
## quelque part — en ciblant un déplacement, ou en le faisant glisser.
enum PointerMode { BROWSE, CHOOSING_ACTION, TARGETING, DRAGGING }

signal pointer_mode_changed(mode: PointerMode)

var _selected_unit: Unit = null
var _pointer_mode: PointerMode = PointerMode.BROWSE


func set_selected_unit(unit: Unit) -> void:
	if _selected_unit and _selected_unit != unit:
		_selected_unit.select.force_deselect()
	_selected_unit = unit
	if unit:
		unit.select.force_select()
	EventBus.unit_selected.emit(unit)


func clear_selection() -> void:
	if _selected_unit:
		_selected_unit.select.force_deselect()
	_selected_unit = null
	set_pointer_mode(PointerMode.BROWSE)
	EventBus.unit_deselected.emit()


func get_selected_unit() -> Unit:
	return _selected_unit


func set_pointer_mode(mode: PointerMode) -> void:
	if _pointer_mode == mode:
		return
	_pointer_mode = mode
	pointer_mode_changed.emit(mode)


func get_pointer_mode() -> PointerMode:
	return _pointer_mode


## Vrai quand le curseur désigne une case de destination.
func wants_tile_cursor() -> bool:
	return _pointer_mode == PointerMode.TARGETING or _pointer_mode == PointerMode.DRAGGING


## Rend le mode, mais seulement si on est bien celui qui l'a pris — sans quoi un
## panneau pourrait rendre un mode posé par un autre. Le repos n'est pas toujours
## l'exploration : une unité sélectionnée laisse son panneau d'actions ouvert.
func release_pointer_mode(from: PointerMode) -> void:
	if _pointer_mode != from:
		return
	set_pointer_mode(
		PointerMode.CHOOSING_ACTION if _selected_unit else PointerMode.BROWSE)
