class_name DugoutItem
extends Control

## Vignette d'un joueur dans une boîte du dugout : icône, numéro, infobulle.
## Ce n'est pas un nœud Unit — le joueur n'en a un que sur le terrain.

const ITEM_SIZE := Vector2(48, 48)
const NUMBER_HEIGHT := 16
const BACKGROUND := Color(0, 0, 0, 0.28)
const HOVER_BACKGROUND := Color(1, 1, 1, 0.16)

signal drag_requested(item: DugoutItem)

var entry: MatchState.Entry

var _icon: TextureRect
var _number: Label
var _hovered := false


func _init() -> void:
	custom_minimum_size = ITEM_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_bottom = -NUMBER_HEIGHT
	add_child(_icon)

	_number = Label.new()
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_number.add_theme_font_size_override("font_size", 12)
	_number.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_number.offset_top = -NUMBER_HEIGHT
	add_child(_number)

	mouse_entered.connect(func(): _hovered = true; queue_redraw())
	mouse_exited.connect(func(): _hovered = false; queue_redraw())
	_refresh()


func setup(match_entry: MatchState.Entry) -> void:
	entry = match_entry
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if entry == null:
		return
	_icon.texture = entry.get_icon()
	_number.text = str(entry.number)
	tooltip_text = "%d — %s" % [entry.number, entry.get_display_name()]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HOVER_BACKGROUND if _hovered else BACKGROUND, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		drag_requested.emit(self)
		accept_event()
