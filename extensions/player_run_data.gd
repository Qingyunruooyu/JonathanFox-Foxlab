extends "res://singletons/player_run_data.gd"

static func init_foxlab_stats() -> Dictionary:
	return {
			"stat_levels": 0,
			"foxlab_cat_duplicate_item": 0
		}

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
			"gain_xp_gain": 0,
			"gain_enemy_health": 0,
			"gain_enemy_speed": 0,
			"gain_enemy_damage": 0,
			"gain_structure_percent_damage":0,
			"fox_poet_next_curse_chance": 0,
			"foxlab_troubleshooter_crisis_num": 0,
			"foxlab_troubleshooter_temp":0,
			"foxlab_dante_states": 0,
			"foxlab_shop_point": 0,
			"foxlab_shop_point_upgrade": 0,
			"foxlab_shop_vip": 0,
			"foxlab_cultivator_level": 0,
			"foxlab_cultivator_reset": 0,
			"fox_wave_started": 0, # 防止面具变身的初始角色带有起始物品的时候，被重复添加
			"foxlab_mask_first_generate": 1, # 如果是第一次生成，则清除前一次运行的数据
			"foxlab_buddhas_hand_first_generate": 1,
			"fox_faceless_prev_items":[],  # 所有面具效果的道具在获得的时候，都会清理已有的变身
			"fox_faceless_enable_upgrade_on_transform":0,
			"fox_faceless_upgrade_on_transform_wave":Utils.LARGE_NUMBER,
			#ConvertStatEffect存在短路行为，如果两个角色都有这个效果，则不兼容，不允许同时变身
			"fox_faceless_convert_stat_characters":{},
			"fox_faceless_transform_stack":[0, false], #如果同时有多个面具，或者面具化身了无面，则挨个变身，避免嵌套变身
			"fox_convert_remainder_end_of_wave":[],
			"temp_stats_on_structure_crit": [], # 被删掉的原版词条
			"foxlab_effect_receive_item_at_wave": [], # 改自brolab的两个特殊机制词条
			"foxlab_stats_end_of_wave_after_wave": [],
			"foxlab_mutate_alive_enemy": 0, #变异几率
			"foxlab_gain_stat_on_mutate":0, #变异后可获得属性,
			"foxlab_no_trees":0 ,#无法生成树木,
			"foxlab_always_convert_stats_end_of_wave": [], #不会被其他convert 短路
			"foxlab_always_convert_stats_half_wave": [],
			"foxlab_multiply_stats_half_wave":[],
			"foxlab_multiply_stats_end_of_wave":[],
			"foxlab_gain_stat_every_killed_enemies":[],
			"foxlab_increase_tier_on_rerolls":0,
			"foxlab_force_remove_on_reroll":[],
			"foxlab_ball_lightning":[],
			"foxlab_assemble_tracker_on_hurt":0,
			"foxlab_heal_when_kill_nearby":[],  #受益属性，受益倍率，受益概率
			"foxlab_piercing_is_bounce":0, #贯通视为反弹
			"item_foxlab_stargazer":0,
			"item_foxlab_split":0,
			"item_foxlab_eggs":0,
			"foxlab_bonus_reroll_weapon_tier": Utils.LARGE_NUMBER, #每页购买一个X级或以上武器可以奖励一次刷新
			"foxlab_level_up_bonus_crate": 0, #升级时奖励宝箱数
		}
		new_effects.merge(vanilla_effects)
		new_effects.merge(init_foxlab_stats())
		return new_effects;
	else:
		return {}
