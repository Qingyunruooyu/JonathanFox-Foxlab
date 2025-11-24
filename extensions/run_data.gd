extends "res://singletons/run_data.gd"

func get_next_level_xp_needed(player_index) -> float:
	var xp_needed = .get_next_level_xp_needed(player_index)
	if xp_needed > 0:
		return xp_needed
	# 防止需要的经验不是正数，导致无限升级爆栈
	var xp_needed_effect = max(get_player_effect("next_level_xp_needed", player_index), -99)
	return get_xp_needed(get_player_level(player_index) + 1) * (1.0 + xp_needed_effect / 100.0)

func add_starting_items_and_weapons() -> void :
	var effects = get_player_effects(0)
	.add_starting_items_and_weapons()
	effects["fox_wave_started"] = 1

func is_wave_started() -> bool:
	return get_player_effect_bool("fox_wave_started", 0)
