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

func manage_harvesting() -> void :
	for player_index in RunData.get_player_count():
		# 官方代码纰漏：铁砧升级的时候没有用get_player_effect_bool("lock_current_weapons")，导致负数也被认为是true
		# 薛定谔的猫可能会有负数的lock_current_weapons，会让善战者自带的铁砧总是-100%伤害
		var effects = RunData.get_player_effects(player_index)
		if effects["lock_current_weapons"] < 0:
			effects["lock_current_weapons"] = 0
	.manage_harvesting()