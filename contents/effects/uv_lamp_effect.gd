extends  "res://effects/items/turret_effect.gd"

static func get_id() -> String:
	return "foxlab_uv_lamp"

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	_init_stats_args_turret.effects = effects
	var init_stats = WeaponService.init_structure_stats(stats, player_index, _init_stats_args_turret)
	args.push_back(str(init_stats.max_range))
	return args
