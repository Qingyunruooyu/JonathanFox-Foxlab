class_name FoxLabItemExplodingEffect
extends "res://effects/items/item_exploding_effect.gd"

static func get_id() -> String:
	return "foxlab_effect_item_exploding"

func unapply(player_index: int) -> void :
	var effects = RunData.get_player_effects(player_index)[key]
	var num =  effects.size()
	.unapply(player_index)
	var num_after =  effects.size()
	if num_after < num:
		return
	for effect in effects:
		if effect.get_id() == get_id() and effect.scale_with_missing_health == scale_with_missing_health and\
			effect.tracking_key == tracking_key and effect.get_args(player_index) == get_args(player_index):
			effects.erase(effect)
			return
