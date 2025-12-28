extends "res://entities/units/unit/unit.gd"

func apply_burning(burning_data: BurningData) -> void :
	if not dead:
		_speed_percent_modifier = Utils.get_scene_node().foxlab_burning_enemy_speed
	.apply_burning(burning_data)


func stop_burning() -> void :
	_speed_percent_modifier = 0
	.stop_burning()

