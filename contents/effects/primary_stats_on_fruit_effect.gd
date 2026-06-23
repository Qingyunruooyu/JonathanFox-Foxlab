extends "res://mods-unpacked/JonathanFox-FoxLab/contents/base_effects/batch_apply_effect.gd"

static func get_id() -> String:
	return "foxlab_stats_on_fruit"

func apply_effects_core(player_index: int, call_func: String):
	var level_up_map = Utils.foxlab_get_primary_stat_level_up_map()[0]
	var effect = DoubleValueEffect.new()
	effect.custom_key_hash = Keys.stats_on_fruit_hash
	effect.storage_method = StorageMethod.KEY_VALUE
	effect.value2 = value
	for stat in level_up_map.keys():
		effect.key = Keys.hash_to_string[stat]
		effect.key_hash = stat
		effect.value = level_up_map[effect.key_hash]
		effect.call(call_func, player_index)




