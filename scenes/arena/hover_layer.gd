# hover_layer.gd
extends CanvasLayer

var shader_material: ShaderMaterial
var hovered_cells: Array[Vector2i] = []

func _ready():
	var shader = preload("res://assets/shaders/tile_hover.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	material = shader_material

func set_hover_cell(cell: Vector2i, tile_size: Vector2):
	var tween = create_tween()
	tween.tween_method(
		_update_shader_position, 
		shader_material.get_shader_parameter("hover_pos"),
		Vector2(cell) * tile_size,
		0.2
	).set_trans(Tween.TRANS_CUBIC)

func _update_shader_position(pos: Vector2):
	shader_material.set_shader_parameter("hover_pos", pos)
