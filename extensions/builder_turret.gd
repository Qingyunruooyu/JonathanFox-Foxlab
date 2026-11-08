extends "res://entities/structures/turret/builder/builder_turret.gd"

func set_data(data: Resource) -> void:
	.set_data(data)
	projectiles_on_hit = WeaponService.foxlab_merge_projectiles_on_hit(effects, player_index, false)
