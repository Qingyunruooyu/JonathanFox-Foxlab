extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_enemy_interact"

func get_args(_player_index: int) -> Array:
	return [str(value), str(Utils.FOXLAB_SEED_DURATION + RunData.current_living_enemies / Utils.FOXLAB_LIVING_ENEMY_DURATION_BOOST)]
