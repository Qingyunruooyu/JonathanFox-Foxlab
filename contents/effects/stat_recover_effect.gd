class_name FoxLabStatRecoverEffect
extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_effect_stat_recover"

func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	base_value = effects[key_hash]

func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key_hash] = base_value
	Utils.reset_stat_cache(player_index)
