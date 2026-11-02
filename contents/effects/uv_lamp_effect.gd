extends  "res://effects/items/turret_effect.gd"

export (float) var expose_range_ratio = 2.0
var bonus_percent = null

static func get_id() -> String:
	return "foxlab_uv_lamp"


func apply(player_index: int) -> void:
	.apply(player_index)
	RunData.get_player_effects(player_index)[Utils.foxlab_uv_lamp_hash] += value
	Utils.reset_stat_cache(player_index)


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[Utils.foxlab_uv_lamp_hash] -= value
	Utils.reset_stat_cache(player_index)
	.unapply(player_index)

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	_init_stats_args_turret.effects = effects
	var init_stats = WeaponService.init_structure_stats(stats, player_index, _init_stats_args_turret)
	args.push_back(str(min(init_stats.max_range, stats.max_range * expose_range_ratio)))
	if bonus_percent == null:
		var exposed_behavior = load("res://mods-unpacked/JonathanFox-FoxLab/contents/effect_behaviors/enemy/exposed_enemy_effect_behavior.tscn").instance()
		bonus_percent = exposed_behavior.bonus_damage_taken_percent
		exposed_behavior.free()
	var count_hash: int = Utils.foxlab_uv_lamp_instance_hash if RunData.wave_in_progress else Utils.foxlab_uv_lamp_hash
	args.push_back(str(bonus_percent))
	args.push_back(str(RunData.sum_all_player_effects(count_hash) * bonus_percent))
	return args
