extends "res://singletons/player_run_data.gd"

# 佛手相关
var foxlab_buddhas_hand_meta = []
# 面具相关
var foxlab_mask_meta = []

static func init_foxlab_stats() -> Dictionary:
	return {
			Keys.stat_levels_hash: 0,
			Utils.foxlab_extra_enemies_hash: 0,
			Utils.foxlab_extra_crash_zone_enemies_hash: 0,
			Utils.foxlab_extra_abyss_enemies_hash: 0,
			Utils.foxlab_extra_bosses_hash: 0,
			Utils.foxlab_extra_elites_hash: 0,
			Utils.foxlab_extra_unknown_elites_hash: 0,
			Utils.foxlab_extra_loot_aliens_hash: 0,
			Utils.foxlab_extra_evil_mobs_hash: 0,
			Utils.foxlab_cat_duplicate_item_hash: 0,
			Utils.item_foxlab_stargazer_hash: 0,
			Utils.item_foxlab_split_hash: 0,
			Utils.item_foxlab_eggs_hash: 0,
		}

# 这个函数是因为JSON文件不区分int 和float，而Effect序列化/反序列化中，只有value成员做了特殊处理，强制转成int，其他
# int成员反序列化回来时（如DoubleValueEffect、PercentDamageEffect等），会当做float类型，如果这些effect的apply又是直接
# append一个array，那么unapply的时候，尽管数值相等，但类型不相同，导致unapply实际上无事发生
func _foxlab_adjust_non_float_to_int(item_data):
	for item_effect in item_data.effects:
		var orig_effect = null
		if Utils.foxlab_effect_id_dict.has(item_effect.get_id()):
			orig_effect = Utils.foxlab_effect_id_dict[item_effect.get_id()]
		else:
			# 节约一点资源，StructureEffect和PetEffect是append(self)类型，实际上不会涉及
			if "is_pet" in item_effect or "is_structure" in item_effect:
				Utils.foxlab_effect_id_dict[item_effect.get_id()] = null
				continue
			var found = false
			for effect in ItemService.effects:
				if effect.get_id() == item_effect.get_id():
					orig_effect = effect
					Utils.foxlab_effect_id_dict[item_effect.get_id()] = orig_effect
					found = true
					break
			if not found:
				Utils.foxlab_effect_id_dict[item_effect.get_id()] = null

		if orig_effect == null:
			continue

		var need_adjust = false
		for prop in orig_effect.get_script_property_list():
			var name = prop["name"]
			var value = item_effect.get(name)
			if value is float and prop["type"] == TYPE_INT:
				print("item: %s, effect: %s, member: %s changed from float to int: %d" % [item_data.my_id, item_effect.get_id(), name, value])
				item_effect.set(name, int(value))
				need_adjust = true
		if not need_adjust:
			Utils.foxlab_effect_id_dict[item_effect.get_id()] = null

func _foxlab_deserialize_item(items: Array, item_dict:Dictionary):
	var item_data = ItemService.get_element_safe(items, item_dict.my_id)
	# 游戏刚启动ProgressData的_ready()如果在MOD加载好之前，拿MOD角色会返回null
	# 不影响，因为后面还会再反序列化
	if item_data != null:
		item_data = item_data.duplicate()
		item_data.deserialize_and_merge(item_dict)
		_foxlab_adjust_non_float_to_int(item_data)
		return item_data
	return null

##### 扩展 ######
func _init():
	foxlab_buddhas_hand_meta.push_back({
				"weapon_id": "",
				"weapon": null,
				"is_const_weapon": 0,
				"extra_item_id": "",
				"item": null, # for special item effect (duplicate_item, increase_tier_on_reroll, item_hourglass)
				})
	foxlab_buddhas_hand_meta.push_back(foxlab_buddhas_hand_meta[0].duplicate())

	foxlab_mask_meta.push_back({
				"chars": [],      #变换的角色（对象）
				"items": [],      #初始道具（对象）
				"weapons": [],    #初始武器（对象）
				"names": "",      #变换的角色的名字
				"prevs": [],      #前一次变身的角色/道具（[名字,诅咒系数]）和武器（对象），这次变身成功后需要移除
				})
	foxlab_mask_meta.push_back(foxlab_mask_meta[0].duplicate(true))

func duplicate():
	var copy = .duplicate()

	for i in range(foxlab_buddhas_hand_meta.size()):
		# duplicate the Dict
		copy.foxlab_buddhas_hand_meta[i] = foxlab_buddhas_hand_meta[i].duplicate()

	for i in range(foxlab_mask_meta.size()):
		var meta = foxlab_mask_meta[i]
		for key in meta.keys():
			if meta[key] is String:
				copy.foxlab_mask_meta[i][key] = meta[key]
			else: # duplicate the Array
				copy.foxlab_mask_meta[i][key] = meta[key].duplicate()
	return copy

func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.foxlab_buddhas_hand_meta = []
	for src_meta in foxlab_buddhas_hand_meta:
		serialized.foxlab_buddhas_hand_meta.push_back(src_meta.duplicate())
		var meta = serialized.foxlab_buddhas_hand_meta.back()
		for key in meta.keys():
			if meta[key] is Resource:
				meta[key] = meta[key].serialize()

	serialized.foxlab_mask_meta = []
	for src_meta in foxlab_mask_meta:
		serialized.foxlab_mask_meta.push_back({})
		var meta = serialized.foxlab_mask_meta.back()
		for key in src_meta.keys():
			var value = src_meta[key]
			if not value is Array:
				assert(value is String)
				meta[key] = value
			else:
				var data = []
				for res in value:
					assert(res is Resource or res is Array)
					if res is Resource:
						data.push_back(res.serialize())
					else:
						data.push_back(res.duplicate())
				meta[key] = data
	return serialized

func deserialize(data: Dictionary):
	if "foxlab_buddhas_hand_meta" in data:
		for i in range(data.foxlab_buddhas_hand_meta.size()):
			foxlab_buddhas_hand_meta[i] =  data.foxlab_buddhas_hand_meta[i].duplicate()
			var meta = foxlab_buddhas_hand_meta[i]
			if meta.item:
				meta.item = _foxlab_deserialize_item(ItemService.items, meta.item)
			if meta.weapon:
				meta.weapon = _foxlab_deserialize_item(ItemService.weapons, meta.weapon)

	if "foxlab_mask_meta" in data:
		for i in range(data.foxlab_mask_meta.size()):
			foxlab_mask_meta[i] = data.foxlab_mask_meta[i].duplicate()
			var meta = foxlab_mask_meta[i]
			if not meta.chars.empty():
				var chars = []
				for character in meta.chars:
					chars.push_back(_foxlab_deserialize_item(ItemService.characters, character))
				meta.chars = chars
			if not meta.items.empty():
				var items = []
				for item in meta.items:
					items.push_back(_foxlab_deserialize_item(ItemService.items, item))
				meta.items = items
			if not meta.weapons.empty():
				var weapons = []
				for weapon in meta.weapons:
					weapons.push_back(_foxlab_deserialize_item(ItemService.weapons, weapon))
				meta.weapons = weapons
			if not meta.prevs.empty():
				var prev_items = []
				for item in meta.prevs:
					if item is Dictionary:
						prev_items.push_back(_foxlab_deserialize_item(ItemService.weapons, item))
					else:
						assert (item is Array)
						prev_items.push_back(item.duplicate())
				meta.prevs = prev_items

	# 纯名字不需要被转换为哈希
	var memory = {}
	for key in Utils.foxlab_keys_raw_text:
		var key_str = str(key)
		if key_str in data.effects:
			memory[key] = data.effects[key_str].duplicate()

	.deserialize(data)

	appearances.clear()

	if not memory.empty():
		for key in memory.keys():
			effects[key] = memory[key]

	for item in items:
		_foxlab_adjust_non_float_to_int(item)
	for weapon in weapons:
		_foxlab_adjust_non_float_to_int(weapon)
	return self

# 切换面具角色需要移除的角色/道具，如果是对象类型（构筑物、爆炸、恶魔等），像武器一样能正确地回收
func _cache_effect_hashes(elements: Array, weapon_effect_hashes: Dictionary) -> void :
	var prev_items = []
	for meta in foxlab_mask_meta:
		for prev in meta.prevs:
			if prev is Array: # [id_hash, curse_factor]
				prev_items.append(prev)

	var cache_items = []
	for item_data in items:
		var is_prev = false
		for i in range(prev_items.size()):
			if prev_items[i][1] != item_data.curse_factor:
				continue
			var prev_item_hash = prev_items[i][0] as int
			if item_data.my_id_hash == prev_item_hash or (item_data.my_id_hash in Keys.item_builder_turret_n_hash and prev_item_hash in Keys.item_builder_turret_n_hash):
				cache_items.append(item_data)
				prev_items.remove(i)
				is_prev = true
				break
		if not is_prev and Utils.foxlab_item_has_object_effect(item_data):
			cache_items.push_back(item_data)

	if not cache_items.empty():
		elements = elements.duplicate()
		elements.append_array(cache_items)

	._cache_effect_hashes(elements, weapon_effect_hashes)

static func init_stats(all_null_values: bool = false)->Dictionary:
	if (not Utils == null) :
		var vanilla_stats = .init_stats(all_null_values)
		var foxlab_stats = init_foxlab_stats()
		foxlab_stats.merge(vanilla_stats)

		return foxlab_stats;
	else:
		return {}

static func init_effects()->Dictionary:
	if (not Utils == null) :
		var vanilla_effects = .init_effects()
		for gain_stat in Utils.foxlab_primary_stat_gain_map:
			if not gain_stat in vanilla_effects:
				vanilla_effects[gain_stat] = 0
		var new_effects: = {
			Utils.foxlab_gain_xp_gain_hash: 0,
			Utils.foxlab_gain_enemy_health_hash: 0,
			Utils.foxlab_gain_enemy_speed_hash: 0,
			Utils.foxlab_gain_enemy_damage_hash: 0,
			Utils.foxlab_gain_structure_percent_damage_hash:0,
			Utils.foxlab_item_steal_warmhole_spawn_hash:0,
			Utils.foxlab_poet_next_curse_chance_hash: 0,
			Utils.foxlab_tasks_hash: [],
			Utils.foxlab_troubleshooter_crisis_num_hash: 0,
			Utils.item_foxlab_trouble_mutation_hash: 0,
			Utils.foxlab_enemy_interact_hash: 0,
			Utils.foxlab_dante_states_hash: 0,
			Utils.foxlab_dante_penalty_hash: 0,
			Utils.foxlab_shop_point_hash: 0,
			Utils.foxlab_shop_vip_hash: 0,
			Utils.foxlab_cultivator_level_hash: 0,
			Utils.foxlab_wave_started_hash: 0, # 防止面具变身的初始角色带有起始物品的时候，被重复添加
			Utils.foxlab_faceless_enable_upgrade_on_transform_hash:0,
			Utils.foxlab_faceless_upgrade_on_transform_wave_hash:Utils.LARGE_NUMBER,
			#ConvertStatEffect存在短路行为，如果两个角色都有这个效果，则不兼容，不允许同时变身
			Utils.foxlab_faceless_convert_stat_characters_hash:{},
			Utils.foxlab_faceless_transform_stack_hash:[0, false], #如果同时有多个面具，或者面具化身了无面，则挨个变身，避免嵌套变身
			Utils.foxlab_mask_history_hash: [],
			Utils.foxlab_buddhas_hand_stack_hash:[0, false], #如果佛手给的武器有佛手效果，避免嵌套
			Utils.foxlab_convert_remainder_end_of_wave_hash:[],
			Utils.foxlab_temp_stats_on_structure_crit_hash: [], # 被删掉的原版词条
			Utils.foxlab_landmines_on_death_chance_hash: [],
			Utils.foxlab_effect_receive_item_at_wave_hash: [], # 改自brolab的两个特殊机制词条
			Utils.foxlab_stats_end_of_wave_after_wave_hash: [],
			Utils.foxlab_mutate_alive_enemy_hash: 0, #变异几率
			Utils.foxlab_gain_stat_on_mutate_hash:0, #变异后可获得属性,
			Utils.foxlab_no_trees_hash:0 ,#无法生成树木,
			Utils.foxlab_always_convert_stats_end_of_wave_hash: [], #不会被其他convert 短路
			Utils.foxlab_always_convert_stats_half_wave_hash: [],
			Utils.foxlab_multiply_stats_half_wave_hash:[],
			Utils.foxlab_multiply_stats_end_of_wave_hash:[],
			Utils.foxlab_gain_stat_every_killed_enemies_hash:[],
			Utils.foxlab_increase_tier_on_rerolls_hash:0,
			Utils.foxlab_force_remove_on_reroll_hash:[],
			Utils.foxlab_ball_lightning_hash:[],
			Utils.foxlab_assemble_tracker_on_hurt_hash:0,
			Utils.foxlab_heal_when_kill_nearby_hash:[],  #受益属性，受益倍率，受益概率
			Utils.foxlab_piercing_is_bounce_hash:0, #贯通视为反弹
			Utils.foxlab_bonus_reroll_weapon_tier_hash: Utils.LARGE_NUMBER, #每页购买一个X级或以上武器可以奖励一次刷新
			Utils.foxlab_level_up_bonus_crate_hash: 0, #升级时奖励宝箱数
			Utils.foxlab_keep_random_weapon_hash: 0,
			Utils.foxlab_shop_effects_checked_hash: 0, #base shop _ready()标记，避免重复操作，没有实际效果
			Utils.foxlab_projectile_on_hit_hash:[],
			Utils.foxlab_projectile_on_hit_num_hash: 0,
			Utils.foxlab_remember_shop_items_hash: 0,
			Utils.foxlab_previous_remembered_hash: [],
			Utils.foxlab_previous_remembered_names_hash: [], # 上面一条的物品的名字，由于有些MOD的物品名字不规范，所以独立存储
			Utils.foxlab_buy_item_increase_tier_hash: 0,
			Utils.foxlab_buy_item_increase_tier_current_hash: 0,
			Utils.foxlab_materials_on_scapegoat_hit_hash: 0,
			Utils.foxlab_scapegoat_no_heal_hash: 0,
			Utils.foxlab_stats_on_scapegoat_death_hash: [],
			Utils.foxlab_gain_scapegoat_no_hurt_hash: [],
			Utils.foxlab_stats_on_frozen_enemy_kill_hash: [],
			Utils.foxlab_item_upgrade_hash: 0,
			Utils.foxlab_instant_poisoned_attracting_hash: 0,
			Utils.foxlab_add_xp_on_getting_gold_hash: 0,
			Utils.foxlab_pending_xp_hash: 0,
			Utils.foxlab_lost_hp_on_losing_gold_hash: 0,
			Utils.foxlab_lost_hp_hash: 0,
			Utils.foxlab_charm_all_when_fully_heal_hash: [],
			Utils.foxlab_charm_all_items_hash: {},
			Utils.foxlab_extra_hit_hash: 0,
		}
		new_effects.merge(vanilla_effects)
		new_effects.merge(init_foxlab_stats())
		return new_effects;
	else:
		return {}
