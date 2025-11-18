extends "res://main.gd"

var foxlab_mutate_chance:Array = [0, 0, 0, 0]
var should_check_mutation:Array = [false, false, false, false]
func _ready():
	for i in RunData.get_player_count():
		foxlab_mutate_chance[i] = max(0, RunData.get_player_effect("foxlab_mutate_alive_enemy", i))
		if foxlab_mutate_chance[i]:
			should_check_mutation[i] = true
			continue
		for structure_effect in RunData.get_player_effect("structures", i):
			for effect in structure_effect.effects:
				if effect.key == "foxlab_mutate_alive_enemy" or effect.custom_key == "foxlab_mutate_alive_enemy":
					should_check_mutation[i] = true
					continue
		for weapon in RunData.get_player_weapons(i):
			for effect in weapon.effects:
				if effect.key == "foxlab_mutate_alive_enemy" or effect.custom_key == "foxlab_mutate_alive_enemy":
					should_check_mutation[i] = true
					continue

func _on_enemy_took_damage(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void :
	._on_enemy_took_damage(enemy, _value, _knockback_direction, _is_crit, _is_dodge, _is_protected, _armor_did_something, args, _hit_type, _is_one_shot)
	if enemy.dead and _is_crit and args.hitbox.from is Structure :
		for effect in RunData.get_player_effect("temp_stats_on_structure_crit", args.from_player_index):
			TempStats.add_stat(effect[0], effect[1], args.from_player_index)

	if not enemy.dead and should_check_mutation[args.from_player_index]:
		var chance = foxlab_mutate_chance[args.from_player_index] / 100.0
		if is_instance_valid(args.hitbox):
			var effects: Array = []
			if args.hitbox.from is Structure:
				effects = args.hitbox.from.effects
			else:
				effects = args.hitbox.effects
			for effect in effects:
				if effect.key == "foxlab_mutate_alive_enemy":
					chance += effect.value / 100.0
		if enemy is Boss:
			chance = chance / 10.0
		if Utils.get_chance_success(chance):
			ItemService.foxlab_spawn_random_enemy(enemy, args.from_player_index)

