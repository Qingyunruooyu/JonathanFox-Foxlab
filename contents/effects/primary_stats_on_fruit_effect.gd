extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_stats_on_fruit"

func apply_effects_core(player_index: int, apply: bool):
	var level_up_map = Utils.foxlab_get_primary_stat_level_up_map()
	var effect = DoubleValueEffect.new()
	effect.custom_key_hash = Keys.stats_on_fruit_hash
	effect.storage_method = StorageMethod.KEY_VALUE
	effect.value2 = value
	for stat in level_up_map.keys():
		effect.key = Keys.hash_to_string[stat]
		effect.key_hash = stat
		effect.value = level_up_map[effect.key_hash]
		if apply:
			effect.apply(player_index)
		else:
			effect.unapply(player_index)


func apply(player_index: int) -> void:
	apply_effects_core(player_index, true)

func unapply(player_index: int) -> void:
	apply_effects_core(player_index, false)


