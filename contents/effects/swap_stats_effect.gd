extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_swap_stats"

func apply(player_index: int) -> void:
	var stats_in_container = Utils.foxlab_get_stats_in_container()
	for stats in stats_in_container:
		var range_seq = null
		if value >= 0:
			range_seq = range(0, stats.size() - 1)
		else:
			range_seq = range(stats.size() - 2, -1, -1)
		for i in range_seq:
			swap_stat(stats[i], stats[i+1], player_index)

static func swap_stat(left_stat_key: int, right_stat_key: int, player_index: int)->bool:
	var left_stat_gain = RunData.get_stat_gain(left_stat_key, player_index)
	if left_stat_gain == 0:
		return false
	var right_stat_gain = RunData.get_stat_gain(right_stat_key, player_index)
	if right_stat_gain == 0:
		return false
	print("swap ", Keys.hash_to_string[left_stat_key], ", ", Keys.hash_to_string[right_stat_key])
	var effects = RunData.get_player_effects(player_index)
	var left_stat_temp = TempStats.get_stat(left_stat_key, player_index)
	var right_stat_temp = TempStats.get_stat(right_stat_key, player_index)
	var left_stat_linked = LinkedStats.get_stat(left_stat_key, player_index)
	var right_stat_linked = LinkedStats.get_stat(right_stat_key, player_index)

	var left_stat_value = Utils.get_stat(left_stat_key, player_index)
	var right_stat_value = Utils.get_stat(right_stat_key, player_index)

	var new_left_permanent = (right_stat_value - left_stat_temp - left_stat_linked) / left_stat_gain
	var new_right_permanent = (left_stat_value - right_stat_temp - right_stat_linked) / right_stat_gain

	effects[left_stat_key] = new_left_permanent
	effects[right_stat_key] = new_right_permanent
	Utils.reset_stat_cache(player_index)
	return true

func unapply(_player_index: int) -> void:
	pass
