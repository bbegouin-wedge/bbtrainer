# dashed_border_rect.gd
extends ColorRect

@export var playArea: PlayArea
@export var enabled: bool = false

@export_group("Rect Settings")
@export var rect_size: Vector2 = Vector2(210, 210):
	set(value):
		rect_size = value
		custom_minimum_size = value
		_update_shader()

@export var border_width: float = 5.0:
	set(value):
		border_width = value
		_update_shader()

@export var corner_radius: float = 20.0:
	set(value):
		corner_radius = value
		_update_shader()

@export var border_color: Color = Color.WHITE:
	set(value):
		border_color = value
		_update_shader()

@export var background_color: Color = Color(0.2, 0.2, 0.741, 0.302):
	set(value):
		background_color = value
		_update_shader()

@export_group("Dash Settings")
@export var dash_length: float = 20.0:
	set(value):
		dash_length = value
		_update_shader()

@export var gap_length: float = 10.0:
	set(value):
		gap_length = value
		_update_shader()

@export var animation_speed: float = 30.0:
	set(value):
		animation_speed = value
		_update_shader()

var shader_material: ShaderMaterial

func _ready():
	if !enabled:
		return
	custom_minimum_size = rect_size
	
	var shader = load("res://assets/shaders/dashed_border.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	material = shader_material
	
	_update_shader()
	
func _process(_delta: float) -> void:	
	if !enabled:
		return
		
	if playArea.is_tile_in_bounds(playArea.get_hovered_tile()):
		position = playArea.get_top_left_tile_coords()

func _update_shader():
	if not shader_material:
		return
	
	shader_material.set_shader_parameter("rect_size", rect_size)
	shader_material.set_shader_parameter("border_width", border_width)
	shader_material.set_shader_parameter("corner_radius", corner_radius)
	shader_material.set_shader_parameter("border_color", border_color)
	shader_material.set_shader_parameter("bg_color", background_color)
	shader_material.set_shader_parameter("dash_length", dash_length)
	shader_material.set_shader_parameter("gap_length", gap_length)
	shader_material.set_shader_parameter("animation_speed", animation_speed)
