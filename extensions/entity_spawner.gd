extends "res://global/entity_spawner.gd"
func on_group_spawn_timing_reached(group_data: WaveGroupData) -> void :
	if group_data.is_neutral:
		for player_index in RunData.get_player_count():
			if RunData.get_player_effect_bool("foxlab_no_trees", player_index):
				return
	.on_group_spawn_timing_reached(group_data)

func on_enemy_charmed(enemy: Entity) -> void :
	.on_enemy_charmed(enemy)
	if enemy is Boss:
		for effect_behavior in enemy.effect_behaviors.get_children():
			if "charmed" in effect_behavior:
				effect_behavior._charm_timer.start(max(_wave_timer.time_left - 5, Utils.CHARM_DURATION))
