extends "res://main.gd"

func on_levelled_up(player_index: int) -> void :
	.on_levelled_up(player_index)
	var effects = RunData.get_player_effects(player_index)
	effects["stat_levels"] = RunData.get_player_level(player_index)


func _on_enemy_took_damage(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void :
	._on_enemy_took_damage(enemy, _value, _knockback_direction, _is_crit, _is_dodge, _is_protected, _armor_did_something, args, _hit_type, _is_one_shot)
	if enemy.dead and _is_crit and args.hitbox.from is Structure :
		for effect in RunData.get_player_effect("temp_stats_on_structure_crit", args.from_player_index):
			TempStats.add_stat(effect[0], effect[1], args.from_player_index)

