extends "res://singletons/utils.gd"

const FOXLAB_BASE_NEARBY_KILL_DIST = 250

# Effects
var foxlab_cat_duplicate_item_hash = Keys.generate_hash("foxlab_cat_duplicate_item")
var foxlab_gain_xp_gain_hash: int = Keys.generate_hash("gain_xp_gain")
var foxlab_gain_enemy_health_hash: int = Keys.generate_hash("gain_enemy_health")
var foxlab_gain_enemy_speed_hash: int = Keys.generate_hash("gain_enemy_speed")
var foxlab_gain_enemy_damage_hash: int = Keys.generate_hash("gain_enemy_damage")
var foxlab_gain_structure_percent_damage_hash: int = Keys.generate_hash("gain_structure_percent_damage")
var fox_poet_next_curse_chance_hash: int = Keys.generate_hash("fox_poet_next_curse_chance")
var foxlab_troubleshooter_crisis_num_hash: int = Keys.generate_hash("foxlab_troubleshooter_crisis_num")
var foxlab_troubleshooter_temp_hash: int = Keys.generate_hash("foxlab_troubleshooter_temp")
var foxlab_dante_states_hash: int = Keys.generate_hash("foxlab_dante_states")
var foxlab_shop_point_hash: int = Keys.generate_hash("foxlab_shop_point")
var foxlab_shop_point_upgrade_hash: int = Keys.generate_hash("foxlab_shop_point_upgrade")
var foxlab_shop_vip_hash: int = Keys.generate_hash("foxlab_shop_vip")
var foxlab_cultivator_level_hash: int = Keys.generate_hash("foxlab_cultivator_level")
var foxlab_cultivator_reset_hash: int = Keys.generate_hash("foxlab_cultivator_reset")
var fox_wave_started_hash: int = Keys.generate_hash("fox_wave_started")
var fox_faceless_enable_upgrade_on_transform_hash: int = Keys.generate_hash("fox_faceless_enable_upgrade_on_transform")
var fox_faceless_upgrade_on_transform_wave_hash: int = Keys.generate_hash("fox_faceless_upgrade_on_transform_wave")
var fox_faceless_convert_stat_characters_hash: int = Keys.generate_hash("fox_faceless_convert_stat_characters")
var fox_faceless_transform_stack_hash: int = Keys.generate_hash("fox_faceless_transform_stack")
var foxlab_buddhas_hand_stack_hash: int = Keys.generate_hash("foxlab_buddhas_hand_stack")
var fox_convert_remainder_end_of_wave_hash: int = Keys.generate_hash("fox_convert_remainder_end_of_wave")
var foxlab_temp_stats_on_structure_crit_hash: int = Keys.generate_hash("foxlab_temp_stats_on_structure_crit")
var foxlab_landmines_on_death_chance_hash: int = Keys.generate_hash("foxlab_landmines_on_death_chance")
var foxlab_effect_receive_item_at_wave_hash: int = Keys.generate_hash("foxlab_effect_receive_item_at_wave")
var foxlab_stats_end_of_wave_after_wave_hash: int = Keys.generate_hash("foxlab_stats_end_of_wave_after_wave")
var foxlab_mutate_alive_enemy_hash: int = Keys.generate_hash("foxlab_mutate_alive_enemy")
var foxlab_gain_stat_on_mutate_hash: int = Keys.generate_hash("foxlab_gain_stat_on_mutate")
var foxlab_no_trees_hash: int = Keys.generate_hash("foxlab_no_trees")
var foxlab_always_convert_stats_end_of_wave_hash: int = Keys.generate_hash("foxlab_always_convert_stats_end_of_wave")
var foxlab_always_convert_stats_half_wave_hash: int = Keys.generate_hash("foxlab_always_convert_stats_half_wave")
var foxlab_multiply_stats_half_wave_hash: int = Keys.generate_hash("foxlab_multiply_stats_half_wave")
var foxlab_multiply_stats_end_of_wave_hash: int = Keys.generate_hash("foxlab_multiply_stats_end_of_wave")
var foxlab_gain_stat_every_killed_enemies_hash: int = Keys.generate_hash("foxlab_gain_stat_every_killed_enemies")
var foxlab_increase_tier_on_rerolls_hash: int = Keys.generate_hash("foxlab_increase_tier_on_rerolls")
var foxlab_force_remove_on_reroll_hash: int = Keys.generate_hash("foxlab_force_remove_on_reroll")
var foxlab_ball_lightning_hash: int = Keys.generate_hash("foxlab_ball_lightning")
var foxlab_assemble_tracker_on_hurt_hash: int = Keys.generate_hash("foxlab_assemble_tracker_on_hurt")
var foxlab_heal_when_kill_nearby_hash: int = Keys.generate_hash("foxlab_heal_when_kill_nearby")
var foxlab_piercing_is_bounce_hash: int = Keys.generate_hash("foxlab_piercing_is_bounce")
var item_foxlab_stargazer_hash: int = Keys.generate_hash("item_foxlab_stargazer")
var item_foxlab_split_hash: int = Keys.generate_hash("item_foxlab_split")
var item_foxlab_eggs_hash: int = Keys.generate_hash("item_foxlab_eggs")
var foxlab_bonus_reroll_weapon_tier_hash: int = Keys.generate_hash("foxlab_bonus_reroll_weapon_tier")
var foxlab_level_up_bonus_crate_hash: int = Keys.generate_hash("foxlab_level_up_bonus_crate")
var foxlab_keep_random_weapon_hash: int = Keys.generate_hash("foxlab_keep_random_weapon")
var foxlab_shop_effects_checked_hash: int = Keys.generate_hash("foxlab_shop_effects_checked")
var foxlab_projectile_on_hit_hash: int = Keys.generate_hash("foxlab_projectile_on_hit")
var foxlab_projectile_on_hit_num_hash: int = Keys.generate_hash("foxlab_projectile_on_hit_num")
var foxlab_remember_shop_items_hash: int = Keys.generate_hash("foxlab_remember_shop_items")
var foxlab_previous_remembered_hash: int = Keys.generate_hash("foxlab_previous_remembered")
var foxlab_previous_remembered_names_hash: int = Keys.generate_hash("foxlab_previous_remembered_names")
var foxlab_nullify_fatal_once_hash: int = Keys.generate_hash("foxlab_nullify_fatal_once")
var foxlab_nullify_fatal_resurrect_hash: int = Keys.generate_hash("foxlab_nullify_fatal_resurrect")
var foxlab_nullify_fatal_silence_hash: int = Keys.generate_hash("foxlab_nullify_fatal_silence")
var foxlab_nullify_fatal_revenge_hash: int = Keys.generate_hash("foxlab_nullify_fatal_revenge")
var foxlab_nullify_fatal_enemy_hash: int = Keys.generate_hash("foxlab_nullify_fatal_enemy")

# weapon extra effects that will be kept on weapon upgrade
var foxlab_const_effect_begin_hash: int = Keys.generate_hash("foxlab_const_effect_begin")
var foxlab_const_effect_end_hash: int = Keys.generate_hash("foxlab_const_effect_end")
# remembered weapon effects that will be forgotten at wave end
var foxlab_remembered_effect_begin_hash: int = Keys.generate_hash("foxlab_remembered_effect_begin")

# tracking items
var character_foxlab_bloody_wolf_hash: int = Keys.generate_hash("character_foxlab_bloody_wolf")
var character_foxlab_faceless_hash: int = Keys.generate_hash("character_foxlab_faceless")
var character_foxlab_ghost_envoy_hash: int = Keys.generate_hash("character_foxlab_ghost_envoy")
var character_foxlab_mnemosyne_hash: int = Keys.generate_hash("character_foxlab_mnemosyne")
var character_foxlab_mom_hash: int = Keys.generate_hash("character_foxlab_mom")
var character_foxlab_pufferfish_hash: int = Keys.generate_hash("character_foxlab_pufferfish")
var character_foxlab_refactor_hash: int = Keys.generate_hash("character_foxlab_refactor")
var character_foxlab_staff_officer_hash: int = Keys.generate_hash("character_foxlab_staff_officer")
var character_foxlab_toxic_healer_hash: int = Keys.generate_hash("character_foxlab_toxic_healer")
var character_foxlab_turtle_hash: int = Keys.generate_hash("character_foxlab_turtle")
var item_foxlab_angel_hash: int = Keys.generate_hash("item_foxlab_angel")
var item_foxlab_ball_lightning_0_hash: int = Keys.generate_hash("item_foxlab_ball_lightning_0")
var item_foxlab_ball_lightning_1_hash: int = Keys.generate_hash("item_foxlab_ball_lightning_1")
var item_foxlab_ball_lightning_2_hash: int = Keys.generate_hash("item_foxlab_ball_lightning_2")
var item_foxlab_ball_lightning_3_hash: int = Keys.generate_hash("item_foxlab_ball_lightning_3")
var item_foxlab_buddhas_hand_hash: int = Keys.generate_hash("item_foxlab_buddhas_hand")
var item_foxlab_demon_hash: int = Keys.generate_hash("item_foxlab_demon")
var item_foxlab_funnel_hash: int = Keys.generate_hash("item_foxlab_funnel")
var item_foxlab_inner_indomitable_hash: int = Keys.generate_hash("item_foxlab_inner_indomitable")
var item_foxlab_mask_hash: int = Keys.generate_hash("item_foxlab_mask")
var item_foxlab_reactor_hash: int = Keys.generate_hash("item_foxlab_reactor")
var item_foxlab_tracker_hash: int = Keys.generate_hash("item_foxlab_tracker")

# enemy names
var foxlab_evil_mob_hash: int = Keys.generate_hash("evil_mob")

# hash sets
var foxlab_ignored_floating_stat_hash = {
	Keys.no_heal_hash: 0,
	Keys.negative_knockback_hash: 0,
	Keys.enemy_damage_hash: 0,
	Keys.enemy_health_hash: 0,
	Keys.enemy_speed_hash: 0,
	Keys.stronger_elites_on_kill_hash: 0,
	foxlab_troubleshooter_crisis_num_hash: 0,
	foxlab_troubleshooter_temp_hash: 0,
	foxlab_dante_states_hash: 0,
	foxlab_shop_point_hash: 0,
	foxlab_shop_point_upgrade_hash: 0,
	foxlab_shop_vip_hash: 0,
	foxlab_cultivator_reset_hash: 0,
	foxlab_cultivator_level_hash: 0,
	}
var foxlab_primary_stat_gain_map = {}
var foxlab_structure_stats = {
		Keys.structure_range_hash: Keys.stat_structure_range_hash,
		Keys.structure_percent_damage_hash: Keys.stat_structure_percent_damage_hash
	}
var foxlab_enemy_stats = [Keys.enemy_damage_hash, Keys.enemy_health_hash, Keys.enemy_speed_hash]

var foxlab_multi_tracking_items = [item_foxlab_inner_indomitable_hash, character_foxlab_refactor_hash, item_foxlab_reactor_hash]

# 异形眼球，胡子婴儿等全部回收时，会有除以0的bug
var foxlab_least_one_items = {}

static func foxlab_get_tracking_text(item_id: int, tracking_text: String,  player_index: int) -> String:
	var text : String = ""
	if player_index != RunData.DUMMY_PLAYER_INDEX :
		for i in RunData.tracked_item_effects[player_index][item_id].size():
			var tracked_count = RunData.tracked_item_effects[player_index][item_id][i]

			var tracking_text_to_use = tracking_text

			if item_id == Utils.item_foxlab_inner_indomitable_hash and i == 1:
				tracking_text_to_use = "MATERIALS_GAINED"
			elif item_id == Utils.character_foxlab_refactor_hash and i == 1:
				tracking_text_to_use = "FOXLAB_MODIFICATION_GAINED"
			elif item_id == Utils.item_foxlab_reactor_hash:
				if i == 1:
					tracking_text_to_use = "FOXLAB_BOSSES_INVOKED"
				elif i == 2:
					tracking_text_to_use = "FOXLAB_BOSSES_RESURRECTED"

			text += "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text_to_use.to_upper(), [Text.get_formatted_number(tracked_count)]) + "[/color]"
	return text
	
func foxlab_get_least_one_items():
	for item in ItemService.items:
		if not item.can_be_looted:
			continue
		for effect in item.effects:
			if effect is ProjectileEffect:
				foxlab_least_one_items[item.my_id_hash] = item
				break

######## 扩展 ######
func _ready():
	for stat in _primary_stat_keys:
		var gain_stat = "gain_" + Keys.hash_to_string[stat]
		foxlab_primary_stat_gain_map[Keys.generate_hash(gain_stat)] = stat
	call_deferred("foxlab_get_least_one_items")

func average_all_player_stats(stat_hsh: int) -> float:
	var value = .average_all_player_stats(stat_hsh)
	# 负诅咒导致敌人生命值和伤害变成1
	return max(0, value) if stat_hsh == Keys.stat_curse_hash else value

func foxlab_multiply_stats(stats: Array, player_index: int, permanent: bool = true) -> void :
	if stats.empty():
		return
	for stat_to_mul in stats:
		var stat = stat_to_mul[0]
		var mul = stat_to_mul[1] as float
		if stat == Keys.materials_hash:
			var gold = RunData.get_player_gold(player_index)
			var gold_delta = gold * mul - gold
			RunData.add_gold(gold_delta, player_index)
			if not permanent:
				var actual_gain = gold * abs(mul) - gold
				RunData.add_tracked_value(player_index, character_foxlab_ghost_envoy_hash, actual_gain)
		else:
			var value = RunData.get_stat(stat, player_index)
			var value_delta = value * mul - value
			var stat_gain = RunData.get_stat_gain(stat, player_index)
			var actual_value_delta = value_delta
			if stat_gain > 0.0:
				actual_value_delta = round(value_delta / stat_gain) as int
			if actual_value_delta != 0:
				if permanent:
					RunData.add_stat(stat, actual_value_delta, player_index)
				else:
					TempStats.add_stat(stat, actual_value_delta, player_index)
					RunData.emit_signal("stat_added", stat, value_delta, 0.0, player_index)

func convert_stats(stats: Array, player_index: int, permanent: bool = true) -> void :
	# 敌袭结束时，在恶魔转换执行之前执行尾数转换
	if permanent: #敌袭结束
		foxlab_multiply_stats(RunData.get_player_effect(foxlab_multiply_stats_end_of_wave_hash, player_index), player_index, permanent)
		convert_remainder(RunData.get_player_effect(fox_convert_remainder_end_of_wave_hash, player_index), player_index)
		for effect in RunData.get_player_effect(foxlab_always_convert_stats_end_of_wave_hash, player_index):
			.convert_stats([effect], player_index, permanent)
	else: #敌袭中途
		foxlab_multiply_stats(RunData.get_player_effect(foxlab_multiply_stats_half_wave_hash, player_index), player_index, permanent)
		for effect in RunData.get_player_effect(foxlab_always_convert_stats_half_wave_hash, player_index):
			.convert_stats([effect], player_index, permanent)

	.convert_stats(stats, player_index, permanent)

func convert_remainder(stats: Array, player_index:int):
	if stats.empty():
		return
	for stat_to_convert in stats:
		var pct_converted:float = stat_to_convert[0]/100.0
		var stat_name :int= stat_to_convert[1]
		var stat_dividend :int= stat_to_convert[2]
		var remainder_offset:int = stat_to_convert[3]
		var keep_value = stat_to_convert[4]
		var to_stat:int = stat_to_convert[5]
		var to_stat_scaling:float= stat_to_convert[6]
		var storage_method = stat_to_convert[7]
		var is_negative_key:bool = stat_to_convert[8]

		var stat_value :int = 0
		if stat_name == Keys.materials_hash:
			stat_value = RunData.get_player_gold(player_index)
		elif stat_name == Keys.random_hash:
			stat_value = Utils.randi()
		else:
			stat_value = RunData.get_stat(stat_name, player_index) as int
		stat_value = (stat_value * pct_converted) as int
		if stat_value != 0 and stat_value < 0 != is_negative_key:
			continue
		var stat_remainder = stat_value if stat_dividend == 0 else stat_value % stat_dividend
		stat_remainder += remainder_offset
		var actual_stat_added = round(stat_remainder * to_stat_scaling) as int
		var stat_added_gain = RunData.get_stat_gain(to_stat, player_index)
		if stat_added_gain > 0.0:
			actual_stat_added = round(actual_stat_added / stat_added_gain) as int

		if storage_method == Effect.StorageMethod.REPLACE:
			if to_stat in [Keys.lock_current_weapons_hash, Keys.disable_item_locking_hash, Keys.item_steals_hash]:
				actual_stat_added = max(0, actual_stat_added)
			RunData.get_player_effects(player_index)[to_stat] = actual_stat_added
		else:
			RunData.get_player_effects(player_index)[to_stat] += actual_stat_added
		if actual_stat_added != 0:
			RunData.emit_signal("stat_added", to_stat, actual_stat_added, 0.0, player_index)

		#DebugService.log_data("remainder stat: %s, stat_value: %d, stat_dividend: %d, remainder: %d, actual_stat_added: %d, to_stat: %s" %
		#		[stat_name, stat_value, stat_dividend, stat_remainder, actual_stat_added, to_stat ])

		if keep_value == 1 or stat_name == Keys.random_hash:
			continue

		if keep_value == 0:
			RunData.get_player_effects(player_index)[stat_name] = 0
			continue

		var actual_stat_removed = stat_remainder
		var stat_removed_gain = RunData.get_stat_gain(stat_name, player_index)
		if stat_removed_gain > 0.0:
			actual_stat_removed = round(stat_remainder / stat_removed_gain) as int
		if stat_name == Keys.materials_hash:
			RunData.remove_gold(actual_stat_removed, player_index)
		else:
			RunData.remove_stat(stat_name, actual_stat_removed, player_index)

