extends "res://singletons/linked_stats.gd"

func foxlab_check_update(player_index: int):
	if update_for_player_every_half_sec[player_index]:
		return
	var effects = RunData.get_player_effects(player_index)
	for linked_stat in effects[Keys.stat_links_hash]:
		var stat_scaled:int  = linked_stat[2]
		var perm_stats_only: bool = linked_stat[4]
		if Utils.is_stat_key(stat_scaled) and perm_stats_only == false:
			update_for_player_every_half_sec[player_index] = true

# 扩展
#站立不动、移动时
func reset_player(player_index: int) -> void :
	.reset_player(player_index)

	var actual_nb_scaled_cache = {}
	var effects = RunData.get_player_effects(player_index)
	for linked_stat in effects[Keys.stat_links_hash]:
		var stat_to_tweak: int = linked_stat[0]
		var nb_stat_to_tweak: = int(linked_stat[1])
		var stat_scaled: int = linked_stat[2]
		var nb_stat_scaled: = int(linked_stat[3])
		var actual_nb_scaled: = 0.0
		if actual_nb_scaled_cache.has(stat_scaled):
			actual_nb_scaled = actual_nb_scaled_cache[stat_scaled]
		elif stat_scaled == Utils.foxlab_living_structure_hash:
			actual_nb_scaled = RunData.foxlab_current_living_structures
			actual_nb_scaled_cache[stat_scaled] = actual_nb_scaled
			update_for_player_every_half_sec[player_index] = true
		var amount_to_add: = int(nb_stat_to_tweak * (actual_nb_scaled / nb_stat_scaled))
		add_stat(stat_to_tweak, amount_to_add, player_index)

	foxlab_check_update(player_index)