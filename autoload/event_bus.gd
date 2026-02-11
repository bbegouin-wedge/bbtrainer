extends Node

# --- Arena ---
signal grid_visibility_toggled
signal pitch_orientation_toggled

# --- Unit ---
signal unit_selected(unit: Node)
signal unit_deselected
signal unit_moved(unit: Node, from: Vector2i, to: Vector2i)

# --- Team Building
signal team_selected 

# --- Game flow ---
signal game_started
signal turn_changed(team_index: int, turn_number: int)
signal game_phase_changed(new_phase: GameStatusManager.GameStatus)

# --- UI / Navigation ---
signal scene_change_requested(scene_path: String)
