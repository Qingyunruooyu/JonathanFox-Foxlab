extends "res://mods-unpacked/JonathanFox-FoxLab/contents/base_effects/batch_apply_effect.gd"

static func get_id() -> String:
	return "foxlab_gain_stat_for_primary_stat_item"

func apply_effects_core(player_index: int, call_func: String):
	var effect = DoubleKeyValueEffect.new()
	effect.custom_key_hash = custom_key_hash
	effect.storage_method = storage_method
	effect.key_hash = key_hash
	effect.value = value
	for stat in Utils.get_primary_stat_keys():
		effect.key2_hash = stat
		effect.call(call_func, player_index)

