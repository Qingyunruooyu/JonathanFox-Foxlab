extends "res://main.gd"

#全局杀敌获得属性
var foxlab_enemy_killed_this_wave := [0, 0, 0, 0]
#基于当前属性值的击杀（分段）
var foxlab_enemy_killed_this_wave_piecewise := [{}, {}, {}, {}]
var foxlab_gain_stat_every_killed_enemies := [{}, {}, {}, {}] #有上限限制的属性

#异变相关
var foxlab_mutate_chance:Array = [0, 0, 0, 0]
var foxlab_should_check_mutation:Array = [false, false, false, false]
var foxlab_bosses_this_wave = [0, 0, 0, 0]
const FOXLAB_STAT_MOD_CHANCE:float = 0.2
var foxlab_mutate_boost = ItemService.foxlab_enemy_boost_args.duplicate()

#贯通改为反弹相关
var foxlab_original_piercing = [0, 0, 0, 0]

func _ready():
	foxlab_receive_item_stat_ready()
	foxlab_mutation_ready()
	foxlab_piercing_is_bounce_ready()
	foxlab_gain_stat_every_killed_enemies_ready()

########### 波次开始获得东西相关 ##############
func foxlab_receive_item_stat_ready():
	for player_index in _players.size():
		var player = _players[player_index]
		var full_health = (player.current_stats.health == player.max_stats.health)
		var pre_health = player.current_stats.health
		var need_reset_player: bool = false
		# value, foxlab_receive_item_id, foxlab_receive_item_wave, curse_factor, is_cursed, end_wave
		var receive_item_effects: Array = RunData.get_player_effect(Utils.foxlab_effect_receive_item_at_wave_hash, player_index)
		if not receive_item_effects.empty():
			# Cache
			var _item = ItemService.get_item_from_id(Keys.item_alien_eyes_hash)

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
							if actual_item_data.my_id_hash == Keys.item_axolotl_hash:
								for effect in actual_item_data.effects:
									if effect is SwapMaxMinStatEffect:
										effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
							RunData.add_item(actual_item_data, player_index)

						_floating_text_manager.display_icon(receive_item_effect[0], item_data.icon, _floating_text_manager.stat_pos_sounds, _floating_text_manager.stat_neg_sounds, player.global_position - Vector2(0, 50), _floating_text_manager.direction, -10.0)

						need_reset_player = true

			for remove_entry in remove_array:
				receive_item_effects.erase(remove_entry)

		# [key, value, starting_wave, end_wave]
		var stats_end_of_wave_after_wave: Array = RunData.get_player_effect(Utils.foxlab_stats_end_of_wave_after_wave_hash, player_index)
		if not stats_end_of_wave_after_wave.empty():
			var remove_array: = []
			for j in stats_end_of_wave_after_wave.size():
				var eff = stats_end_of_wave_after_wave[j]
				if RunData.current_wave == int(eff[2]):
					var effect_items: Array = RunData.get_player_effect(Keys.stats_end_of_wave_hash, player_index)
					var has_effect: bool = false
					for existing_item in effect_items:
						if existing_item[0] == eff[0]:
							existing_item[1] += int(eff[1])
							has_effect = true
							break
					if not has_effect:
						effect_items.append([eff[0], int(eff[1])])
				if RunData.current_wave == (int(eff[3]) + 1):
					var effect_items: Array = RunData.get_player_effect(Keys.stats_end_of_wave_hash, player_index)
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
			# 重置cache用，不然武器伤害之类的不会更新
			RunData.add_stat(Keys.enemy_health_hash, 0, player_index)
			player.update_player_stats(true)
			if not full_health:
				player.current_stats.health = min(pre_health, player.current_stats.health)
			player.emit_signal("health_updated", player, player.current_stats.health, player.max_stats.health)

########### 异变相关 ###############
func foxlab_mutation_ready():
	for i in RunData.get_player_count():
		foxlab_mutate_chance[i] = max(0, RunData.get_player_effect(Utils.foxlab_mutate_alive_enemy_hash, i))
		if foxlab_mutate_chance[i]:
			foxlab_should_check_mutation[i] = true
			continue
		for structure_effect in RunData.get_player_effect(Keys.structures_hash, i):
			if foxlab_should_check_mutation[i]:
				continue
			for effect in structure_effect.effects:
				if effect.key_hash == Utils.foxlab_mutate_alive_enemy_hash or effect.custom_key_hash == Utils.foxlab_mutate_alive_enemy_hash:
					foxlab_should_check_mutation[i] = true
					break
		for weapon in RunData.get_player_weapons(i):
			if foxlab_should_check_mutation[i]:
				continue
			for effect in weapon.effects:
				if effect.key_hash == Utils.foxlab_mutate_alive_enemy_hash or effect.custom_key_hash == Utils.foxlab_mutate_alive_enemy_hash:
					foxlab_should_check_mutation[i] = true
					break

func _on_enemy_took_damage_foxlab(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void :
	if enemy._pending_die:
		for i in range(WeaponService.foxlab_spawn_landmines_on_enemy_death_count(args.hitbox, args.is_burning, args.from_player_index)):
			var pos = _entity_spawner.get_spawn_pos_in_area(enemy.global_position, 200)
			var queue = _entity_spawner.queues_to_spawn_structures[args.from_player_index]
			queue.push_back([EntityType.STRUCTURE, landmines_effect.scene, pos, landmines_effect])

		if _is_crit and args.hitbox.from is Structure :
			for effect in RunData.get_player_effect(Utils.foxlab_temp_stats_on_structure_crit_hash, args.from_player_index):
				TempStats.add_stat(effect[0], effect[1], args.from_player_index)

		return

	if enemy.is_boosted or args.from_player_index < 0 or args.from_player_index >= RunData.get_player_count() or not foxlab_should_check_mutation[args.from_player_index]:
		return

	var chance = foxlab_mutate_chance[args.from_player_index] / 100.0
	if is_instance_valid(args.hitbox):
		for effect in args.hitbox.from.effects if args.hitbox.from is Structure else args.hitbox.effects:
			if effect.key_hash == Utils.foxlab_mutate_alive_enemy_hash:
				chance += effect.value / 100.0
	if enemy is Boss:
		chance = chance * 0.08 / (1 + foxlab_bosses_this_wave[args.from_player_index])
	if Utils.get_chance_success(chance):
		foxlab_bosses_this_wave[args.from_player_index] += ItemService.foxlab_spawn_random_enemy(enemy, foxlab_bosses_this_wave[args.from_player_index], args.from_player_index)
		if RunData.get_player_effect_bool(Utils.foxlab_gain_stat_on_mutate_hash, args.from_player_index) and Utils.get_chance_success(chance):
			for i in range(1 + RunData.current_wave / 5):
				var add_mod :bool = Utils.get_chance_success(FOXLAB_STAT_MOD_CHANCE)
				var stat = Utils.get_rand_element(Utils.foxlab_primary_stat_gain_map.keys()) if add_mod else Utils.get_rand_element(Utils.foxlab_primary_stat_gain_map.values())
				var value = Utils.randi_range(3, 5) if add_mod else Utils.randi_range(1, 2)
				RunData.add_stat(stat, value, args.from_player_index)
				RunData.add_tracked_value(args.from_player_index, Utils.character_foxlab_refactor_hash, value, add_mod)
			var boost_enemy = _entity_spawner.get_rand_enemy()
			foxlab_mutate_boost.speed_boost =  0 if boost_enemy is Boss else ItemService.foxlab_enemy_boost_args.attack_speed_boost
			var pre_state = boost_enemy.can_be_boosted
			boost_enemy.can_be_boosted = true
			boost_enemy.boost(foxlab_mutate_boost)
			boost_enemy.can_be_boosted = pre_state

##########贯通改为反弹相关########
func foxlab_piercing_is_bounce_ready():
	for player_index in range(RunData.get_player_count()):
		if not RunData.get_player_effect_bool(Utils.foxlab_piercing_is_bounce_hash, player_index):
			continue
		var effects = RunData.get_player_effects(player_index)
		foxlab_original_piercing[player_index] = effects[Keys.pierce_on_crit_hash]
		if foxlab_original_piercing[player_index]:
			effects[Keys.pierce_on_crit_hash] = 0
			effects[Keys.bounce_on_crit_hash] += foxlab_original_piercing[player_index]

func foxlab_gain_stat_every_killed_enemies_ready():
	for player_index in range(RunData.get_player_count()):
		var effects = RunData.get_player_effect(Utils.foxlab_gain_stat_every_killed_enemies_hash, player_index)
		for effect in effects:
			if effect.size() > 3:
				foxlab_gain_stat_every_killed_enemies[player_index][effect[0]] = 0
			if effect[2] <= 0:
				foxlab_enemy_killed_this_wave_piecewise[player_index][effect[0]] = 0

##############扩展################
func _on_WaveTimer_timeout() -> void :
	._on_WaveTimer_timeout()
	for player_index in range(RunData.get_player_count()):
		if foxlab_original_piercing[player_index]:
			var effects = RunData.get_player_effects(player_index)
			effects[Keys.pierce_on_crit_hash] += foxlab_original_piercing[player_index]
			effects[Keys.bounce_on_crit_hash] -= foxlab_original_piercing[player_index]

		if RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
			RunData.foxlab_forget_item(player_index)

func on_levelled_up(player_index: int) -> void :
	.on_levelled_up(player_index)
	var effects = RunData.get_player_effects(player_index)
	effects[Keys.stat_levels_hash] = RunData.get_player_level(player_index)

	var bonus_crate = RunData.get_player_effect(Utils.foxlab_level_up_bonus_crate_hash, player_index)
	if bonus_crate < 1:
		return

	var upgrade = _upgrades_to_process[player_index].back()
	var consumable_tier = Tier.UNCOMMON
	if upgrade.level % 5 == 0:
		consumable_tier = Tier.LEGENDARY
	var consumable_to_drop = ItemService.get_consumable_for_tier(consumable_tier).duplicate()
	consumable_to_drop.icon = preload("res://mods-unpacked/JonathanFox-FoxLab/contents/items/characters/赏金猎人/cursed_chest.png")
	for i in range(bonus_crate):
		var consumable_to_process = UpgradesUI.ConsumableToProcess.new()
		consumable_to_process.consumable_data = consumable_to_drop
		consumable_to_process.player_index = player_index
		_consumables_to_process[player_index].push_back(consumable_to_process)
		_things_to_process_player_containers[player_index].consumables.add_element(consumable_to_drop)

func _on_HalfWaveTimer_timeout() -> void :
	._on_HalfWaveTimer_timeout()

	var multi_stats = RunData.concat_all_player_effects(Utils.foxlab_multiply_stats_half_wave_hash).size()
	if multi_stats or RunData.concat_all_player_effects(Utils.foxlab_always_convert_stats_half_wave_hash).size() > 0:
		_wave_timer_label.change_color(Color.deepskyblue)

	if multi_stats:
		var bg_changed: =false
		for i in range(RunData.get_player_count()):
			if RunData.get_player_gold(i) < 0:
				_wave_timer_label.change_color(Utils.CURSE_COLOR)
				_floating_text_manager.display("FOXLAB_MIDNIGHT", _floating_text_manager.players[i].global_position, Utils.CURSE_COLOR)
				var player_ui = _players_ui[i]
				player_ui.gold.gold_label.add_color_override("font_color", Utils.CURSE_COLOR)
				if not bg_changed:
					RunData.reset_background()
					_tile_map.tile_set.tile_set_texture(0, RunData.get_background().get_tiles_sprite())
					_tile_map.outline.modulate = RunData.get_background().outline_color
					MusicManager.play(0)
					bg_changed = true

	EntityService.reset_cache()

func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void :
	._on_enemy_died(enemy, args)
	if not _cleaning_up and args.enemy_killed_by_player and args.killed_by_player_index >= 0 and args.killed_by_player_index < RunData.get_player_count():
		var player_index = args.killed_by_player_index
		var player:Player = _players[player_index]
		for near_effect in RunData.get_player_effect(Utils.foxlab_heal_when_kill_nearby_hash, player_index):
			if not Utils.get_chance_success(near_effect[2] / 100.0):
				continue
			var dist_to_player = enemy.global_position.distance_to(player.global_position)
			if dist_to_player <= Utils.FOXLAB_BASE_NEARBY_KILL_DIST + WeaponService.sum_scaling_stat_values([[near_effect[0], near_effect[1]/100.0]], player_index):
				if player.on_healing_effect(1, Utils.item_foxlab_inner_indomitable_hash) <= 0:
					RunData.add_gold(1, player_index)
					RunData.add_tracked_value(player_index, Utils.item_foxlab_inner_indomitable_hash, 1, 1)
					_floating_text_manager.display("", enemy.global_position, Color.white, ItemService.foxlab_kill_nearby_icon, _floating_text_manager.duration, false, _floating_text_manager.direction, false)

		var effects = RunData.get_player_effect(Utils.foxlab_gain_stat_every_killed_enemies_hash, player_index)
		if not effects.empty():
			foxlab_enemy_killed_this_wave[player_index] += 1
			RunData.add_tracked_value(player_index, Utils.character_foxlab_bloody_wolf_hash, 1)
			for effect in effects:
				var num_killed = foxlab_enemy_killed_this_wave[player_index]
				var num = effect[2]
				if num <= 0:
					foxlab_enemy_killed_this_wave_piecewise[player_index][effect[0]] += 1
					num = max(1, RunData.get_player_effect(effect[0], player_index))
					num_killed = foxlab_enemy_killed_this_wave_piecewise[player_index][effect[0]]
				if num_killed % (num as int) == 0:
					if effect.size() > 3:
						if foxlab_gain_stat_every_killed_enemies[player_index][effect[0]] >= effect[3]:
							continue
						else:
							foxlab_gain_stat_every_killed_enemies[player_index][effect[0]] += effect[1]
					RunData.add_stat(effect[0], effect[1], player_index)
					if effect[2] <= 0:
#						DebugService.log_data("num: %d, num_killed: %d, total: %d" % [num, num_killed, foxlab_enemy_killed_this_wave[player_index]])
						foxlab_enemy_killed_this_wave_piecewise[player_index][effect[0]] = 0


func _on_EntitySpawner_enemy_spawned(enemy: Enemy) -> void :
	._on_EntitySpawner_enemy_spawned(enemy)
	var _error_took_damage = enemy.connect("took_damage", self, "_on_enemy_took_damage_foxlab")


