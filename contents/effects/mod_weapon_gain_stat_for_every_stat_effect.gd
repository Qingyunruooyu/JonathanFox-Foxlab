class_name FoxLabWeaponGainStatForEveryStatEffect
extends "res://effects/weapons/weapon_gain_stat_for_every_stat_effect.gd"

static func get_id() -> String:
	return "foxlab_effect_weapon_gain_stat_for_every_stat"

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.increased_stat_name = increased_stat_name
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	increased_stat_name = serialized.increased_stat_name
