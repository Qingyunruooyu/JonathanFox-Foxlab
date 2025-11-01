extends "res://singletons/player_run_data.gd"

static func init_foxlab_stats() -> Dictionary:
	return {
			"stat_levels": 0,
			"fox_猫_duplicate_item": 0
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
			"fox_诗人_next_curse_chance": 0,
			"fox_排险者_crisis_num": 0,
			"fox_但丁_states": 0,
			"fox_购物狂_item_entries": 0,
			"fox_购物狂_item_entries_upgrade": 0,
			"fox_购物狂_vip_level": 0,
			"fox_修仙者_level": 0,
			"fox_修仙者_reset": 0,
			"fox_独狼_kills": 0,
			"gain_fox_独狼_kills": 0,
			"de_gain_fox_独狼_kills":0,
			"fox_独狼_total_kills": 0,
			"fox_独狼_total_kills_for_gain": 0,
			"fox_独狼_convert_temp": 0,
			"fox_独狼_number_of_enemies_1er": 0,
			"fox_独狼_stat_attack_speed_1er": 0,
			"fox_独狼_enemy_damage_1er": 0,
			"fox_独狼_enemy_health_1er": 0,
			"fox_无脸_wave_started": 0, # 防止面具变身的初始角色带有起始物品的时候，被重复添加
			"fox_无脸_prev_items":[],  # 所有面具效果的道具在获得的时候，都会清理已有的变身
			"fox_无脸_upgrade_on_transform":[],
			#ConvertStatEffect存在短路行为，如果两个角色都有这个效果，则不兼容，不允许同时变身
			"fox_无脸_convert_stat_characters":{},
			"fox_无脸_transform_stack":[0, false], #如果同时有多个面具，或者面具化身了无面，则挨个变身，避免嵌套变身
			"fox_convert_remainder_end_of_wave":[],
			"temp_stats_on_structure_crit": [], # 被删掉的原版词条
		}
		new_effects.merge(vanilla_effects)
		new_effects.merge(init_foxlab_stats())
		return new_effects;
	else:
		return {}
