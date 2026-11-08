extends "res://weapons/weapon.gd"

# 同炮命中多个X的每X投射组合变体缓存，键为排序后的X组合；init_stats时清空
var _foxlab_every_x_combo_cache = {}

func queue_free():
	Utils.foxlab_queue_free_weapon(self)

func init_stats(at_wave_begin: bool = true) -> void:
	.init_stats(at_wave_begin)
	_foxlab_every_x_combo_cache.clear()
	_hitbox.projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(effects, player_index, true)

func shoot() -> void:
	var shot_nb = _nb_shots_taken + 1
	var matched = []
	for x in _stats_every_x_shots:
		if shot_nb % x == 0:
			matched.append(x)
	if matched.size() <= 1:
		.shoot()
		return
	# 原版多命中时快照互相覆盖、结束时恢复成错误stats；换成组合快照，
	# 字典临时替换成唯一命中键（用本炮序号，必被整除），基类换入/恢复各只执行一次
	matched.sort()
	var combined = _foxlab_every_x_combo_cache.get(str(matched))
	if combined == null:
		combined = WeaponService.foxlab_build_combined_every_x_stats(self, matched)
		_foxlab_every_x_combo_cache[str(matched)] = combined
	var dict_backup = _stats_every_x_shots
	_stats_every_x_shots = {shot_nb: combined}
	.shoot()
	_stats_every_x_shots = dict_backup
