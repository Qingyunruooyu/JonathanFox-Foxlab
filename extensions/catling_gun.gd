extends "res://entities/units/pet/catling_gun/catling_gun.gd"

onready var _foxlab_range_shape = $TargetTriggerZone / CollisionShape2D

func reload_data():
	.reload_data()
	if _foxlab_range_shape:
		_foxlab_range_shape.shape.radius = _current_weapon_stats.max_range

func set_current_stats(stats: Array) -> void :
	.set_current_stats(stats)
	if _foxlab_range_shape:
		_foxlab_range_shape.shape.radius = _current_weapon_stats.max_range