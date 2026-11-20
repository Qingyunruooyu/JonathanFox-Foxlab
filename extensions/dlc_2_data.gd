extends "res://dlcs/dlc_2/dlc_2_data.gd"

const FOXLAB_MUTATION_COPY_BLACKLIST_IDS = [
	"foxlab_all_or_nothing",
	"foxlab_apply_only",
	"foxlab_destroy_weapons",
	"foxlab_entity_price",
	"foxlab_gain_stat_query",
	"foxlab_get_item",
	"foxlab_get_rand_character",
	"foxlab_get_rand_weapon",
	"foxlab_magician",
	"foxlab_multiply_stat",
	"foxlab_set_stat",
	"foxlab_stat_gain_mod",
	"foxlab_stat_query",
	"foxlab_stat_recover",
	"foxlab_stats_end_of_wave_after_wave",
	"foxlab_swap_stats",
	"foxlab_take_away",
	"foxlab_task",
	"foxlab_uv_lamp",
	"foxlab_weapon_class_price",
	"foxlab_weapon_gain_stat_for_every_stat",
	"foxlab_weapon_slow_on_hit",
	"foxlab_weapon_text",
	"linear_scaling_effect",
]

var _foxlab_mutation_rules_initialized = false
var _foxlab_mutation_context_player: int = -1


func _foxlab_init_mutation_rules() -> void:
	if _foxlab_mutation_rules_initialized:
		return

	mutation_copy_blacklist.append_array([
		Utils.foxlab_ball_lightning_hash,
		Utils.foxlab_bonus_item_on_bought_hash,
		Utils.foxlab_bonus_reroll_weapon_tier_hash,
		Utils.foxlab_charm_all_when_fully_heal_hash,
		Utils.foxlab_copy_weapon_on_summon_birth_hash,
		Utils.foxlab_effect_receive_item_at_wave_hash,
		Utils.foxlab_effect_receive_item_at_wave_end_hash,
		Utils.foxlab_force_remove_on_reroll_hash,
		Utils.foxlab_gain_scapegoat_no_hurt_hash,
		Utils.foxlab_increase_tier_on_rerolls_hash,
		Utils.foxlab_instant_poisoned_attracting_hash,
		Utils.foxlab_knockback_aura_hash,
		Utils.foxlab_mask_fail_refund_hash,
		Utils.foxlab_multiply_stats_half_wave_hash,
		Utils.foxlab_multiply_stats_end_of_wave_hash,
		Utils.foxlab_scapegoat_no_heal_hash,
		Utils.foxlab_spawn_enemy_via_gold_bag_hash,
		Utils.foxlab_stats_end_of_wave_after_wave_hash,
		Utils.foxlab_temp_stats_on_structure_crit_hash,
		Utils.foxlab_weapon_class_explode_hash,
	])
	var boolean_keys = [
		Utils.foxlab_add_xp_on_getting_gold_hash,
		Utils.foxlab_assemble_tracker_on_hurt_hash,
		Utils.foxlab_bounce_player_projectile_hash,
		Utils.foxlab_burning_proof_hash,
		Utils.foxlab_buy_item_increase_tier_hash,
		Utils.foxlab_curse_item_by_price_hash,
		Utils.foxlab_faceless_enable_upgrade_on_transform_hash,
		Utils.foxlab_gain_stat_on_mutate_hash,
		Utils.foxlab_instant_burn_hash,
		Utils.foxlab_item_upgrade_hash,
		Utils.foxlab_keep_random_weapon_hash,
		Utils.foxlab_lost_hp_on_losing_gold_hash,
		Utils.foxlab_material_ctrl_hash,
		Utils.foxlab_no_trees_hash,
		Utils.foxlab_piercing_is_bounce_hash,
		Utils.foxlab_remember_shop_items_hash,
		Utils.foxlab_turret_target_hash,
	]
	mutation_boolean_keys.append_array(boolean_keys)
	mutation_cumulative_explosion_keys.append(Utils.foxlab_explode_on_burn_hash)
	mutation_saturating_chance_keys.append(Utils.foxlab_upgrade_locked_item_on_reroll_hash)
	# TODO(jona): remove when compatible
	var saturating_chance_custom_keys = get("mutation_saturating_chance_custom_keys")
	if saturating_chance_custom_keys != null:
		saturating_chance_custom_keys.append(Utils.foxlab_landmines_on_death_chance_hash)
	mutation_scaled_value2_keys.append(Utils.foxlab_heal_when_kill_nearby_hash)
	mutation_min_scale[Utils.foxlab_projectile_on_hit_hash] = 0.7
	_foxlab_mutation_rules_initialized = true


func _foxlab_has_character(char_hash: int, player_index: int) -> bool:
	return player_index >= 0 and RunData.get_nb_item(char_hash, player_index) > 0


func mutant_item(item_data, player_index: int):
	_foxlab_mutation_context_player = player_index
	var result = .mutant_item(item_data, player_index)
	_foxlab_mutation_context_player = -1
	return result


func can_effect_be_copied_by_mutation(effect, player_index: int = -1) -> bool:
	_foxlab_init_mutation_rules()
	if FOXLAB_MUTATION_COPY_BLACKLIST_IDS.has(effect.get_id()):
		return false
	if effect.custom_key_hash == Utils.foxlab_gain_stat_every_killed_enemies_hash and effect.value2 <= 0:
		return false
	if player_index >= 0 and effect.key_hash == Keys.consumable_heal_hash \
			and _foxlab_has_character(Utils.character_foxlab_alchemist_hash, player_index):
		return false
	if player_index >= 0 and _foxlab_has_character(Utils.character_foxlab_antimatter_hash, player_index) \
			and RunData.get_stat_gain(effect.key_hash, player_index) < 0.0:
		return false
	if player_index >= 0 and effect.key_hash == Utils.foxlab_recover_lost_item_hash:
		var chance: int = 0
		for entry in RunData.get_player_effect(Utils.foxlab_recover_lost_item_hash, player_index):
			chance += entry[0]
		if chance >= MAX_USEFUL_CHANCE:
			return false
	return .can_effect_be_copied_by_mutation(effect, player_index)


func _scale_copied_effect(effect, player_index: int) -> void:
	if effect.key_hash == Utils.foxlab_projectile_on_hit_hash:
		effect.value = max(1, int(ceil(abs(effect.value) * pow(get_mutation_scale(player_index), 2.0))))
		return
	._scale_copied_effect(effect, player_index)
	if effect.custom_key_hash == Utils.foxlab_gain_stat_every_killed_enemies_hash and effect.value2 > 0:
		effect.value2 = int(ceil(effect.value2 / get_mutation_scale(player_index)))


func _can_merge_tumor_effects(a, b) -> bool:
	if a.custom_key_hash == Utils.foxlab_heal_when_kill_nearby_hash or b.custom_key_hash == Utils.foxlab_heal_when_kill_nearby_hash:
		return false
	return ._can_merge_tumor_effects(a, b)


func _get_removable_negative_effect_indexes(item_data) -> Array:
	_foxlab_init_mutation_rules()
	var indexes = ._get_removable_negative_effect_indexes(item_data)
	var player_index: int = _foxlab_mutation_context_player
	if player_index < 0:
		return indexes
	var has_alchemist: bool = _foxlab_has_character(Utils.character_foxlab_alchemist_hash, player_index)
	var has_antimatter: bool = _foxlab_has_character(Utils.character_foxlab_antimatter_hash, player_index)
	if not has_alchemist and not has_antimatter:
		return indexes
	for i in range(indexes.size() - 1, -1, -1):
		var effect = item_data.effects[indexes[i]]
		if (has_alchemist and effect.key_hash == Keys.consumable_heal_hash) \
				or (has_antimatter and RunData.get_stat_gain(effect.key_hash, player_index) < 0.0):
			indexes.remove(i)
	return indexes
