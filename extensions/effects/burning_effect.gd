extends "res://effects/weapons/burning_effect.gd"

func get_args(player_index: int) -> Array:
	var first_scaling_stat = Utils.get_first_scaling_stat(burning_data.scaling_stats)
	var is_structure = false
	if first_scaling_stat == Keys.stat_engineering_hash:
		is_structure = true

	var current_burning_data = WeaponService.init_burning_data(burning_data, player_index, is_structure)
	var scaling_stats = WeaponService.get_scaling_stats_icon_text(current_burning_data.scaling_stats)
	return [str(current_burning_data.duration), str(current_burning_data.damage), scaling_stats]
