extends "res://dlcs/dlc_1/dlc_1_data.gd"

var FOXLAB_STRUCT_WITH_EFFECTS = [Keys.generate_hash("item_foxlab_reactor"), Keys.generate_hash("item_foxlab_tracker")]
var foxlab_enchanted_eyes_crate_chance = 20

func curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) :
	var already_cursed = item_data.is_cursed
	var ret = .curse_item(item_data, player_index, turn_randomization_off, min_modifier)
	if already_cursed:
		return ret

	var max_effect_modifier = ret.curse_factor
	var new_effects = []
	var effect_to_move = []
	if item_data.my_id_hash in FOXLAB_STRUCT_WITH_EFFECTS:
		var structure_effect = null
		var extra_effects = []
		for effect in ret.effects:
			if effect is StructureEffect:
				structure_effect = effect
			elif not (effect is CharmEffect and effect.value2 == 0 and effect.value == 0):
				extra_effects.append(effect)
		if structure_effect:
			structure_effect.effects = extra_effects
	else:
		for effect in ret.effects:
			var effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			var override = false
			var overriden_sign = Sign.POSITIVE
			var id: String = effect.get_id()
			var cskey: int = effect.custom_key_hash
			match [id, cskey]:
				[_, Keys.extra_item_in_crate_hash]:
					if effect.key_hash == Utils.item_foxlab_wanted_hash:
						max_effect_modifier = max(max_effect_modifier, effect_modifier)
						var extra_effect = Effect.new()
						extra_effect.key = "crate_chance"
						extra_effect.key_hash = Keys.crate_chance_hash
						extra_effect.value = foxlab_enchanted_eyes_crate_chance
						extra_effect.effect_sign = Sign.POSITIVE
						extra_effect.value = _boost_effect_value_positively(extra_effect, effect_modifier)
						ret.effects.insert(ret.effects.size() - 1, extra_effect)
				["foxlab_get_rand_weapon", _]:
					max_effect_modifier = max(max_effect_modifier, effect_modifier)
					var extra_effect = Effect.new()
					extra_effect.key = "stat_luck"
					extra_effect.key_hash = Keys.stat_luck_hash
					extra_effect.value = treasure_map_luck
					extra_effect.effect_sign = Sign.POSITIVE
					extra_effect.value = _boost_effect_value_positively(extra_effect, effect_modifier)
					new_effects.append(extra_effect)
				[_, Utils.foxlab_heal_when_kill_nearby_hash]:
					max_effect_modifier = max(max_effect_modifier, effect_modifier)
					effect.value2 = _boost_effect_value_positively(effect, effect_modifier, override, overriden_sign, true)
				["foxlab_stat_query", _]:
					effect_to_move.push_back(effect)
				["foxlab_get_rand_character", _]:
					max_effect_modifier = max(max_effect_modifier, effect_modifier)
					effect.value2 = sqrt(effect.value2 * _boost_effect_value_positively(effect, effect_modifier, override, overriden_sign, true)) as int

	ret.curse_factor = max_effect_modifier

	if not new_effects.empty():
		var back = ret.effects.pop_back()
		ret.effects.append_array(new_effects)
		ret.effects.append(back)

	if not effect_to_move.empty():
		for effect in effect_to_move:
			ret.effects.erase(effect)
		ret.effects.append_array(effect_to_move)
	return ret

func update_consumable_to_get(base_consumable_data: ConsumableData) -> ConsumableData:
	if base_consumable_data != null and base_consumable_data.my_id_hash == Keys.consumable_fruit_hash:
		var chance_poisoned = RunData.sum_all_player_effects(Keys.poisoned_fruit_hash)
		if Utils.get_chance_success(chance_poisoned / 100.0):
			return poisoned_fruit
	return .update_consumable_to_get(base_consumable_data)
