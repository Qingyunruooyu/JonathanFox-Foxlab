extends "res://mods-unpacked/JonathanFox-FoxLab/contents/base_effects/batch_apply_effect.gd"

static func get_id() -> String:
	return "foxlab_all_or_nothing"

func apply_effects_core(player_index: int, call_func: String):
	var effect = DoubleValueEffect.new()
	effect.key_hash = key_hash
	effect.key = key
	effect.custom_key_hash = custom_key_hash
	effect.storage_method = StorageMethod.KEY_VALUE
	for i in range(1, value + 1):
		effect.value2 = i
		effect.value = 2*i - 1
		if i&1:
			effect.value *= -1
		effect.call(call_func, player_index)



