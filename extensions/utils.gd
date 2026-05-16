extends "res://singletons/utils.gd"

const FOXLAB_BASE_NEARBY_KILL_DIST = 250
const FOXLAB_FROZEN_SPEED = 40
const FOXLAB_BOSS_SPAWN_CHANCE = 25
const FOXLAB_BOSS_SPAWN_NUM = 4
const FOXLAB_BOSS_INTERVAL = 30
const FOXLAB_SEED_DURATION = 5
const FOXLAB_LIVING_ENEMY_DURATION_BOOST = 15
const FOXLAB_SEED_PER_SECOND = 4

# Effects
var foxlab_cat_duplicate_item_hash = Keys.generate_hash("foxlab_cat_duplicate_item")
var foxlab_gain_xp_gain_hash: int = Keys.generate_hash("gain_xp_gain")
var foxlab_gain_enemy_health_hash: int = Keys.generate_hash("gain_enemy_health")
var foxlab_gain_enemy_speed_hash: int = Keys.generate_hash("gain_enemy_speed")
var foxlab_gain_enemy_damage_hash: int = Keys.generate_hash("gain_enemy_damage")
var foxlab_gain_structure_percent_damage_hash: int = Keys.generate_hash("gain_structure_percent_damage")
var foxlab_item_steal_warmhole_spawn_hash: int = Keys.generate_hash("foxlab_item_steal_warmhole_spawn")
var foxlab_extra_enemies_hash: int = Keys.generate_hash("foxlab_extra_enemies")
var foxlab_extra_crash_zone_enemies_hash: int = Keys.generate_hash("foxlab_extra_crash_zone_enemies")
var foxlab_extra_abyss_enemies_hash: int = Keys.generate_hash("foxlab_extra_abyss_enemies")
var foxlab_extra_loot_aliens_hash: int = Keys.generate_hash("foxlab_extra_loot_aliens")
var foxlab_extra_evil_mobs_hash: int = Keys.generate_hash("foxlab_extra_evil_mobs")
var foxlab_poet_next_curse_chance_hash: int = Keys.generate_hash("foxlab_poet_next_curse_chance")
var foxlab_tasks_hash: int = Keys.generate_hash("foxlab_tasks")
var foxlab_troubleshooter_crisis_num_hash: int = Keys.generate_hash("foxlab_troubleshooter_crisis_num")
var item_foxlab_trouble_mutation_hash: int = Keys.generate_hash("item_foxlab_trouble_mutation")
var foxlab_enemy_interact_hash: int = Keys.generate_hash("foxlab_enemy_interact")
var foxlab_dante_states_hash: int = Keys.generate_hash("foxlab_dante_states")
var foxlab_dante_penalty_hash: int = Keys.generate_hash("foxlab_dante_penalty")
var foxlab_shop_point_hash: int = Keys.generate_hash("foxlab_shop_point")
var foxlab_shop_vip_hash: int = Keys.generate_hash("foxlab_shop_vip")
var foxlab_cultivator_level_hash: int = Keys.generate_hash("foxlab_cultivator_level")
var foxlab_extra_bosses_hash: int = Keys.generate_hash("foxlab_extra_bosses")
var foxlab_extra_elites_hash: int = Keys.generate_hash("foxlab_extra_elites")
var foxlab_extra_unknown_elites_hash: int = Keys.generate_hash("foxlab_extra_unknown_elites")
var foxlab_wave_started_hash: int = Keys.generate_hash("foxlab_wave_started")
var foxlab_faceless_enable_upgrade_on_transform_hash: int = Keys.generate_hash("foxlab_faceless_enable_upgrade_on_transform")
var foxlab_faceless_upgrade_on_transform_wave_hash: int = Keys.generate_hash("foxlab_faceless_upgrade_on_transform_wave")
var foxlab_faceless_convert_stat_characters_hash: int = Keys.generate_hash("foxlab_faceless_convert_stat_characters")
var foxlab_faceless_transform_stack_hash: int = Keys.generate_hash("foxlab_faceless_transform_stack")
var foxlab_mask_history_hash: int=Keys.generate_hash("foxlab_mask_history")
var foxlab_buddhas_hand_stack_hash: int = Keys.generate_hash("foxlab_buddhas_hand_stack")
var foxlab_convert_remainder_end_of_wave_hash: int = Keys.generate_hash("foxlab_convert_remainder_end_of_wave")
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
var foxlab_buy_item_increase_tier_hash: int = Keys.generate_hash("foxlab_buy_item_increase_tier")
var foxlab_buy_item_increase_tier_current_hash: int = Keys.generate_hash("foxlab_buy_item_increase_tier_current")
var foxlab_materials_on_scapegoat_hit_hash: int = Keys.generate_hash("foxlab_materials_on_scapegoat_hit")
var foxlab_scapegoat_no_heal_hash: int = Keys.generate_hash("foxlab_scapegoat_no_heal")
var foxlab_stats_on_scapegoat_death_hash: int = Keys.generate_hash("foxlab_stats_on_scapegoat_death")
var foxlab_gain_scapegoat_no_hurt_hash: int = Keys.generate_hash("foxlab_gain_scapegoat_no_hurt")
var foxlab_stats_on_frozen_enemy_kill_hash: int = Keys.generate_hash("foxlab_stats_on_frozen_enemy_kill")
var foxlab_item_upgrade_hash: int = Keys.generate_hash("foxlab_item_upgrade")
var foxlab_instant_poisoned_attracting_hash: int = Keys.generate_hash("foxlab_instant_poisoned_attracting")
var foxlab_add_xp_on_getting_gold_hash: int = Keys.generate_hash("foxlab_add_xp_on_getting_gold")
var foxlab_pending_xp_hash: int = Keys.generate_hash("foxlab_pending_xp")
var foxlab_lost_hp_on_losing_gold_hash: int = Keys.generate_hash("foxlab_lost_hp_on_losing_gold")
var foxlab_lost_hp_hash: int = Keys.generate_hash("foxlab_lost_hp")
var foxlab_charm_all_when_fully_heal_hash: int = Keys.generate_hash("foxlab_charm_all_when_fully_heal")
var foxlab_charm_all_items_hash: int = Keys.generate_hash("foxlab_charm_all_items")

# weapon extra effects that will be kept on weapon upgrade
var foxlab_const_effect_begin_hash: int = Keys.generate_hash("foxlab_const_effect_begin")
var foxlab_const_effect_end_hash: int = Keys.generate_hash("foxlab_const_effect_end")
# remembered weapon effects that will be forgotten at wave end
var foxlab_remembered_effect_begin_hash: int = Keys.generate_hash("foxlab_remembered_effect_begin")

# items
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
var character_foxlab_goat_keeper_hash: int = Keys.generate_hash("character_foxlab_goat_keeper")
var character_foxlab_stargazer_hash: int = Keys.generate_hash("character_foxlab_stargazer")
var character_foxlab_bounty_hunter_hash: int = Keys.generate_hash("character_foxlab_bounty_hunter")
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
var item_foxlab_faceless_guide_hash: int = Keys.generate_hash("item_foxlab_faceless_guide")
var item_foxlab_enchanted_eyes_hash: int = Keys.generate_hash("item_foxlab_enchanted_eyes")
var item_foxlab_wanted_hash: int = Keys.generate_hash("item_foxlab_wanted")
var item_foxlab_wanted_unknown_hash: int = Keys.generate_hash("item_foxlab_wanted_unknown")
var item_foxlab_salvation_hash: int = Keys.generate_hash("item_foxlab_salvation")
var consumable_foxlab_seed_hash: int = Keys.generate_hash("consumable_foxlab_seed")

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
	Keys.next_level_xp_needed_hash: 0,
	Keys.items_price_hash: 0,
	Keys.reroll_price_hash: 0,
	}
# primary stat gain -> primary stat
var foxlab_primary_stat_gain_map = {}
# stats in order of stat panel
var foxlab_stats_in_container = []
# 0: tier COMMON level up value of primary (defaults to 1)
# 1: basic upgrade id
var foxlab_primary_stat_level_up_map = []
var foxlab_structure_stats = {
		Keys.structure_range_hash: Keys.stat_structure_range_hash,
		Keys.structure_percent_damage_hash: Keys.stat_structure_percent_damage_hash
	}
var foxlab_enemy_stats = [Keys.enemy_damage_hash, Keys.enemy_health_hash, Keys.enemy_speed_hash]

var foxlab_keys_raw_text = [foxlab_mask_history_hash, foxlab_previous_remembered_names_hash]

var foxlab_item_wanted = []
var foxlab_item_wanted_hash = {}
var foxlab_unknown_elites = []

var foxlab_gaster_group = null

var foxlab_evil_mob_units = []

var foxlab_enemy_id_scene_map = {}

var foxlab_object_effect_item = {}

#反序列化之后，物品回收相关，快速查找effect id对应的effect对象
var foxlab_effect_id_dict = {}

var foxlab_item_with_descrip = {item_foxlab_buddhas_hand_hash: 0, item_foxlab_mask_hash: 0, item_foxlab_salvation_hash: 0}

static func foxlab_get_tracking_text(item_id: int, tracking_text: String,  player_index: int) -> String:
	var text : String = ""
	if player_index != RunData.DUMMY_PLAYER_INDEX :
		for i in RunData.tracked_item_effects[player_index][item_id].size():
			var tracked_count = RunData.tracked_item_effects[player_index][item_id][i]

			var tracking_text_to_use
			match [item_id, i]:
				[Utils.item_foxlab_inner_indomitable_hash, 1]:
					tracking_text_to_use = "MATERIALS_GAINED"
				[Utils.character_foxlab_refactor_hash, 1]:
					tracking_text_to_use = "FOXLAB_MODIFICATION_GAINED"
				[Utils.item_foxlab_reactor_hash, 1]:
					tracking_text_to_use = "FOXLAB_BOSSES_INVOKED"
				[Utils.item_foxlab_reactor_hash, 2]:
					tracking_text_to_use = "FOXLAB_BOSSES_RESURRECTED"
				[Utils.character_foxlab_goat_keeper_hash, 1]:
					tracking_text_to_use = "FOXLAB_CRATES_DROPPED"
				[Utils.item_foxlab_salvation_hash, 1]:
					tracking_text_to_use = "FOXLAB_SEEDS_DROPPED"
				[Utils.item_foxlab_salvation_hash, 2]:
					tracking_text_to_use = "FOXLAB_SEEDS_ACTIVATED"
				_:
					tracking_text_to_use = tracking_text

			text += "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text_to_use.to_upper(), [Text.get_formatted_number(tracked_count)]) + "[/color]"
	return text

func _foxlab_init_primary_stat_gain_map():
	for stat in _primary_stat_keys:
		var gain_stat = "gain_" + Keys.hash_to_string[stat]
		foxlab_primary_stat_gain_map[Keys.generate_hash(gain_stat)] = stat

####### 生成敌人相关 ##########
const FOXLAB_DRAGON_FISH_PATH = "res://dlcs/dlc_1/zones/common/gangster/gangster_group.tres"
func foxlab_pickup_random_group_data(zone_id: String = "") -> Array:
	var ret_groups = []
	var extra_group_chance = 0.01
	var zone_data = null
	if zone_id != "":
		for zone in ZoneService.zones:
			if zone.name == zone_id:
				zone_data = zone
				break;
	if zone_data == null:
		zone_data = get_rand_element(ZoneService.zones)
	for groups in [zone_data.groups_data_in_all_waves, zone_data.horde_groups]:
		if get_chance_success(extra_group_chance):
			ret_groups.append(get_rand_element(groups))
	if ResourceLoader.exists(FOXLAB_DRAGON_FISH_PATH):
		if get_chance_success(extra_group_chance / 2.0):
			if foxlab_gaster_group == null:
				# preload会提前加载enemy.gd，导致兼容性问题
				foxlab_gaster_group = load(FOXLAB_DRAGON_FISH_PATH)
			ret_groups.append(foxlab_gaster_group)
			ret_groups.append(foxlab_gaster_group)
	# var min_wave = min(9, RunData.current_wave) as int
	# var max_wave = clamp(RunData.current_wave*2.5, 1, zone_data.waves_data.size()) as int
	var min_wave = 11
	var max_wave = zone_data.waves_data.size()
	var wave = min_wave + randi()%(max_wave - min_wave + 1) - 1
	assert (wave < zone_data.waves_data.size())
	var wave_data = zone_data.waves_data[wave].groups_data.duplicate()
	wave_data.shuffle()
	for data in wave_data:
		if not data.is_boss and data.min_difficulty <= RunData.current_difficulty and RunData.current_difficulty <= data.max_difficulty:
			ret_groups.append(data)
			break;
	return ret_groups

const FOXLAB_EXTRA_BOSS_PATH = "res://mods-unpacked/Alexandre-BeyondDanger/content/enemies/boss/architect/architect.tscn"
func foxlab_pickup_random_bosses() -> Array:
	var bosses = ItemService.bosses.duplicate()
	var extra_boss = null
	if ResourceLoader.exists(FOXLAB_EXTRA_BOSS_PATH):
		extra_boss = load(FOXLAB_EXTRA_BOSS_PATH)
		bosses.append({"scene": extra_boss})

	if bosses.size() != FOXLAB_BOSS_SPAWN_NUM:
		if bosses.size() > FOXLAB_BOSS_SPAWN_NUM:
			bosses.shuffle()
			bosses = bosses.slice(0, FOXLAB_BOSS_SPAWN_NUM - 1)
		else:
			while bosses.size() < FOXLAB_BOSS_SPAWN_NUM:
				bosses.append(Utils.get_rand_element(ItemService.bosses))

	assert(bosses.size() == FOXLAB_BOSS_SPAWN_NUM)
	var group = preload("res://zones/common/elite/group_elite.tres").duplicate()
	group.repeating_interval = FOXLAB_BOSS_INTERVAL
	group.repeating = 999
	var units = []
	for boss in bosses:
		var wave_unit_data = WaveUnitData.new()
		wave_unit_data.type = EntityType.BOSS
		wave_unit_data.spawn_chance = FOXLAB_BOSS_SPAWN_CHANCE / 100.0
		wave_unit_data.unit_scene = boss.scene
		units.append(wave_unit_data)
	group.wave_units_data = units
	return [group]

func foxlab_pickup_random_elites(is_unknown: bool) -> Array:
	var group = preload("res://zones/common/elite/group_elite.tres").duplicate()
	var wave_unit_data = WaveUnitData.new()
	wave_unit_data.type = EntityType.BOSS
	if is_unknown:
		if foxlab_item_wanted.empty():
			foxlab_collect_item_foxlab_wanted()
		if not foxlab_unknown_elites.empty():
			wave_unit_data.unit_scene = foxlab_unknown_elites.pick_random()
	if wave_unit_data.unit_scene == null:
		wave_unit_data.unit_scene = ItemService.elites.pick_random().scene
	group.wave_units_data = [wave_unit_data]
	return [group]

func foxlab_generate_loot_alien_group_data(num: int, wave_timer)->Array:
	var ret_groups = []
	for i in num:
		var zone_data = get_rand_element(ZoneService.zones)
		for group in zone_data.loot_alien_groups:
			var new_group = group.duplicate()
			new_group.spawn_timing = rand_range(5, wave_timer.time_left - 10)
			ret_groups.push_back(new_group)
	return ret_groups

func foxlab_generate_evil_mob_group_data(num: int)->Array:
	if foxlab_evil_mob_units.empty():
		for zone_data in ZoneService.zones:
			for group in zone_data.groups_data_in_all_waves:
				for unit in group.wave_units_data:
					if "evil_mob" in unit.unit_scene_name:
						var my_unit = unit.duplicate()
						my_unit.spawn_chance = 1.0
						foxlab_evil_mob_units.append(my_unit)
	var group = preload("res://mods-unpacked/JonathanFox-FoxLab/contents/zones/inplace_operation/group_evil_mob.tres").duplicate()
	for i in num:
		group.wave_units_data.append(foxlab_evil_mob_units.pick_random())
	return [group]

func foxlab_collect_item_foxlab_wanted():
	var unknown_wanted_item = null
	var elite_ids = {}
	for item in ItemService.items:
		if item.name == "ITEM_FOXLAB_WANTED":
			if item.my_id_hash == item_foxlab_wanted_unknown_hash:
				unknown_wanted_item = item
				continue
			foxlab_item_wanted.append(item)
			foxlab_item_wanted_hash[item.my_id_hash] = 1
			for effect in item.effects:
				if effect.custom_key_hash == Keys.extra_enemies_next_wave_hash:
					elite_ids[effect.key2_hash] = 1
	if unknown_wanted_item and foxlab_item_wanted.size() < ItemService.elites.size():
		for elite in ItemService.elites:
			if not elite.my_id_hash in elite_ids:
				foxlab_unknown_elites.append(elite.scene)
		if not foxlab_unknown_elites.empty():
			foxlab_item_wanted.append(unknown_wanted_item)
			foxlab_item_wanted_hash[unknown_wanted_item.my_id_hash] = 1

func foxlab_get_random_item_foxlab_wanted(player_index: int):
	if foxlab_item_wanted.empty():
		foxlab_collect_item_foxlab_wanted()
	if RunData.get_nb_item(item_foxlab_enchanted_eyes_hash, player_index) > 0:
		RunData.add_tracked_value(player_index, item_foxlab_enchanted_eyes_hash, 1)
	if RunData.get_nb_item(character_foxlab_bounty_hunter_hash, player_index) > 0:
		RunData.add_tracked_value(player_index, character_foxlab_bounty_hunter_hash, 1)
	return foxlab_item_wanted.pick_random()

# 不直接销毁武器， 因为武器可能还有投射物、爆炸在外面，防止他们引用野地址
func foxlab_queue_free_weapon(weapon: Node2D):
	weapon._current_cooldown = 99999999.9
	weapon.disable_hitbox()
	weapon.disable_target_tracking()
	weapon.visible = false
	disable_node(weapon)
	#print("disable weapon ", weapon)

func foxlab_get_primary_stat_level_up_map():
	if foxlab_primary_stat_level_up_map.empty():
		foxlab_primary_stat_level_up_map = [{}, {}]
		var level_up_value_map = foxlab_primary_stat_level_up_map[0]
		var level_up_id_map = foxlab_primary_stat_level_up_map[1]
		var primary_stats = Utils.foxlab_get_stats_in_container()[0]
		for upgrade in ItemService.get_pool(0, ItemService.TierData.UPGRADES):
			if upgrade.effects.size() == 1:
				var effect = upgrade.effects[0]
				if effect.custom_key_hash == Keys.empty_hash and effect.key_hash in primary_stats and effect.get_id() == Effect.get_id():
					if not effect.key_hash in level_up_value_map:
						level_up_value_map[effect.key_hash] = effect.value
						level_up_id_map[upgrade.upgrade_id_hash] = 1
						# print(tr(upgrade.get_name_text()))
		for stat in primary_stats:
			if not stat in level_up_value_map:
				level_up_value_map[stat] = 1
				# print(tr(Keys.hash_to_string[stat].to_upper()))
	return foxlab_primary_stat_level_up_map

func foxlab_get_stats_in_container():
	if foxlab_stats_in_container.empty():
		var stats_container = load("res://ui/menus/shop/stats_container.tscn").instance()
		get_tree().root.add_child(stats_container)
		stats_container.visible = false
		if stats_container._primary_stats != null and stats_container._secondary_stats != null:
			for container in [stats_container._primary_stats, stats_container._secondary_stats]:
				foxlab_stats_in_container.append([])
				var stats = foxlab_stats_in_container.back()
				for stat in container.get_children():
					if stat.visible:
						stats.append(stat.key_hash)
		stats_container.queue_free()
	return foxlab_stats_in_container

func foxlab_try_complete_tasks(player_index: int):
	var effects = RunData.get_player_effects(player_index)
	if effects[Utils.foxlab_tasks_hash].empty():
		return
	for task in effects[Utils.foxlab_tasks_hash]:
		if (task.max_execs < 0 or effects[task.custom_key_hash] < task.max_execs):
			var stat_value = RunData.get_stat(task.key_hash, player_index)
			if (task.comparison >= 0 and stat_value >= task.value) or\
				(task.comparison < 0 and stat_value < task.value):
				RunData.add_stat(task.custom_key_hash, 1, player_index)
				for effect in task.sub_effects:
					effect.apply(player_index)

func foxlab_item_has_object_effect(item_data) -> bool:
	if item_data.my_id_hash in foxlab_object_effect_item:
		return foxlab_object_effect_item[item_data.my_id_hash]
	if item_data.is_structure_item() or item_data.is_pet_item():
		foxlab_object_effect_item[item_data.my_id_hash] = true
	else:
		foxlab_object_effect_item[item_data.my_id_hash] = false
		for effect in item_data.effects:
			var checking_key_hash = (effect.key_hash if effect.custom_key_hash == Keys.empty_hash else effect.custom_key_hash)
			if checking_key_hash != Keys.empty_hash and checking_key_hash in RunData.effect_keys_full_serialization:
					foxlab_object_effect_item[item_data.my_id_hash] = true
					break
	return foxlab_object_effect_item[item_data.my_id_hash]

######## 扩展 ######
func reset_stat_keys() -> void :
	.reset_stat_keys()
	foxlab_item_wanted.clear()
	foxlab_item_wanted_hash.clear()
	foxlab_unknown_elites.clear()
	foxlab_evil_mob_units.clear()
	foxlab_stats_in_container.clear()
	foxlab_primary_stat_level_up_map.clear()
	foxlab_primary_stat_gain_map.clear()
	_foxlab_init_primary_stat_gain_map()

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
				if RunData.get_player_gold(player_index) < 0:
					RunData.foxlab_is_midnight[player_index] = true
				RunData.emit_signal("stat_added", Keys.stat_materials_hash, actual_gain, 0.0, player_index)
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
		convert_remainder(RunData.get_player_effect(foxlab_convert_remainder_end_of_wave_hash, player_index), player_index)
		for effect in RunData.get_player_effect(foxlab_always_convert_stats_end_of_wave_hash, player_index):
			.convert_stats([effect], player_index, permanent)
	else: #敌袭中途
		foxlab_multiply_stats(RunData.get_player_effect(foxlab_multiply_stats_half_wave_hash, player_index), player_index, permanent)
		for effect in RunData.get_player_effect(foxlab_always_convert_stats_half_wave_hash, player_index):
			.convert_stats([effect], player_index, permanent)

	.convert_stats(stats, player_index, permanent)

	if permanent:
		foxlab_try_complete_tasks(player_index)

func convert_remainder(stats: Array, player_index:int):
	if stats.empty():
		return
	for stat_to_convert in stats:
		var pct_converted:float = stat_to_convert.pct_converted/100.0
		var stat_name :int= stat_to_convert.key_hash
		var stat_dividend :int= stat_to_convert.value
		var remainder_offset:int = stat_to_convert.offset
		var keep_value = stat_to_convert.keep_value
		var to_stat:int = stat_to_convert.to_stat_hash
		var to_stat_scaling:float= stat_to_convert.to_stat_scaling
		var storage_method = stat_to_convert.storage_method
		var is_negative_key:bool = stat_to_convert.is_negative_key

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

