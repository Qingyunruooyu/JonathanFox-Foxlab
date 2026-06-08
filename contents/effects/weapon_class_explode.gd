extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_weapon_class_explode"

func get_args(_player_index: int) -> Array:
	var set_name = tr(ItemService.get_set(key_hash).name)
	return [set_name, set_name]
