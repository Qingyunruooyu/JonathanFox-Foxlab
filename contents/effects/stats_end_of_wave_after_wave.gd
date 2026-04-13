extends "res://items/global/effect.gd"


export (int) var starting_wave: int = 6
export (int) var end_wave: int = 19

static func get_id() -> String:
	return "foxlab_stats_end_of_wave_after_wave"


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized["starting_wave"] = starting_wave
	serialized["end_wave"] = end_wave

	return serialized


func deserialize_and_merge(effect: Dictionary) -> void:
	.deserialize_and_merge(effect)

	starting_wave = effect.get("starting_wave", 6)
	end_wave = effect.get("end_wave", 19)


func apply(player_index: int) -> void:
	if end_wave > 0 and starting_wave > end_wave:
		return

	var effect_array: Array = RunData.get_player_effect(Utils.foxlab_stats_end_of_wave_after_wave_hash, player_index)

	for existing_item in effect_array:
		if existing_item[0] == key_hash and existing_item[2] == starting_wave and existing_item[3] == end_wave:
			existing_item[1] += value
			return

	effect_array.push_back([key_hash, value, starting_wave, end_wave])


func unapply(player_index: int) -> void:
	if end_wave > 0 and starting_wave > end_wave:
		return

	var has_effect: bool = false
	var effect_array: Array = RunData.get_player_effect(Utils.foxlab_stats_end_of_wave_after_wave_hash, player_index)

	for i in effect_array.size():
		var eff = effect_array[i]
		if eff[0] == key_hash and eff[2] == starting_wave and eff[3] == end_wave:
			has_effect = true
			eff[1] -= value
			if eff[1] == 0:
				effect_array.remove(i)
				break

	if has_effect and RunData.current_wave >= starting_wave and RunData.current_wave <= end_wave:
		.unapply(player_index)


func get_args(_player_index: int) -> Array:
	var text_raw = Text.text("EFFECT_GAIN_STAT_END_OF_WAVE", [str(value), tr(key.to_upper())], [effect_sign, effect_sign])
	var args: = [
		str(starting_wave),
		text_raw if end_wave < 1 else text_raw + \
		Text.text("EFFECT_FOXLAB_STATS_END_OF_WAVE_BEFORE_WAVE", [str(end_wave)], [effect_sign])
	]
	return args
