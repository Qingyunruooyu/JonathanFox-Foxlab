extends "res://dlcs/dlc_1/dlc_1_data.gd"

var STRUCT_WITH_EFFECTS = [Keys.generate_hash("item_foxlab_reactor"), Keys.generate_hash("item_foxlab_tracker")]

func curse_item(item_data: ItemParentData, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0) :
	var already_cursed = item_data.is_cursed
	var ret = .curse_item(item_data, player_index, turn_randomization_off, min_modifier)
	if not already_cursed and item_data.my_id_hash in STRUCT_WITH_EFFECTS:
		var structure_effect = null
		var extra_effects = []
		for effect in ret.effects:
			if effect is StructureEffect:
				structure_effect = effect
			elif not (effect is CharmEffect and effect.value2 == 0 and effect.value == 0):
				extra_effects.append(effect)
		if structure_effect:
			structure_effect.effects = extra_effects
	return ret
