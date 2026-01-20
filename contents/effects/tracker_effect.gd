class_name FoxLabTrackerEffect
extends  "res://effects/items/turret_effect.gd"

var tracker = preload("res://mods-unpacked/JonathanFox-FoxLab/contents/entities/structures/turret/tracker/tracker.gd")

static func get_id() -> String:
	return "foxlab_effect_tracker"

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	var max_range = tracker.get_max_range_melee_weapon_range(stats, player_index)
	args.push_back(str(max_range))
	return args

func unapply(player_index: int) -> void :
	var effects = RunData.get_player_effects(player_index)["structures"]
	var num =  effects.size()
	.unapply(player_index)
	var num_after =  effects.size()
	if num_after < num:
		return
	for effect in effects:
		if effect.get_id() == get_id() and effect.text_key == text_key and\
			 effect.get_args(player_index) == get_args(player_index):
			effects.erase(effect)
			return
