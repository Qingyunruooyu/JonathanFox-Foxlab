extends "res://singletons/linked_stats.gd"

#站立不动、移动时
func reset_player(player_index: int) -> void :
	.reset_player(player_index)
	if update_for_player_every_half_sec[player_index]:
		return
	var effects = RunData.get_player_effects(player_index)
	for linked_stat in effects[Keys.stat_links_hash]:
		var stat_scaled:int  = linked_stat[2]
		var perm_stats_only: bool = linked_stat[4]
		if Utils.is_stat_key(stat_scaled) and perm_stats_only == false:
			update_for_player_every_half_sec[player_index] = true
