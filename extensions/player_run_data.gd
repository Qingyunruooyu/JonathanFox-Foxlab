extends "res://singletons/player_run_data.gd"

static func init_stats(all_null_values: bool = false)->Dictionary:
	if (not Utils == null) :
		var vanilla_stats = .init_stats(all_null_values)
		var new_stats: = {
			"stat_levels": 0,
			"fox_猫_duplicate_item": 0
		}

		new_stats.merge(vanilla_stats)

		return new_stats;
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
			"fox_程序员_exp": 0,
			"fox_魔术师_material_add": 0,
			"fox_魔术师_material_sub": 0,
			"fox_魔术师_material_cache": 0,
			"fox_二极管_material_backup": 0,
			"fox_二极管_crit_chance_raw": 0,
			"fox_二极管_crit_chance_fill": 0,
			"fox_诗人_next_curse_chance": 0,
			"fox_排险者_crisis_num": 0,
			"fox_股民_material_backup": 0,
			"fox_股民_material_fill": 0,
			"fox_股民_gain_max_hp_offset": 0,
			"fox_但丁_states": 0,
			"fox_购物狂_item_entries": 0,
			"fox_购物狂_item_entries_upgrade": 0,
			"fox_购物狂_vip_level": 0,
			"fox_修仙者_level": 0,
			"fox_修仙者_reset": 0,
			"fox_猫_steps": 0,
			"fox_猫_steps_nolock": 0,
			"fox_猫_steps_lock_weapon": 0,
			"fox_猫_steps_lcm": 0,
			"fox_猫_steal_base": 0,
			"fox_猫_nolock_base": 0,
			"fox_猫_lock_weapon_base": 0,
			"fox_猫_steal_1er": 0,
			"fox_猫_nolock_1er": 0,
			"fox_猫_lock_weapon_1er": 0,
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
			"fox_衔尾蛇_cache": 0, # 1.1.12.0之后，蝾螈生效后已经会reset_stat_cache了，兼容旧版
			"fox_无脸_wave_started": 0, # 防止面具变身的初始角色带有起始物品的时候，被重复添加
			"fox_无脸_prev_items":[],  # 所有面具效果的道具在获得的时候，都会清理已有的变身
			"fox_无脸_upgrade_on_transform":[],
			"temp_stats_on_structure_crit": [], # 被删掉的原版词条
		}
		new_effects.merge(vanilla_effects)
		return new_effects;
	else:
		return {}
