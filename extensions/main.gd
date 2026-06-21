extends "res://main.gd"

#全局杀敌获得属性
var foxlab_enemy_killed_this_wave := [0, 0, 0, 0]
var foxlab_boss_killed_this_wave := [0, 0, 0, 0]
#基于当前属性值的击杀（分段）
var foxlab_enemy_killed_this_wave_piecewise := [{}, {}, {}, {}]
var foxlab_gain_stat_every_killed_enemies := [{}, {}, {}, {}] #有上限限制的属性

#异变相关
var foxlab_mutate_chance:Array = [0, 0, 0, 0]
var foxlab_should_check_mutation:Array = [false, false, false, false]
var foxlab_bosses_this_wave = [0, 0, 0, 0]
const FOXLAB_STAT_MOD_CHANCE:float = 0.2
var foxlab_mutate_boost = [null, null, null, null]

#贯通改为反弹相关
var foxlab_original_piercing = [0, 0, 0, 0]

#超度相关
var foxlab_seed_timers = []
var foxlab_seed_numbers = [Utils.FOXLAB_SEED_PER_SECOND, Utils.FOXLAB_SEED_PER_SECOND, Utils.FOXLAB_SEED_PER_SECOND, Utils.FOXLAB_SEED_PER_SECOND]
var foxlab_next_gold_player: int

# 额外碰撞判定
var foxlab_should_check_extra_hit = false

func _ready():
	var _err = RunData.connect("foxlab_sec_char_changed", self, "_on_foxlab_sec_char_changed")
	_err = RunData.connect("foxlab_weapon_added", self, "_on_foxlab_weapon_added")
	_err = RunData.connect("foxlab_item_added", self, "_on_foxlab_item_added")
	_err = _end_wave_timer.connect("timeout", self, "_on_foxlab_EndWaveTimer_timeout")

	foxlab_receive_item_stat_ready()
	foxlab_mutation_ready()
	foxlab_piercing_is_bounce_ready()
	foxlab_gain_stat_every_killed_enemies_ready()
	foxlab_seed_timers_ready()
	foxlab_extra_hit_ready()

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
										effect.has_been_applied = false
										effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
							RunData.add_item(actual_item_data, player_index)
						_on_foxlab_item_added(actual_item_data, receive_item_effect[0], player_index)

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
			RunData._are_player_stats_dirty[player_index] = true
			player.update_player_stats(true)
			if not full_health:
				player.current_stats.health = min(pre_health, player.current_stats.health)
			player.emit_signal("health_updated", player, player.current_stats.health, player.max_stats.health)

########### 异变相关 ###############
func _foxlab_should_check_mutation(player_index: int)-> bool:
	foxlab_mutate_chance[player_index] = max(0, RunData.get_player_effect(Utils.foxlab_mutate_alive_enemy_hash, player_index))
	if foxlab_mutate_chance[player_index]:
		return true
	for structure_effect in RunData.get_player_effect(Keys.structures_hash, player_index):
		for effect in structure_effect.effects:
			if effect.key_hash == Utils.foxlab_mutate_alive_enemy_hash or effect.custom_key_hash == Utils.foxlab_mutate_alive_enemy_hash:
				return true
	for weapon in RunData.get_player_weapons_ref(player_index):
		for effect in weapon.effects:
			if effect.key_hash == Utils.foxlab_mutate_alive_enemy_hash or effect.custom_key_hash == Utils.foxlab_mutate_alive_enemy_hash:
				return true
	return false

func foxlab_mutation_ready():
	for i in RunData.get_player_count():
		foxlab_should_check_mutation[i] = _foxlab_should_check_mutation(i)
		if foxlab_should_check_mutation[i]:
			foxlab_mutate_boost[i] = BoostArgs.new()
			foxlab_mutate_boost[i].hp_boost = ItemService.foxlab_enemy_boost_args.hp_boost
			foxlab_mutate_boost[i].damage_boost = ItemService.foxlab_enemy_boost_args.damage_boost

func foxlab_seed_timers_ready():
	var timer_wait_time: = 1.0
	var player_count: int = RunData.get_player_count()
	var timer_delay: = timer_wait_time / player_count
	foxlab_next_gold_player = Utils.randi() % RunData.get_player_count()
	for player_index in RunData.get_player_count():
		if RunData.get_player_effect_bool(Utils.foxlab_enemy_interact_hash, player_index):
			var timer = Timer.new()
			timer.wait_time = timer_wait_time
			timer.autostart = true
			foxlab_seed_timers.append(timer)
			timer.connect("timeout", self, "_on_foxlab_seed_timer_timeout", [player_index])
			add_child(timer)
			if not get_tree().current_scene.name == "GutRunner":
				yield(get_tree().create_timer(timer_delay), "timeout")

func foxlab_extra_hit_ready():
	for i in RunData.get_player_count():
		if RunData.get_player_effect_bool(Utils.foxlab_extra_hit_hash, i):
			foxlab_should_check_extra_hit = true
			break

func _on_foxlab_seed_timer_timeout(player_index: int) -> void:
	foxlab_seed_numbers[player_index] = 0

func _on_enemy_took_damage_foxlab(enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool,\
		 _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void :
	enemy._die_args_unit.from = args.from
	if args.from_player_index < 0 or args.from_player_index >= RunData.get_player_count():
		return

	if enemy._pending_die:
		foxlab_process_landmine_on_death(enemy, args)
		foxlab_process_struct_crit_kill(_is_crit, args)
		_foxlab_process_frozen_unit_kill(enemy, args.from_player_index)
		return

	if not enemy.is_boosted and foxlab_should_check_mutation[args.from_player_index]:
		foxlab_process_enemy_mutate(enemy, args)

func _on_neutral_took_damage_foxlab(neutral, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, \
	_is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void :
	if neutral._pending_die and args.from_player_index >= 0 and args.from_player_index < RunData.get_player_count():
		_foxlab_process_frozen_unit_kill(neutral, args.from_player_index)

func foxlab_process_landmine_on_death(enemy, args: TakeDamageArgs):
	for _i in range(WeaponService.foxlab_spawn_landmines_on_enemy_death_count(args.hitbox, args.is_burning, args.from_player_index)):
		var pos = _entity_spawner.get_spawn_pos_in_area(enemy.global_position, 200)
		var queue = _entity_spawner.queues_to_spawn_structures[args.from_player_index]
		queue.push_back([EntityType.STRUCTURE, landmines_effect.scene, pos, landmines_effect])

func foxlab_process_struct_crit_kill(is_crit: bool, args: TakeDamageArgs):
	if is_crit and args.hitbox.from is Structure :
		for effect in RunData.get_player_effect(Utils.foxlab_temp_stats_on_structure_crit_hash, args.from_player_index):
			TempStats.add_stat(effect[0], effect[1], args.from_player_index)

func foxlab_process_enemy_mutate(enemy, args: TakeDamageArgs):
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
			var boost_enemy = Utils.get_rand_element(_entity_spawner.get_all_enemies(false))
			if not is_instance_valid(boost_enemy) or boost_enemy._pending_die:
				return

			foxlab_mutate_boost[args.from_player_index].speed_boost =  0 if boost_enemy is Boss else ItemService.foxlab_enemy_boost_args.attack_speed_boost
			var pre_state = boost_enemy.can_be_boosted
			boost_enemy.can_be_boosted = true
			boost_enemy.boost(foxlab_mutate_boost[args.from_player_index])
			boost_enemy.can_be_boosted = pre_state

			for _i in range(1 + RunData.current_wave / 5):
				var add_mod :bool = Utils.get_chance_success(FOXLAB_STAT_MOD_CHANCE)
				var stat = Utils.get_rand_element(Utils.foxlab_primary_stat_gain_map.keys()) if add_mod else Utils.get_rand_element(Utils.foxlab_primary_stat_gain_map.values())
				var value = Utils.randi_range(3, 5) if add_mod else Utils.randi_range(1, 2)
				RunData.add_stat(stat, value, args.from_player_index)
				RunData.add_tracked_value(args.from_player_index, Utils.character_foxlab_refactor_hash, value, add_mod)

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

# ref: func spawn_consumables(unit: Unit)，但是只要判定掉落消耗品，就会掉落箱子
func foxlab_spawn_crate(unit) -> bool:
	var consumable_to_spawn: ConsumableData = ItemService.get_consumable_to_drop(unit, 1.0)
	if consumable_to_spawn != null and consumable_to_spawn.my_id_hash in [Keys.consumable_item_box_hash, Keys.consumable_legendary_item_box_hash]:
		var consumable: Consumable = get_node_from_pool(_consumable_pool_id, _consumables_container)
		if consumable == null:
			consumable = consumable_scene.instance()
			_consumables_container.call_deferred("add_child", consumable)
			var _error = consumable.connect("picked_up", self, "on_consumable_picked_up")
			yield(consumable, "ready")

		consumable.already_picked_up = false
		consumable.consumable_data = consumable_to_spawn
		consumable.set_texture(consumable_to_spawn.icon)
		var pos = unit.global_position
		var dist = rand_range(50, 100 + unit.stats.gold_spread)
		var push_back_destination: Vector2 = ZoneService.get_rand_pos_in_area(pos, dist, 0)
		consumable.drop(pos, 0, push_back_destination)
		_consumables.push_back(consumable)
		return true
	return false

func foxlab_spawn_seed(unit, player_index: int):
	if foxlab_seed_numbers[player_index] >= Utils.FOXLAB_SEED_PER_SECOND:
		return
	foxlab_seed_numbers[player_index] += 1

	var consumable_to_spawn: ConsumableData = ItemService.foxlab_seed_data.duplicate()
	var effects = []
	for effect in consumable_to_spawn.effects:
		if effect.get_id() == "foxlab_seed":
			effects.append(Utils.foxlab_enemy_id_scene_map[unit.pool_id])
		else:
			effects.append(effect)
	consumable_to_spawn.effects = effects

	var consumable: Consumable = get_node_from_pool(_consumable_pool_id, _consumables_container)
	if consumable == null:
		consumable = consumable_scene.instance()
		_consumables_container.call_deferred("add_child", consumable)
		var _error = consumable.connect("picked_up", self, "on_consumable_picked_up")
		yield(consumable, "ready")

	consumable.already_picked_up = false
	consumable.consumable_data = consumable_to_spawn
	consumable.set_texture(unit.stats.icon)
	var pos = unit.global_position
	var dist: = rand_range(150, 200 + unit.stats.gold_spread)
	var push_back_destination: Vector2 = ZoneService.get_rand_pos_in_area(pos, dist, 0)
	consumable.drop(pos, rand_range(0.25*PI, 1.75*PI), push_back_destination)
	_consumables.push_back(consumable)
	RunData.add_tracked_value(player_index, Utils.item_foxlab_salvation_hash, 1, 1)

#面具弹出相关
func _on_foxlab_sec_char_changed(new_characters, player_index):
	var pos = _players[player_index].global_position - Vector2(0, 50)
	for character in new_characters:
		var icon = character.icon
		var icon_scale = Utils.foxlab_fit_item_icon_scale(character)
		_floating_text_manager.display("", pos, Color.white, icon, _floating_text_manager.duration * 2, true,  _floating_text_manager.direction, false, icon_scale)
		pos -= Vector2(30, 30)
	SoundManager2D.play(Utils.get_rand_element(_floating_text_manager.stat_pos_sounds), pos, -10)

#中途添加武器相关（佛手）
func _on_foxlab_weapon_added(new_weapon: WeaponData, player_index: int):
	var player = _players[player_index]
	if player.dead or player.cleaning_up:
		return

	for effect in new_weapon.effects:
		if effect.key_hash == Keys.hit_protection_hash and effect.value > 0 and effect.get_id() == Effect.get_id():
			player._hit_protection += effect.value

	foxlab_after_add_item({}, player_index)
	player.call_deferred("foxlab_add_weapon", new_weapon)
	_on_foxlab_item_added(new_weapon, 1, player_index)

func _on_foxlab_item_added(new_item, item_count: int, player_index: int):
	var player = _players[player_index]
	var icon_scale = Utils.foxlab_fit_item_icon_scale(new_item)
	var pos = player.global_position - 1.5 * _floating_text_manager.players_add_stats_count[player_index] * _floating_text_manager.offset
	_floating_text_manager.players_add_stats_count[player_index] += 1
	var text_str = ""
	var color:Color
	if item_count >= 0:
		text_str = "+" + str(item_count)
		color = Color(ProgressData.settings.color_positive)
		SoundManager2D.play(Utils.get_rand_element(_floating_text_manager.stat_pos_sounds), player.global_position, -10)
	else:
		text_str = str(item_count)
		color = Color(ProgressData.settings.color_negative)
		SoundManager2D.play(Utils.get_rand_element(_floating_text_manager.stat_neg_sounds), player.global_position, -15)
	if new_item.is_cursed:
		color = Utils.CURSE_COLOR
	_floating_text_manager.display(text_str, pos, color, new_item.icon,\
			_floating_text_manager.duration * 2.5, true,  _floating_text_manager.direction, false, icon_scale, player_index)

#击杀慢速敌人相关
func _foxlab_process_frozen_unit_kill(unit: Node2D, player_index: int):
	var velocity = unit._integrate_forces_velocity
	if not unit._can_move or velocity.length_squared() < Utils.FOXLAB_FROZEN_SPEED * Utils.FOXLAB_FROZEN_SPEED:
		var frozen_effect = RunData.get_player_effect(Utils.foxlab_stats_on_frozen_enemy_kill_hash, player_index)
		if not frozen_effect.empty():
			for effect in frozen_effect:
				RunData.add_stat(effect[0], effect[1], player_index)
				RunData.add_tracked_value(player_index, Utils.character_foxlab_stargazer_hash, effect[1])
#超度
func _foxlab_enemy_interact(enemy: Node2D):
	var sum: = 0
	for player_index in RunData.get_player_count():
		var value = RunData.get_player_effect(Utils.foxlab_enemy_interact_hash, player_index)
		if value > 0:
			RunData.add_gold(-value, foxlab_next_gold_player)
			foxlab_next_gold_player = (foxlab_next_gold_player + 1) % RunData.get_player_count()
			foxlab_spawn_seed(enemy, player_index)
			RunData.add_tracked_value(player_index, Utils.item_foxlab_salvation_hash, value, 0)
			sum += value
	if sum > 0:
		on_player_wanted_to_spawn_gold(sum, enemy.global_position, 100)

# 本波额外敌人
func foxlab_process_extra_enemies():
	var extra_enemies = 0
	for player_index in _players.size():
		for _i in range(Utils.get_stat(Utils.foxlab_extra_enemies_hash, player_index) as int):
			_wave_manager.add_groups(Utils.foxlab_pickup_random_group_data())
			extra_enemies += 1
		for _i in range(Utils.get_stat(Utils.foxlab_extra_crash_zone_enemies_hash, player_index) as int):
			_wave_manager.add_groups(Utils.foxlab_pickup_random_group_data("ZONE_CRASH_ZONE"))
			extra_enemies += 1
		for _i in range(Utils.get_stat(Utils.foxlab_extra_abyss_enemies_hash, player_index) as int):
			_wave_manager.add_groups(Utils.foxlab_pickup_random_group_data("ZONE_ABYSS"))
			extra_enemies += 1

		for _i in range(Utils.get_stat(Utils.foxlab_extra_bosses_hash, player_index) as int):
			_wave_manager.add_groups(Utils.foxlab_pickup_random_bosses())
		for _i in range(Utils.get_stat(Utils.foxlab_extra_unknown_elites_hash, player_index) as int):
			_wave_manager.add_groups(Utils.foxlab_pickup_random_elites(true))
		for _i in range(Utils.get_stat(Utils.foxlab_extra_elites_hash, player_index) as int):
			_wave_manager.add_groups(Utils.foxlab_pickup_random_elites(false))

		var extra_loot_aliens = Utils.get_stat(Utils.foxlab_extra_loot_aliens_hash, player_index) as int
		if extra_loot_aliens > 0:
			_wave_manager.add_groups(Utils.foxlab_generate_loot_alien_group_data(extra_loot_aliens, _wave_timer))
		var extra_evil_mobs = Utils.get_stat(Utils.foxlab_extra_evil_mobs_hash, player_index) as int
		if extra_evil_mobs > 0:
			_wave_manager.add_groups(Utils.foxlab_generate_evil_mob_group_data(extra_evil_mobs))

	_is_horde_wave = (extra_enemies > 4)

#待处理的经验，亏欠的生命值
func foxlab_process_pending_states():
	for player_index in _players.size():
		var effects = RunData.get_player_effects(player_index)
		var pending_xp = effects[Utils.foxlab_pending_xp_hash]
		if pending_xp > 0:
			RunData.add_xp(pending_xp, player_index)
		effects[Utils.foxlab_pending_xp_hash] = 0

		var player = _players[player_index]
		if player.foxlab_process_lost_hp():
			_on_player_health_updated(player, player.current_stats.health, player.max_stats.health)

# 只处理这几个简单的，其他还有非常多只在一开始就判定这一波要不要生效的，不再做处理了
func foxlab_before_add_item(player_index: int) ->Dictionary:
	var pre_states = {}
	for stat in [Keys.hit_protection_hash, Keys.lose_hp_per_second_hash, Keys.temp_stats_per_interval_hash]:
		pre_states[stat] = RunData.get_player_effect(stat, player_index)
	return pre_states

func foxlab_after_add_item(pre_states: Dictionary, player_index: int):
	var player = _players[player_index]
	for stat in [Keys.hit_protection_hash, Keys.lose_hp_per_second_hash, Keys.temp_stats_per_interval_hash]:
		var new_effect = RunData.get_player_effect(stat, player_index)
		match stat:
			Keys.hit_protection_hash:
				var old_effect = pre_states.get(stat)
				if old_effect!= null and new_effect > old_effect:
					player._hit_protection += (new_effect - old_effect)
			Keys.lose_hp_per_second_hash:
				if new_effect > 0 and player._lose_health_timer.is_stopped():
					player._lose_health_timer.start()
			Keys.temp_stats_per_interval_hash:
				if not new_effect.empty() and player._one_second_timer.is_stopped():
					player._one_second_timer.start()

func foxlab_get_item(item_id_hash: int, num: int, player_index: int):
	var item_data = ItemService.get_item_from_id(item_id_hash)
	if not item_data == null:
		var pre_states = foxlab_before_add_item(player_index)
		var displayed_item = item_data
		for _i in num:
			var actual_item_data = ItemService.apply_item_effect_modifications(item_data, player_index)
			if actual_item_data.my_id_hash == Keys.item_axolotl_hash:
				for effect in actual_item_data.effects:
					if effect is SwapMaxMinStatEffect:
						effect.has_been_applied = false
						effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
			RunData.add_item(actual_item_data, player_index)
			if actual_item_data.is_cursed:
				displayed_item = actual_item_data
		foxlab_after_add_item(pre_states, player_index)
		_on_foxlab_item_added(displayed_item, num, player_index)

##### 重复判定伤害 #####
func _on_foxlab_enemy_area_entered_deferred(hitbox: Area2D, enemy: Node2D):
	if not enemy._pending_die and hitbox.active and hitbox.deals_damage and\
		is_instance_valid(hitbox.from) and not hitbox.from is PlayerExplosion and\
		hitbox.from.player_index != -1:
		var extra_hit:int = RunData.get_player_effect(Utils.foxlab_extra_hit_hash, hitbox.from.player_index)
		if extra_hit > 0:
			var ignored_objects = hitbox.ignored_objects.duplicate()
			for _i in extra_hit:
				hitbox.ignored_objects.erase(enemy)
				enemy.hurt_area_entered_deferred(hitbox)
				if not hitbox.active:
					break
			hitbox.ignored_objects = ignored_objects

func _on_foxlab_enemy_Hurtbox_entered(hitbox: Area2D, enemy: Node2D):
	call_deferred("_on_foxlab_enemy_area_entered_deferred", hitbox, enemy)

func foxlab_change_turret_target(structure: Node2D):
	if EntityService.is_offensive(structure):
		var detect_range:Area2D = structure._range_shape.get_parent()
		detect_range.collision_mask = Utils.PLAYER_BIT
		var _err = detect_range.connect("body_entered", self, "_on_foxlab_turret_Range_body_entered", [structure])
		_err = detect_range.connect("body_exited", self, "_on_foxlab_turret_Range_body_exited", [structure])

func _on_foxlab_turret_Range_body_entered(body: Node, turret: Node) -> void :
	turret.add_outline(Color.skyblue)
	var _err = body.connect("died", self, "_on_foxlab_turret_target_died", [turret])

func _on_foxlab_turret_Range_body_exited(body: Node, turret: Node) -> void :
	body.disconnect("died", self, "_on_foxlab_turret_target_died")
	call_deferred("_foxlab_remove_turret_outline", turret)

func _on_foxlab_turret_target_died(_target: Node, _args: Entity.DieArgs, turret: Node) -> void :
	call_deferred("_foxlab_remove_turret_outline", turret)

func _foxlab_remove_turret_outline(turret: Node) -> void:
	if turret._targets_in_range.empty():
		turret.remove_outline(Color.skyblue)

func _on_foxlab_structure_died(_structure, _die_args) -> void:
	RunData.foxlab_current_living_structures -= 1

func _on_foxlab_EndWaveTimer_timeout() -> void :
	if not _is_wave_failed:
		for player_index in range(RunData.get_player_count()):
			if RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
				RunData.foxlab_forget_item(player_index)

##############扩展################
func _on_WaveTimer_timeout() -> void :
	for player_index in range(RunData.get_player_count()):
		var gain_effects = RunData.get_player_effect(Utils.foxlab_gain_scapegoat_no_hurt_hash, player_index)
		if gain_effects.empty() or RunData.foxlab_scapegoat_no_hurt[player_index].empty():
			continue
		for gain_effect in gain_effects:
			foxlab_get_item(gain_effect[0], gain_effect[1], player_index)

	._on_WaveTimer_timeout()
	for player_index in range(RunData.get_player_count()):
		if foxlab_original_piercing[player_index]:
			var effects = RunData.get_player_effects(player_index)
			effects[Keys.pierce_on_crit_hash] += foxlab_original_piercing[player_index]
			effects[Keys.bounce_on_crit_hash] -= foxlab_original_piercing[player_index]

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
	for _i in range(bonus_crate):
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
			if RunData.foxlab_is_midnight[i]:
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

	for i in range(RunData.get_player_count()):
		if RunData.get_stat(Keys.stat_curse_hash, i) < 0:
			_players[i].foxlab_add_curse_particle()

	EntityService.reset_cache()

func _on_enemy_died(enemy, args: Entity.DieArgs) -> void :
	._on_enemy_died(enemy, args)
	# print("killer: ", args.from, "is enemy: ", args.from is Enemy)
	if not args.cleaning_up and args.from is Enemy:
		_foxlab_enemy_interact(enemy)
	if not _cleaning_up and args.enemy_killed_by_player and args.killed_by_player_index >= 0 and args.killed_by_player_index < RunData.get_player_count():
		var player_index = args.killed_by_player_index
		for near_effect in RunData.get_player_effect(Utils.foxlab_heal_when_kill_nearby_hash, player_index):
			if not Utils.get_chance_success(near_effect[2] / 100.0):
				continue
			var player = _players[player_index]
			var dist_to_player = enemy.global_position.distance_squared_to(player.global_position)
			# 地雷、Bonk狗的爆炸可以监测，爆炸炮塔不行，原版代码没为受击之后触发的爆炸设置from，缺省设置成了PlayerExplosion
			if args.from is Pet or args.from is Structure:
				dist_to_player = min(enemy.global_position.distance_squared_to(args.from.global_position), dist_to_player)
			if dist_to_player <= pow(Utils.FOXLAB_BASE_NEARBY_KILL_DIST + WeaponService.sum_scaling_stat_values([[near_effect[0], near_effect[1]/100.0]], player_index), 2):
				if player.on_healing_effect(1, Utils.item_foxlab_inner_indomitable_hash) <= 0:
					RunData.add_gold(1, player_index)
					RunData.add_tracked_value(player_index, Utils.item_foxlab_inner_indomitable_hash, 1, 1)
					_floating_text_manager.display("", enemy.global_position - Vector2(40, 0), Color.white, ItemService.foxlab_kill_nearby_icon, \
						_floating_text_manager.duration, false, _floating_text_manager.direction, false)

		var effects = RunData.get_player_effect(Utils.foxlab_gain_stat_every_killed_enemies_hash, player_index)
		if not effects.empty():
			foxlab_enemy_killed_this_wave[player_index] += 1
			RunData.add_tracked_value(player_index, Utils.character_foxlab_bloody_wolf_hash, 1)
			for effect in effects:
				var num_killed = foxlab_enemy_killed_this_wave[player_index]
				var num = effect[2]
				if num <= 0:
					foxlab_enemy_killed_this_wave_piecewise[player_index][effect[0]] += 1
					num = max(1, abs(RunData.get_player_effect(effect[0], player_index)))
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

		effects = RunData.get_player_effect(Utils.foxlab_gain_stat_every_killed_bosses_hash, player_index)
		if enemy is Boss and not effects.empty():
			foxlab_boss_killed_this_wave[player_index] += 1
			for effect in effects:
				var num_killed = foxlab_boss_killed_this_wave[player_index]
				var num = effect[2]
				if num_killed % (num as int) == 0:
					RunData.add_stat(effect[0], effect[1], player_index)

func _on_EntitySpawner_enemy_spawned(enemy) -> void :
	._on_EntitySpawner_enemy_spawned(enemy)
	var _error_took_damage = enemy.connect("took_damage", self, "_on_enemy_took_damage_foxlab")
	if foxlab_should_check_extra_hit:
		var hurtbox = enemy.get_node("Hurtbox")
		var _err = hurtbox.connect("area_entered", self, "_on_foxlab_enemy_Hurtbox_entered", [enemy])

func _on_EntitySpawner_enemy_respawned(enemy) -> void :
	._on_EntitySpawner_enemy_respawned(enemy)
	if is_instance_valid(enemy.source_spawner) and enemy.source_spawner is Enemy and enemy.get_charmed_by_player_index() == -1:
		_foxlab_enemy_interact(enemy)

func _on_EntitySpawner_neutral_spawned(neutral) -> void :
	._on_EntitySpawner_neutral_spawned(neutral)
	var _error_took_damage = neutral.connect("took_damage", self, "_on_neutral_took_damage_foxlab")

func _on_EntitySpawner_players_spawned(players: Array) -> void :
	._on_EntitySpawner_players_spawned(players)
	foxlab_process_extra_enemies()
	foxlab_process_pending_states()

func _on_EntitySpawner_structure_spawned(structure) -> void :
	._on_EntitySpawner_structure_spawned(structure)
	var _error_died = structure.connect("died", self, "_on_foxlab_structure_died")
	if RunData.get_player_effect_bool(Utils.foxlab_turret_target_hash, structure.player_index):
		call_deferred("foxlab_change_turret_target", structure)

func _on_EntitySpawner_structure_respawned(structure):
	._on_EntitySpawner_structure_respawned(structure)
	RunData.foxlab_current_living_structures += 1

func on_upgrade_selected(upgrade_data: UpgradeData, upgrade) -> void :
	if upgrade_data.has_meta("foxlab_item"):
		RunData.add_item(upgrade_data.get_meta("foxlab_item"), upgrade.player_index)
	else:
		.on_upgrade_selected(upgrade_data, upgrade)

func clean_up_room() -> void :
	.clean_up_room()
	for timer in foxlab_seed_timers:
		if timer is Timer:
			timer.stop()

func _on_player_health_updated(player, current_val: int, max_val: int) -> void :
	._on_player_health_updated(player, current_val, max_val)
	var lost_hp = RunData.get_player_effect(Utils.foxlab_lost_hp_hash, player.player_index)
	if lost_hp > 0:
		var life_label:Label = _players_ui[player.player_index].life_label
		if life_label.visible:
			life_label.text = str(-lost_hp) + " | " + life_label.text
