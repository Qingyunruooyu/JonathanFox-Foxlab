extends "res://weapons/ranged/rail_gun/railgun.gd"

func init_stats(at_wave_begin: bool = true) -> void:
	.init_stats(at_wave_begin)
	_hitbox.projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(effects, player_index, true)
