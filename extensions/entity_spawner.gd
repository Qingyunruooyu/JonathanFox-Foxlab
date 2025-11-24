extends "res://global/entity_spawner.gd"
func on_group_spawn_timing_reached(group_data: WaveGroupData) -> void :
	if group_data.is_neutral:
		for player_index in RunData.get_player_count():
			if RunData.get_player_effect_bool("foxlab_no_trees", player_index):
				return
	.on_group_spawn_timing_reached(group_data)
