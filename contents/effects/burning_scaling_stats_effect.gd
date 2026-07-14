extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_burning_scaling_stats"

func apply(player_index: int) -> void:
	.apply(player_index)
	modify_global_burning(player_index, false)

func unapply(player_index: int) -> void:
	.unapply(player_index)
	modify_global_burning(player_index, true)

func modify_global_burning(player_index: int, sub: bool):
	var burn_chance_effect = RunData.get_player_effects(player_index)[Keys.burn_chance_hash]
	burn_chance_effect.scaling_stats = WeaponService.foxlab_apply_scaling_stat_effects([[key_hash, value]], burn_chance_effect.scaling_stats, sub)