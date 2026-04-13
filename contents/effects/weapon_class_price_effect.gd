extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_weapon_class_price"

func apply(player_index: int) -> void:
	var effect = Effect.new()
	effect.custom_key = "specific_items_price"
	effect.custom_key_hash = Keys.specific_items_price_hash
	effect.storage_method = Effect.StorageMethod.KEY_VALUE
	effect.value = value
	var applied: Dictionary = {}
	for weapon in ItemService.weapons:
		if weapon.weapon_id_hash in applied:
			continue
		for set in weapon.sets:
			if set.my_id_hash == key_hash:
				effect.key = weapon.weapon_id
				effect.key_hash = weapon.weapon_id_hash
				effect.apply(player_index)
				applied[weapon.weapon_id_hash] = 1


func unapply(player_index: int) -> void:
	var effect = Effect.new()
	effect.custom_key = "specific_items_price"
	effect.custom_key_hash = Keys.specific_items_price_hash
	effect.storage_method = Effect.StorageMethod.KEY_VALUE
	effect.value = value
	var applied: Dictionary = {}
	for weapon in ItemService.weapons:
		if weapon.weapon_id_hash in applied:
			continue
		for set in weapon.sets:
			if set.my_id_hash == key_hash:
				effect.key = weapon.weapon_id
				effect.key_hash = weapon.weapon_id_hash
				effect.unapply(player_index)
				applied[weapon.weapon_id_hash] = 1

func get_args(_player_index: int) -> Array:
	var set = ItemService.get_set(key_hash)
	return [str(value), tr(set.name)]
