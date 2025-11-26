extends "res://singletons/utils.gd"

func convert_stats(stats: Array, player_index: int, permanent: bool = true) -> void :
	# 敌袭结束时，在恶魔转换执行之前执行尾数转换
	if permanent: #敌袭结束
		convert_remainder(RunData.get_player_effect("fox_convert_remainder_end_of_wave", player_index), player_index)
		for effect in RunData.get_player_effect("foxlab_always_convert_stats_end_of_wave", player_index):
			.convert_stats([effect], player_index, permanent)
	else: #敌袭中途
		for effect in RunData.get_player_effect("foxlab_always_convert_stats_half_wave", player_index):
			.convert_stats([effect], player_index, permanent)
	.convert_stats(stats, player_index, permanent)

func convert_remainder(stats: Array, player_index:int):
	if stats.empty():
		return
	for stat_to_convert in stats:
		var pct_converted:float = stat_to_convert[0]/100.0
		var stat_name :String= stat_to_convert[1]
		var stat_dividend :int= stat_to_convert[2]
		var remainder_offset:int = stat_to_convert[3]
		var keep_value = stat_to_convert[4]
		var to_stat:String = stat_to_convert[5]
		var to_stat_scaling:float= stat_to_convert[6]
		var storage_method = stat_to_convert[7]
		var is_negative_key:bool = stat_to_convert[8]

		var stat_value :int = 0
		if stat_name == "materials":
			stat_value = RunData.get_player_gold(player_index)
		elif stat_name == "random":
			stat_value = Utils.randi()
		else:
			stat_value = RunData.get_stat(stat_name, player_index) as int
		stat_value = (stat_value * pct_converted) as int
		if stat_value != 0 and stat_value < 0 != is_negative_key:
			continue
		var stat_remainder = stat_value if stat_dividend == 0 else stat_value % stat_dividend
		stat_remainder += remainder_offset
		var actual_stat_added = round(stat_remainder * to_stat_scaling) as int
		var stat_added_gain = RunData.get_stat_gain(to_stat, player_index)
		if stat_added_gain > 0.0:
			actual_stat_added = round(actual_stat_added / stat_added_gain) as int

		if storage_method == Effect.StorageMethod.REPLACE:
			if to_stat in ["lock_current_weapons", "disable_item_locking", "item_steals"]:
				actual_stat_added = max(0, actual_stat_added)
			RunData.get_player_effects(player_index)[to_stat] = actual_stat_added
		else:
			RunData.get_player_effects(player_index)[to_stat] += actual_stat_added
		if actual_stat_added != 0:
			RunData.emit_signal("stat_added", to_stat, actual_stat_added, 0.0, player_index)

		DebugService.log_data("remainder stat: %s, stat_value: %d, stat_dividend: %d, remainder: %d, actual_stat_added: %d, to_stat: %s" %
				[stat_name, stat_value, stat_dividend, stat_remainder, actual_stat_added, to_stat ])

		if keep_value == 1 or stat_name == "random":
			continue

		if keep_value == 0:
			RunData.get_player_effects(player_index)[stat_name] = 0
			continue

		var actual_stat_removed = stat_remainder
		var stat_removed_gain = RunData.get_stat_gain(stat_name, player_index)
		if stat_removed_gain > 0.0:
			actual_stat_removed = round(stat_remainder / stat_removed_gain) as int
		if stat_name == "materials":
			RunData.remove_gold(actual_stat_removed, player_index)
		else:
			RunData.remove_stat(stat_name, actual_stat_removed, player_index)

