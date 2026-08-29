extends Node

## Ce que le curseur est en train de faire. Le surligneur de case ne doit
## s'afficher que pendant l'exploration : quand un panneau d'actions est ouvert
## on choisit une commande, pas une case ; et pendant un ciblage, c'est la
## portée qui dessine son propre retour.
enum PointerMode { BROWSE, CHOOSING_ACTION, TARGETING }

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


## Vrai quand le curseur explore librement le terrain.
func is_browsing() -> bool:
	return _pointer_mode == PointerMode.BROWSE
