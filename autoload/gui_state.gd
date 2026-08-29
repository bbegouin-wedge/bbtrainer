extends Node

var _selected_unit: Unit = null


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
	EventBus.unit_deselected.emit()


func get_selected_unit() -> Unit:
	return _selected_unit
