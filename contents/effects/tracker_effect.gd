extends  "res://effects/items/turret_effect.gd"

var tracker = preload("res://mods-unpacked/JonathanFox-FoxLab/contents/entities/structures/turret/tracker/tracker.gd")

static func get_id() -> String:
	return "foxlab_tracker"

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	var max_range = tracker.get_max_range_melee_weapon_range(stats, player_index)
	args.push_back(str(max_range))
	return args
