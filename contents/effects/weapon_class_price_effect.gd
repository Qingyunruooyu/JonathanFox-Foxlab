extends "res://mods-unpacked/JonathanFox-FoxLab/contents/base_effects/batch_apply_effect.gd"

static func get_id() -> String:
	return "foxlab_weapon_class_price"

func apply_effects_core(player_index: int, call_func: String):
	var effect = Effect.new()
	effect.custom_key_hash = Keys.specific_items_price_hash
	effect.storage_method = Effect.StorageMethod.KEY_VALUE
	effect.value = value
	var applied: Dictionary = {}
	for weapon in ItemService.weapons:
		if weapon.weapon_id_hash in applied:
			continue
		for set in weapon.sets:
			if set.my_id_hash == key_hash:
				effect.key_hash = weapon.weapon_id_hash
				effect.call(call_func, player_index)
				applied[weapon.weapon_id_hash] = 1


func get_args(_player_index: int) -> Array:
	var set_name = tr(ItemService.get_set(key_hash).name)
	return [str(value), set_name]
