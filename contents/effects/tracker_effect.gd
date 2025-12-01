class_name FoxLabTrackerEffect
extends FoxLabTurretEffect

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	var max_range = FoxLabTracker.get_max_range_melee_weapon_range(stats, player_index)
	args.push_back(str(max_range))
	return args
