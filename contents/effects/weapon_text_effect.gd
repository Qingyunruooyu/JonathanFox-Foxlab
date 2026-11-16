extends "res://effects/weapons/null_effect.gd"

static func get_id() -> String:
	return "foxlab_weapon_text"

func get_args(_player_index: int) -> Array:
	return [str(value), key]
