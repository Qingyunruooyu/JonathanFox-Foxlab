extends "res://visual_effects/floating_text/floating_text_manager.gd"


func get_stat_modified(stat: int):
	if stat in Utils.foxlab_primary_stat_gain_map:
		return Utils.foxlab_primary_stat_gain_map[stat]
	if stat in Utils.foxlab_structure_stats:
		return Utils.foxlab_structure_stats[stat]
	if stat == Utils.fox_poet_next_curse_chance_hash:
		return Keys.curse_locked_items_hash
	return stat

func is_fox_ignored_stats(stat: int):
	return stat in Utils.foxlab_ignored_floating_stat_hash

func on_stat_added(stat: int, value: int, db_mod: float, player_index: int, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	stat = get_stat_modified(stat)
	if is_fox_ignored_stats(stat):
		return
	.on_stat_added(stat, value, db_mod, player_index, pos_sounds, neg_sounds)


func on_stat_removed(stat: int, value: int, db_mod: float, player_index: int, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	stat = get_stat_modified(stat)
	if is_fox_ignored_stats(stat):
		return
	.on_stat_removed(stat, value, db_mod, player_index, pos_sounds, neg_sounds)
