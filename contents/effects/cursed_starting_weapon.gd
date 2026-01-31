class_name FoxLabCursedWeaponEffect
extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_effect_cursed_starting_weapon"

func get_args(_player_index: int) -> Array:
	if custom_key_hash == Keys.cursed_starting_weapon_hash:
		var displayed_key = key.substr(0, key.length() - 2)
		return [str(value), tr(displayed_key.to_upper())]
	return .get_args(_player_index)
