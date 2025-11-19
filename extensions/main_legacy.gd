extends "res://main.gd"

var foxlab_mutate_chance:Array = [0, 0, 0, 0]
var should_check_mutation:Array = [false, false, false, false]
var primary_stat_keys:Array = []
const enemy_stat_keys:Array = ["enemy_damage", "enemy_damage",  "enemy_damage", "enemy_health", "enemy_health", "enemy_speed"]

func _ready():
	for i in RunData.get_player_count():
		foxlab_mutate_chance[i] = max(0, RunData.get_player_effect("foxlab_mutate_alive_enemy", i))
		if foxlab_mutate_chance[i]:
			should_check_mutation[i] = true
			continue
		for structure_effect in RunData.get_player_effect("structures", i):
			if should_check_mutation[i]:
				continue
			for effect in structure_effect.effects:
				if effect.key == "foxlab_mutate_alive_enemy" or effect.custom_key == "foxlab_mutate_alive_enemy":
					should_check_mutation[i] = true
					break
		for weapon in RunData.get_player_weapons(i):
			if should_check_mutation[i]:
				continue
			for effect in weapon.effects:
				if effect.key == "foxlab_mutate_alive_enemy" or effect.custom_key == "foxlab_mutate_alive_enemy":
					should_check_mutation[i] = true
					break
	for check in should_check_mutation:
		if check:
			for key in Utils.get_primary_stat_keys():
				primary_stat_keys.append("gain_" + key)
			break

func _on_enemy_took_damage(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int) -> void :
	._on_enemy_took_damage(enemy, _value, _knockback_direction, _is_crit, _is_dodge, _is_protected, _armor_did_something, args, _hit_type)
	if enemy.dead and _is_crit and args.hitbox.from is Structure :
		for effect in RunData.get_player_effect("temp_stats_on_structure_crit", args.from_player_index):
			TempStats.add_stat(effect[0], effect[1], args.from_player_index)

	if enemy.dead or not should_check_mutation[args.from_player_index]:
		return

	var chance = foxlab_mutate_chance[args.from_player_index] / 100.0
	if is_instance_valid(args.hitbox):
		for effect in args.hitbox.from.effects if args.hitbox.from is Structure else args.hitbox.effects:
			if effect.key == "foxlab_mutate_alive_enemy":
				chance += effect.value / 100.0
	if enemy is Boss:
		chance = chance * 0.08
	if Utils.get_chance_success(chance):
		ItemService.foxlab_spawn_random_enemy(enemy, args.from_player_index)
		if RunData.get_player_effect_bool("foxlab_gain_stat_on_mutate", args.from_player_index) and Utils.get_chance_success(chance):
			for i in range(1 + RunData.current_wave / 5):
				RunData.add_stat(Utils.get_rand_element(enemy_stat_keys), 1, args.from_player_index)
				var value = Utils.randi_range(3, 3 + RunData.current_wave / 5)
				RunData.add_stat(Utils.get_rand_element(primary_stat_keys), value, args.from_player_index)
				RunData.add_tracked_value(args.from_player_index, "character_foxlab_refactor", value)



