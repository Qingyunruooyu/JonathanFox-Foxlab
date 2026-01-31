class_name FoxLabGainStatEveryKilledEnemies
extends "res://effects/items/double_value_effect.gd"


static func get_id() -> String:
	return "foxlab_effect_gain_stat_every_killed_enemies"

func get_args(_player_index: int) -> Array:
	var number = value2
	if value2 <= 0:
		number = max(1, RunData.get_player_effect(key_hash, _player_index))
	return [str(value), tr(key.to_upper()), str(number)]
