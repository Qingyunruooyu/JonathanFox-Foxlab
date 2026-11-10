extends "res://entities/structures/turret/turret.gd"

# 扩展 builder_turret.gd 的话，兼容性很差，builder相关逻辑都在本扩展经父链/鸭式探测实现

var _foxlab_builder_every_x_dirty = false
var _foxlab_is_builder_turret = false

func set_data(data: Resource) -> void:
	.set_data(data)
	_foxlab_is_builder_turret = Utils.foxlab_is_builder_turret(self)
	if _foxlab_is_builder_turret:
		set("projectiles_on_hit", WeaponService.foxlab_merge_projectiles_on_hit(effects, player_index, true))

func shoot() -> void:
	if _foxlab_is_builder_turret:
		var every_x_dict = get("_stats_every_x_shots")
		if every_x_dict != null and every_x_dict.size() > 1:
			var matched = []
			for x in every_x_dict:
				if _nb_shots_taken % x == 0:
					matched.append(x)
			if matched.size() > 1:
				stats = WeaponService.foxlab_build_combined_every_x_turret_stats(self, matched)
				_foxlab_builder_every_x_dirty = true
			elif matched.size() == 1:
				stats = every_x_dict[matched[0]]
	.shoot()

func _physics_process(_delta: float):
	if _foxlab_builder_every_x_dirty:
		_foxlab_builder_every_x_dirty = false
		if not dead and _foxlab_is_builder_turret:
			stats = WeaponService.init_structure_stats(base_stats, player_index, get("_init_stats_args_build"))
