extends "res://singletons/player_run_data.gd"

var foxlab_buddhas_hand_weapon = [null, null]
# for special item effect (duplicate_item, increase_tier_on_reroll, item_hourglass)
var foxlab_buddhas_hand_item = [null, null]
var foxlab_buddhas_hand_meta = []

static func init_foxlab_stats() -> Dictionary:
	return {
			Keys.stat_levels_hash: 0,
			Utils.foxlab_cat_duplicate_item_hash: 0,
			Utils.item_foxlab_stargazer_hash:0,
			Utils.item_foxlab_split_hash:0,
			Utils.item_foxlab_eggs_hash:0,
		}

##### 扩展 ######
func _init():
	foxlab_buddhas_hand_meta.push_back({"is_const_weapon": 0, "extra_item_id": "", "weapon_id": ""})
	foxlab_buddhas_hand_meta.push_back(foxlab_buddhas_hand_meta[0].duplicate())

func duplicate() -> PlayerRunData:
	var copy = .duplicate()
	copy.foxlab_buddhas_hand_weapon = foxlab_buddhas_hand_weapon.duplicate()
	copy.foxlab_buddhas_hand_item = foxlab_buddhas_hand_item.duplicate()
	copy.foxlab_buddhas_hand_meta = foxlab_buddhas_hand_meta.duplicate()
	return copy


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.foxlab_buddhas_hand_weapon = []
	for weapon in foxlab_buddhas_hand_weapon:
		serialized.foxlab_buddhas_hand_weapon.push_back(weapon.serialize() if weapon else null)

	serialized.foxlab_buddhas_hand_item = []
	for item in foxlab_buddhas_hand_item:
		serialized.foxlab_buddhas_hand_item.push_back(item.serialize() if item else null)

	serialized.foxlab_buddhas_hand_meta = foxlab_buddhas_hand_meta.duplicate()

	return serialized


func deserialize(data: Dictionary) -> PlayerRunData:
	.deserialize(data)

	if "foxlab_buddhas_hand_weapon" in data:
		foxlab_buddhas_hand_weapon = []
		for weapon in data.foxlab_buddhas_hand_weapon:
			if weapon:
				var weapon_data = ItemService.get_element_safe(ItemService.weapons, weapon.my_id)
				if weapon_data:
					weapon_data = weapon_data.duplicate()
					weapon_data.deserialize_and_merge(weapon)
					foxlab_buddhas_hand_weapon.push_back(weapon_data)
			else:
				foxlab_buddhas_hand_weapon.push_back(null)

	if "foxlab_buddhas_hand_item" in data:
		foxlab_buddhas_hand_item = []
		for item in data.foxlab_buddhas_hand_item:
			if item:
				var item_data = ItemService.get_element_safe(ItemService.items, item.my_id)
				if item_data != null:
					item_data = item_data.duplicate()
					item_data.deserialize_and_merge(item)
					foxlab_buddhas_hand_item.push_back(item_data)
			else:
				foxlab_buddhas_hand_item.push_back(null)

	if "foxlab_buddhas_hand_meta" in data:
		foxlab_buddhas_hand_meta = data.foxlab_buddhas_hand_meta.duplicate()

	return self


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
		var new_effects: = {
			Utils.foxlab_gain_xp_gain_hash: 0,
			Utils.foxlab_gain_enemy_health_hash: 0,
			Utils.foxlab_gain_enemy_speed_hash: 0,
			Utils.foxlab_gain_enemy_damage_hash: 0,
			Utils.foxlab_gain_structure_percent_damage_hash:0,
			Utils.fox_poet_next_curse_chance_hash: 0,
			Utils.foxlab_troubleshooter_crisis_num_hash: 0,
			Utils.foxlab_troubleshooter_temp_hash:0,
			Utils.foxlab_dante_states_hash: 0,
			Utils.foxlab_shop_point_hash: 0,
			Utils.foxlab_shop_point_upgrade_hash: 0,
			Utils.foxlab_shop_vip_hash: 0,
			Utils.foxlab_cultivator_level_hash: 0,
			Utils.foxlab_cultivator_reset_hash: 0,
			Utils.fox_wave_started_hash: 0, # 防止面具变身的初始角色带有起始物品的时候，被重复添加
			Utils.foxlab_mask_first_generate_hash: 1, # 如果是第一次生成，则清除前一次运行的数据
			Utils.fox_faceless_prev_items_hash:[],  # 所有面具效果的道具在获得的时候，都会清理已有的变身
			Utils.fox_faceless_enable_upgrade_on_transform_hash:0,
			Utils.fox_faceless_upgrade_on_transform_wave_hash:Utils.LARGE_NUMBER,
			#ConvertStatEffect存在短路行为，如果两个角色都有这个效果，则不兼容，不允许同时变身
			Utils.fox_faceless_convert_stat_characters_hash:{},
			Utils.fox_faceless_transform_stack_hash:[0, false], #如果同时有多个面具，或者面具化身了无面，则挨个变身，避免嵌套变身
			Utils.foxlab_buddhas_hand_stack_hash:[0, false], #如果佛手给的武器有佛手效果，避免嵌套
			Utils.fox_convert_remainder_end_of_wave_hash:[],
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
			Utils.foxlab_nullify_fatal_once_hash: 0, # 拿到道具后，一局限一次，免疫致命伤害
			Utils.foxlab_nullify_fatal_resurrect_hash: 0, # 每波限一次，免疫致命伤害并失去随机道具
			Utils.foxlab_nullify_fatal_silence_hash: 0, # 免疫致命伤害后，如果是敌人的伤害，本局不再承受其伤害
			Utils.foxlab_nullify_fatal_revenge_hash: 0, # 免疫致命伤害后，如果是敌人的伤害，未来秒杀这种敌人
			Utils.foxlab_nullify_fatal_enemy_hash: "", # 免疫致命伤害的敌人
		}
		new_effects.merge(vanilla_effects)
		new_effects.merge(init_foxlab_stats())
		return new_effects;
	else:
		return {}
