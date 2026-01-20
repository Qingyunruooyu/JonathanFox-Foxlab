class_name FoxLabMultiplyStatEffect
extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_effect_multiply_stat"

func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	var effect_items: Array = effects[custom_key]
	for existing_item in effect_items:
		if existing_item[0] == key:
			existing_item[1] *= value / 100.0
			return
	effect_items.push_back([key, value / 100.0])

func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	var effect_items: Array = effects[custom_key]
	for i in effect_items.size():
		var effect_item = effect_items[i]
		if effect_item[0] == key:
			effect_item[1] /= value / 100.0
			if is_equal_approx(1.00, effect_item[1]):
				effect_items.remove(i)
			return

func get_args(_player_index: int) -> Array:
	var multi_value = stepify(value / 100.0, 0.01)
	return [ str(multi_value), str(tr(key.to_upper()))]
