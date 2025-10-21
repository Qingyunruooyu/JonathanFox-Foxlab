extends "res://singletons/run_data.gd"

func get_next_level_xp_needed(player_index) -> float:
	return max(1, .get_next_level_xp_needed(player_index))


func add_starting_items_and_weapons() -> void :
	var effects = get_player_effects(0)
	.add_starting_items_and_weapons()
	effects["fox_无脸_wave_started"] = 1

func is_wave_started() -> bool:
	return get_player_effect_bool("fox_无脸_wave_started", 0)
