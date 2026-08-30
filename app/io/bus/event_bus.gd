extends Node

# --- Arena ---
signal grid_visibility_toggled
signal pitch_orientation_toggled

# --- Unit ---
signal unit_selected(unit: Node)
signal unit_deselected
signal unit_moved(unit: Node, from: Vector2i, to: Vector2i)
signal unit_right_clicked(unit: Node)
## Action demandée depuis le panneau contextuel d'un joueur.
signal player_action_requested(action: int, unit: Node)
signal player_selected_for_skill(player: BloodBowlData.Player, index: int)

# --- Team Building
signal team_selected 
signal star_selected(star:BloodBowlData.StarPlayer)
signal star_deselected(star:BloodBowlData.StarPlayer)

# --- Game flow ---
signal game_started
signal turn_changed(team_index: int, turn_number: int)
signal game_phase_changed(new_phase: SceneOrchestrator.GameStatus)

# --- UI / Navigation ---
signal scene_change_requested(scene_path: String)
