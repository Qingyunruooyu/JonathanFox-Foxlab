extends "res://singletons/entity_service.gd"

const FOXLAB_TURRET_KEYS = {"effect_foxlab_reactor": 1,  "effect_foxlab_funnel": 2, "effect_foxlab_demon_pull": 6, "effect_foxlab_aquila": 7,  "effect_foxlab_tracker": 9}

var foxlab_turret_keys_all = {"effect_builder_turret_alt": 0, "effect_turret_rocket": 3, "effect_turret_laser": 4, "effect_tyler": 5,
		"effect_turret_flame": 8, "effect_turret": 10, "effect_turret_healing": 11}

func _ready():
	foxlab_turret_keys_all.merge(FOXLAB_TURRET_KEYS)


func sort_turrets_by_strength(a: TurretEffect, b: TurretEffect) -> bool:
	if not a.text_key in FOXLAB_TURRET_KEYS and not b.text_key in FOXLAB_TURRET_KEYS:
		return .sort_turrets_by_strength(a, b)
	var a_index: int = foxlab_turret_keys_all.get_or_add(a.text_key, Utils.LARGE_NUMBER)
	var b_index: int = foxlab_turret_keys_all.get_or_add(b.text_key, Utils.LARGE_NUMBER)
	return a_index <= b_index

