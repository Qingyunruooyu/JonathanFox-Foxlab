extends "res://main.gd"

#全局杀敌获得属性
var foxlab_enemy_killed_this_wave := [0, 0, 0, 0]

#异变相关
var foxlab_mutate_chance:Array = [0, 0, 0, 0]
var foxlab_should_check_mutation:Array = [false, false, false, false]
var primary_stat_keys:Array = []
var primary_mod_keys:Array = []
var bosses_this_wave = 0
const ENEMY_STAT_KEYS:Array = ["enemy_damage", "enemy_damage",  "enemy_damage", "enemy_health", "enemy_health", "stronger_elites_on_kill", "stronger_elites_on_kill", "enemy_speed"]
const STAT_MOD_CHANCE:float = 0.2

func _ready():
	foxlab_receive_item_stat_ready()
	foxlab_mutation_ready()

########### 波次开始获得东西相关 ##############
func foxlab_receive_item_stat_ready():
	for player_index in _players.size():
		var player = _players[player_index]

		var need_reset_player: bool = false
		# value, foxlab_receive_item_id, foxlab_receive_item_wave, curse_factor, is_cursed, end_wave
		var receive_item_effects: Array = RunData.get_player_effect("foxlab_effect_receive_item_at_wave", player_index)
		if not receive_item_effects.empty():
			# Cache
			var _item = ItemService.get_item_from_id("item_acid")

			var remove_array: Array = []
			for receive_item_effect in receive_item_effects:
				if receive_item_effect[2] <= RunData.current_wave:
					var end_wave = -1
					if receive_item_effect.size() > 5:
						end_wave = receive_item_effect[5]
					if end_wave <= 0:
						remove_array.push_back(receive_item_effect)
					elif end_wave < RunData.current_wave:
						remove_array.push_back(receive_item_effect)
						continue

					var item_data = ItemService.get_element(ItemService.items, receive_item_effect[1])
					if not item_data == null:
						var is_cursed: bool = receive_item_effect[4]
						var dlc = null
						var actual_item_data = item_data

						if is_cursed:
							dlc = ProgressData.get_dlc_data("abyssal_terrors")

						for i in receive_item_effect[0]:
							if dlc:
								actual_item_data = dlc.curse_item(item_data, player_index, false)
							if actual_item_data.my_id == "item_axolotl":
								for effect in actual_item_data.effects:
									if effect is SwapMaxMinStatEffect:
										effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
							RunData.add_item(actual_item_data, player_index)

						_floating_text_manager.display_icon(receive_item_effect[0], item_data.icon, _floating_text_manager.stat_pos_sounds, _floating_text_manager.stat_neg_sounds, player.global_position - Vector2(0, 50), _floating_text_manager.direction, -10.0)

						need_reset_player = true

			for remove_entry in remove_array:
				receive_item_effects.erase(remove_entry)

		# [key, value, starting_wave, end_wave]
		var stats_end_of_wave_after_wave: Array = RunData.get_player_effect("foxlab_stats_end_of_wave_after_wave", player_index)
		if not stats_end_of_wave_after_wave.empty():
			var remove_array: = []
			for j in stats_end_of_wave_after_wave.size():
				var eff = stats_end_of_wave_after_wave[j]
				if RunData.current_wave == int(eff[2]):
					var effect_items: Array = RunData.get_player_effect("stats_end_of_wave", player_index)
					var has_effect: bool = false
					for existing_item in effect_items:
						if existing_item[0] == eff[0]:
							existing_item[1] += int(eff[1])
							has_effect = true
							break
					if not has_effect:
						effect_items.append([eff[0], int(eff[1])])
				if RunData.current_wave == (int(eff[3]) + 1):
					var effect_items: Array = RunData.get_player_effect("stats_end_of_wave", player_index)
					for i in effect_items.size():
						var effect_item = effect_items[i]
						if effect_item[0] == eff[0]:
							effect_item[1] -= eff[1]
							if effect_item[1] == 0:
								effect_items.remove(i)
							break

					remove_array.push_back(eff)
			for j in remove_array:
				stats_end_of_wave_after_wave.erase(j)

		if need_reset_player:
			player.update_player_stats(true)


########### 异变相关 ###############
func foxlab_mutation_ready():
	bosses_this_wave = 0
	for i in RunData.get_player_count():
		foxlab_mutate_chance[i] = max(0, RunData.get_player_effect("foxlab_mutate_alive_enemy", i))
		if foxlab_mutate_chance[i]:
			foxlab_should_check_mutation[i] = true
			continue
		for structure_effect in RunData.get_player_effect("structures", i):
			if foxlab_should_check_mutation[i]:
				continue
			for effect in structure_effect.effects:
				if effect.key == "foxlab_mutate_alive_enemy" or effect.custom_key == "foxlab_mutate_alive_enemy":
					foxlab_should_check_mutation[i] = true
					break
		for weapon in RunData.get_player_weapons(i):
			if foxlab_should_check_mutation[i]:
				continue
			for effect in weapon.effects:
				if effect.key == "foxlab_mutate_alive_enemy" or effect.custom_key == "foxlab_mutate_alive_enemy":
					foxlab_should_check_mutation[i] = true
					break
	for check in foxlab_should_check_mutation:
		if check:
			for key in Utils.get_primary_stat_keys():
				primary_mod_keys.append("gain_" + key)
				primary_stat_keys.append(key)
			break

func _on_enemy_took_damage_foxlab(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void :
	_process_when_enemy_take_damage(enemy, _is_crit, args)

func _on_enemy_took_damage_foxlab_legacy(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int) -> void :
	_process_when_enemy_take_damage(enemy, _is_crit, args)

func _process_when_enemy_take_damage(enemy: Enemy, _is_crit: bool, args: TakeDamageArgs):
	if enemy.dead and _is_crit and args.hitbox.from is Structure :
		for effect in RunData.get_player_effect("temp_stats_on_structure_crit", args.from_player_index):
			TempStats.add_stat(effect[0], effect[1], args.from_player_index)

	if enemy.dead or args.from_player_index < 0 or args.from_player_index >= RunData.get_player_count() or not foxlab_should_check_mutation[args.from_player_index]:
		return

	var chance = foxlab_mutate_chance[args.from_player_index] / 100.0
	if is_instance_valid(args.hitbox):
		for effect in args.hitbox.from.effects if args.hitbox.from is Structure else args.hitbox.effects:
			if effect.key == "foxlab_mutate_alive_enemy":
				chance += effect.value / 100.0
	if enemy is Boss:
		chance = chance * 0.08 / (1 + bosses_this_wave / 1.2)
	if Utils.get_chance_success(chance):
		bosses_this_wave += ItemService.foxlab_spawn_random_enemy(enemy, bosses_this_wave, args.from_player_index)
		if RunData.get_player_effect_bool("foxlab_gain_stat_on_mutate", args.from_player_index) and Utils.get_chance_success(chance):
			for i in range(1 + RunData.current_wave / 5):
				RunData.add_stat(Utils.get_rand_element(ENEMY_STAT_KEYS), Utils.randi_range(1, 1 + RunData.current_wave / 13), args.from_player_index)
				var stat = Utils.get_rand_element(primary_mod_keys) if Utils.get_chance_success(STAT_MOD_CHANCE) else Utils.get_rand_element(primary_stat_keys)
				var value = Utils.randi_range(3, 3 + RunData.current_wave / 5) if stat.begins_with("gain_") else Utils.randi_range(1,2)
				RunData.add_stat(stat, value, args.from_player_index)
				RunData.add_tracked_value(args.from_player_index, "character_foxlab_refactor", value)

##############扩展################
func on_levelled_up(player_index: int) -> void :
	.on_levelled_up(player_index)
	var effects = RunData.get_player_effects(player_index)
	effects["stat_levels"] = RunData.get_player_level(player_index)

func _on_HalfWaveTimer_timeout() -> void :
	._on_HalfWaveTimer_timeout()

	for i in range(RunData.get_player_count()):
		if RunData.get_player_gold(i) < 0:
			_wave_timer_label.change_color(Utils.CURSE_COLOR)
			_floating_text_manager.display("FOXLAB_MIDNIGHT", _floating_text_manager.players[i].global_position, Utils.CURSE_COLOR)
			var player_ui: PlayerUIElements = _players_ui[i]
			player_ui.gold.gold_label.add_color_override("font_color", Utils.CURSE_COLOR)

	EntityService.reset_cache()

func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void :
	._on_enemy_died(enemy, args)
	if not _cleaning_up and args.enemy_killed_by_player and args.killed_by_player_index >= 0 and args.killed_by_player_index < RunData.get_player_count():
		var player_index = args.killed_by_player_index
		var effects = RunData.get_player_effect("foxlab_gain_stat_every_killed_enemies", player_index)
		if not effects.empty():
			foxlab_enemy_killed_this_wave[player_index] += 1
			RunData.add_tracked_value(player_index, "character_foxlab_bloody_wolf", 1)
			for effect in effects:
				if foxlab_enemy_killed_this_wave[player_index] % effect[2] == 0:
					RunData.add_stat(effect[0], effect[1], player_index)

func _on_EntitySpawner_enemy_spawned(enemy: Enemy) -> void :
	._on_EntitySpawner_enemy_spawned(enemy)
	if ItemService.FOXLAB_IS_NEW_DAWN:
		var _error_took_damage = enemy.connect("took_damage", self, "_on_enemy_took_damage_foxlab")
	else:
		var _error_took_damage = enemy.connect("took_damage", self, "_on_enemy_took_damage_foxlab_legacy")


