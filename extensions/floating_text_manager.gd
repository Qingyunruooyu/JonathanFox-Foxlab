extends "res://visual_effects/floating_text/floating_text_manager.gd"


func get_stat_modified(stat: int):
	if stat in Utils.foxlab_primary_stat_gain_map:
		return Utils.foxlab_primary_stat_gain_map[stat]
	if stat in Utils.foxlab_structure_stats:
		return Utils.foxlab_structure_stats[stat]
	return stat

func is_fox_ignored_stats(stat: int):
	return stat in Utils.foxlab_ignored_floating_stat_hash

func on_stat_added(stat: int, value: int, db_mod: float, player_index: int, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	if stat == Utils.fox_poet_next_curse_chance_hash and not players[player_index].dead:
		var current = RunData.get_player_effect(stat, player_index) % 100
		display(str(current) + "%", players[player_index].global_position, Utils.CURSE_COLOR, ItemService.get_stat_icon(Keys.curse_locked_items_hash))
		if current < value:
			if neg_sounds.size() > 0:
				SoundManager.play(Utils.get_rand_element(neg_sounds), - 8 + db_mod, 0.2, true)
		else:
			if pos_sounds.size() > 0:
				SoundManager.play(Utils.get_rand_element(pos_sounds), - 3 + db_mod, 0.2, true)
		return
	stat = get_stat_modified(stat)
	if is_fox_ignored_stats(stat):
		return
	.on_stat_added(stat, value, db_mod, player_index, pos_sounds, neg_sounds)


func on_stat_removed(stat: int, value: int, db_mod: float, player_index: int, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	stat = get_stat_modified(stat)
	if is_fox_ignored_stats(stat):
		return
	.on_stat_removed(stat, value, db_mod, player_index, pos_sounds, neg_sounds)
