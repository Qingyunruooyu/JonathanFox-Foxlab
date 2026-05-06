extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_gain_stat_for_primary_stat_item"

func apply_effects_core(player_index: int, apply: bool):
	var effect = DoubleKeyValueEffect.new()
	effect.custom_key_hash = custom_key_hash
	effect.storage_method = storage_method
	effect.key_hash = key_hash
	effect.value = value
	for stat in Utils.get_primary_stat_keys():
		effect.key2_hash = stat
		if apply:
			effect.apply(player_index)
		else:
			effect.unapply(player_index)

func apply(player_index: int) -> void:
	apply_effects_core(player_index, true)

func unapply(player_index: int) -> void:
	apply_effects_core(player_index, false)
