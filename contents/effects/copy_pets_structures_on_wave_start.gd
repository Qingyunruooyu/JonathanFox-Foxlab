extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_copy_pets_structures_on_wave_start"

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	args.append(str(RunData.get_player_effect(key_hash, player_index)))
	args.append(str(Utils.FOXLAB_COPY_PETS_STRUCTURES_DELAY))
	return args
