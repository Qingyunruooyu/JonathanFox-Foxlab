class_name FoxLabTurretEffect
extends "res://effects/items/turret_effect.gd"

static func get_id() -> String:
	return "foxlab_effect_turret"

func unapply(player_index: int) -> void :
	var effects = RunData.get_player_effects(player_index)[Keys.structures_hash]
	var num =  effects.size()
	.unapply(player_index)
	var num_after =  effects.size()
	if num_after < num:
		return
	for effect in effects:
		if effect.get_id() == get_id() and effect.text_key == text_key and\
			 effect.get_args(player_index) == get_args(player_index):
			effects.erase(effect)
			return


