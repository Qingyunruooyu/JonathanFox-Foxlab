class_name FoxLabStatsOnFrozenEnemyKill
extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_effect_stats_on_frozen_enemy_kill"

func get_args(_player_index: int) -> Array:
	var ret = .get_args(_player_index)
	ret.append(str(Utils.FOXLAB_FROZEN_SPEED))
	return ret