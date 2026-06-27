extends "res://singletons/linked_stats.gd"

# 扩展
#站立不动、移动时，飞毛腿+沙发+盐水时
func reset_player(player_index: int) -> void :
	.reset_player(player_index)

	var actual_nb_scaled_cache = {}
	var actual_nb_scaled_cache_bugged = {}
	var effects = RunData.get_player_effects(player_index)
	for linked_stat in effects[Keys.stat_links_hash]:
		var stat_to_tweak: int = linked_stat[0]
		var nb_stat_to_tweak: = int(linked_stat[1])
		var stat_scaled: int = linked_stat[2]
		var nb_stat_scaled: = int(linked_stat[3])
		var perm_stats_only: bool = linked_stat[4]
		var actual_nb_scaled: = 0.0
		if actual_nb_scaled_cache.has([stat_scaled, perm_stats_only]):
			actual_nb_scaled = actual_nb_scaled_cache[[stat_scaled, perm_stats_only]]
		else:
			if stat_scaled == Utils.foxlab_living_structure_hash:
				actual_nb_scaled = RunData.foxlab_current_living_structures
				update_for_player_every_half_sec[player_index] = true
			else:
				if Utils.is_stat_key(stat_scaled):
					update_for_player_every_half_sec[player_index] = true
					if perm_stats_only == true:
						actual_nb_scaled = RunData.get_stat(stat_scaled, player_index)
					else:
						actual_nb_scaled = RunData.get_stat(stat_scaled, player_index) + TempStats.get_stat(stat_scaled, player_index)
				else:
					continue
			actual_nb_scaled_cache[[stat_scaled, perm_stats_only]] = actual_nb_scaled
			if not stat_scaled in actual_nb_scaled_cache_bugged:
				actual_nb_scaled_cache_bugged[stat_scaled] = actual_nb_scaled

		var amount_to_add: = int(nb_stat_to_tweak * (actual_nb_scaled / nb_stat_scaled))
		var amount_to_minus: = int(nb_stat_to_tweak * (actual_nb_scaled_cache_bugged[stat_scaled] / nb_stat_scaled))
		if amount_to_add != amount_to_minus:
			add_stat(stat_to_tweak, amount_to_add - amount_to_minus, player_index)

