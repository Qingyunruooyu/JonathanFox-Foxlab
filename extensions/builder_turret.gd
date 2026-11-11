extends "res://entities/structures/turret/builder/builder_turret.gd"

# 每X组合快照缓存，键为排序后的X组合；reload_data/set_current_stats时清空（后者覆盖同文件名缓存命中分支）
var _foxlab_every_x_combo_cache = {}

func reload_data() -> void:
	.reload_data()
	_foxlab_every_x_combo_cache.clear()
	projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(effects, player_index, true)

func set_current_stats(new_stats: RangedWeaponStats) -> void:
	.set_current_stats(new_stats)
	_foxlab_every_x_combo_cache.clear()
	projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(effects, player_index, true)

func shoot() -> void:
	if _stats_every_x_shots.size() > 1:
		var matched = []
		for x in _stats_every_x_shots:
			if _nb_shots_taken % x == 0:
				matched.append(x)
		if matched.size() > 1:
			matched.sort()
			var combined = _foxlab_every_x_combo_cache.get(str(matched))
			if combined == null:
				combined = WeaponService.foxlab_build_combined_every_x_turret_stats(self, matched)
				_foxlab_every_x_combo_cache[str(matched)] = combined
			var dict_backup = _stats_every_x_shots
			_stats_every_x_shots = {matched[0]: combined}
			.shoot()
			_stats_every_x_shots = dict_backup
			return
	.shoot()
