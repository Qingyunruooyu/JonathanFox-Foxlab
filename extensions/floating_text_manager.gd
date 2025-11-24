extends "res://visual_effects/floating_text/floating_text_manager.gd"

func get_stat_modified(stat: String):
	if stat.begins_with("gain_"):
		stat.erase(0, 5)
	if stat.begins_with("structure"):
		return "stat_" + stat
	if stat.begins_with("fox_poet"):
		stat = "stat_curse"
	return stat

func is_fox_ignored_stats(stat: String):
	return stat.begins_with("fox")


func on_stat_added(stat: String, value: int, db_mod: float, player_index: int, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	stat = get_stat_modified(stat)
	if is_fox_ignored_stats(stat):
		return
	.on_stat_added(stat, value, db_mod, player_index, pos_sounds, neg_sounds)


func on_stat_removed(stat: String, value: int, db_mod: float, player_index: int, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	stat = get_stat_modified(stat)
	if is_fox_ignored_stats(stat):
		return
	.on_stat_removed(stat, value, db_mod, player_index, pos_sounds, neg_sounds)
