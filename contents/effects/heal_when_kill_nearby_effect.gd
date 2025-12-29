class_name FoxLabHealWhenKillNearby
extends DoubleValueEffect

static func get_id() -> String:
	return "foxlab_effect_heal_when_kill_nearby"

func get_args(_player_index: int) -> Array:
	var distance = Utils.FOXLAB_BASE_NEARBY_KILL_DIST + WeaponService.sum_scaling_stat_values([[key, value/100.0]], _player_index)
	return [str(stepify(distance, 0.01)), key, str(value2)]

