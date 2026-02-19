extends "res://effects/weapons/weapon_gain_stat_for_every_stat_effect.gd"


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.increased_stat_name = increased_stat_name
	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	increased_stat_name = serialized.increased_stat_name
