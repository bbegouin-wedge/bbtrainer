extends Label

@export var playArea: PlayArea
@onready var hoveredTileLabel: Label = Label.new()

func _ready():
	label_settings = putSettings()
	hoveredTileLabel.label_settings = putSettings()
	add_child(hoveredTileLabel)
	hoveredTileLabel.position = Vector2(get_screen_top_left().x, get_screen_top_left().y + 50)

func get_screen_top_left() -> Vector2:
	var viewport_size = get_viewport_rect().size
	
	# Coin haut-gauche en coordonnées monde
	var top_left = Vector2(0,0)
	return top_left

func putSettings() -> LabelSettings:
	var setting = LabelSettings.new()
	setting.font_size = 48
	setting.font_color = Color(1,1,0.3,1)
	label_settings = setting
	return setting
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var hovered_tile = playArea.get_hovered_tile()
	
	var hoveredTileText = "hovered tile : X: %d, Y: %d" % [hovered_tile.x, hovered_tile.y]
	var globalMouseText = "global mouse pos : X: %d, Y: %d" % [mouse_pos.x, mouse_pos.y]
	text = globalMouseText
	hoveredTileLabel.text = hoveredTileText
	
	
