extends "res://effects/items/double_key_value_effect.gd"

static func get_id() -> String:
	return "foxlab_set_stat"

func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	var times = effects[key2_hash]
	var prev_value = RunData.get_stat(key_hash, player_index)
	if storage_method == StorageMethod.REPLACE:
		effects[key_hash] = (times * value / value2) as int
	else:
		effects[key_hash] += (times * value / value2) as int
	var after_value = RunData.get_stat(key_hash, player_index)
	Utils.reset_stat_cache(player_index)
	RunData.emit_signal("stat_added", key_hash, after_value - prev_value, 0.0, player_index)

func unapply(_player_index: int) -> void:
	pass

func get_args(_player_index: int) -> Array:
	if value2 == 1:
		return .get_args(_player_index)
	return [ str((value / (value2 as float) - 1) * 100 as int), tr(key.to_upper()), str(value2), tr(key2.to_upper())]
