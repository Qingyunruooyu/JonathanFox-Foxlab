extends "res://singletons/weapon_service.gd"

func _set_common_ranged_stats(new_stats: RangedWeaponStats, from_stats: RangedWeaponStats, player_index: int):
	._set_common_ranged_stats(new_stats, from_stats, player_index)
	if not RunData.get_player_effect_bool("foxlab_piercing_is_bounce", player_index):
		return
	var piercing = new_stats.piercing
	new_stats.piercing = 0
	if from_stats.can_bounce:
		new_stats.bounce += piercing

func set_projectile_effects(base_effects: Array, player_index: int = - 1) -> Array:
	if player_index >= 0 and RunData.get_player_effect_bool("foxlab_piercing_is_bounce", player_index):
		for effect in base_effects:
			if effect.key == "pierce_on_crit":
				effect.key = "bounce_on_crit"
	return .set_projectile_effects(base_effects, player_index)
