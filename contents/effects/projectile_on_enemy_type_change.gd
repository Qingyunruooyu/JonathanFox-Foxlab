extends "res://effects/items/projectile_effect.gd"

const BOSS_DAMAGE_BONUS = 10

static func get_id() -> String:
	return "foxlab_projectile_on_enemy_type_change"

func apply(player_index: int) -> void:
	var effect: Array = RunData.get_player_effect(key_hash, player_index)
	var first_apply = effect.empty()
	.apply(player_index)
	if first_apply:
		effect.append(BOSS_DAMAGE_BONUS)

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	var bonus_bounce = RunData.foxlab_current_different_enemies
	var bounce = str(int(args[2]) + bonus_bounce - 1)
	args[2] = bounce
	args.append(str(BOSS_DAMAGE_BONUS))
	return args
