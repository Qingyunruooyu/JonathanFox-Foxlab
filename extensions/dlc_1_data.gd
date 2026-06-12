extends "res://dlcs/dlc_1/dlc_1_data.gd"

func curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) :
	var already_cursed = item_data.is_cursed
	var ret = .curse_item(item_data, player_index, turn_randomization_off, min_modifier)
	if already_cursed:
		return ret
	return Utils.foxlab_extra_curse_item(item_data, player_index, turn_randomization_off, min_modifier, ret, self)

func update_consumable_to_get(base_consumable_data: ConsumableData) -> ConsumableData:
	if base_consumable_data != null and base_consumable_data.my_id_hash == Keys.consumable_fruit_hash:
		var chance_poisoned = RunData.sum_all_player_effects(Keys.poisoned_fruit_hash)
		if Utils.get_chance_success(chance_poisoned / 100.0):
			return poisoned_fruit
	return .update_consumable_to_get(base_consumable_data)
