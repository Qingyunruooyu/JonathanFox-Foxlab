extends "res://weapons/weapon.gd"

var _foxlab_every_x_combo_cache = {}

func queue_free():
	Utils.foxlab_queue_free_weapon(self)

func init_stats(at_wave_begin: bool = true) -> void:
	.init_stats(at_wave_begin)
	_foxlab_every_x_combo_cache.clear()
	_hitbox.projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(effects, player_index, true)

func shoot() -> void:
	var dict = _stats_every_x_shots
	var dict_size = dict.size()
	if dict_size <= 1 or dict_size > 62:
		.shoot()
		return
	var shot_nb = _nb_shots_taken + 1
	var bits = 0
	var count = 0
	var lowest = 0
	var i = 0
	for x in dict:
		if shot_nb % x == 0:
			bits |= 1 << i
			if count == 0:
				lowest = x
			count += 1
		i += 1
	if count <= 1:
		.shoot()
		return
	var combo_dict = _foxlab_every_x_combo_cache.get(bits)
	if combo_dict == null:
		var matched = []
		i = 0
		for x in dict:
			if bits & (1 << i):
				matched.append(x)
			i += 1
		combo_dict = {lowest: WeaponService.foxlab_build_combined_every_x_stats(self, matched)}
		_foxlab_every_x_combo_cache[bits] = combo_dict
	var dict_backup = dict
	_stats_every_x_shots = combo_dict
	.shoot()
	_stats_every_x_shots = dict_backup
