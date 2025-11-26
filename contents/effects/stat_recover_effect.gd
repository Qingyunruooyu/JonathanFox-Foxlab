class_name FoxLabStatRecoverEffect
extends Effect

static func get_id() -> String:
	return "foxlab_effect_stat_recover"

func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	base_value = effects[key]

func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key] = base_value
	Utils.reset_stat_cache(player_index)
