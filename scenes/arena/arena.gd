class_name Arena
extends Node2D

const UNIT_SCENE = preload("res://scenes/unit/unit.tscn")

@onready var blue_reserves: TileMapLayer = $"visuals/Sidezones-blue/blue-reserves"
@onready var play_area: PlayArea = $PlayArea

func _ready() -> void:
	EventBus.game_phase_changed.connect(_on_game_phase_changed)

func _on_game_phase_changed(new_phase: GameStatusManager.GameStatus) -> void:
	if new_phase == GameStatusManager.GameStatus.READY_TO_RUN:
		_spawn_team_in_reserves()

func _spawn_team_in_reserves() -> void:
	var cells := blue_reserves.get_used_cells()
	var cell_index := 0
	var composition := TeamState.get_composition()

	for player: BloodBowlData.Player in composition:
		var count: int = composition[player]
		for i in count:
			if cell_index >= cells.size():
				push_warning("Plus de place dans les réserves")
				return
			var unit := UNIT_SCENE.instantiate()
			var tile_center := blue_reserves.map_to_local(cells[cell_index])
			unit.position = to_local(blue_reserves.to_global(tile_center - Vector2(105, 105)))
			add_child(unit)
			unit.drag_and_drop.tilemap_layer = play_area
			unit.skin.texture = player.get_blue_icon_texture()
			cell_index += 1
