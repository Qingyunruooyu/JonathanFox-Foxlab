extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_all_or_nothing"

func apply_effects_core(player_index: int, apply: bool):
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
		if apply:
			effect.apply(player_index)
		else:
			effect.unapply(player_index)

func apply(player_index: int) -> void:
	apply_effects_core(player_index, true)

func unapply(player_index: int) -> void:
	apply_effects_core(player_index, false)


