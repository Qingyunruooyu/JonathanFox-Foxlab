extends "res://effects/items/projectile_effect.gd"

static func get_id() -> String:
	return "foxlab_projectile_on_enemy_type_change"

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	var bonus_bounce = RunData.foxlab_current_different_enemies
	var bounce = str(int(args[2]) + bonus_bounce)
	args[2] = bounce
	# 对头目的奖励伤害没有100%，是10%
	args.append("10")
	return args
