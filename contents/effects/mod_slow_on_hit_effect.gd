extends "res://effects/weapons/weapon_slow_on_hit_effect.gd"

static func get_id() -> String:
	return "foxlab_weapon_slow_on_hit"

# 官方代码没有异步初始化，导致哈希永远是工程学的
func _generate_hashes():
	._generate_hashes()
	scaling_stat_hash = Keys.generate_hash(scaling_stat)
