extends "res://singletons/run_data.gd"

func get_next_level_xp_needed(player_index) -> float:
	return max(1, .get_next_level_xp_needed(player_index))
