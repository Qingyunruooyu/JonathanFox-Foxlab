class_name FoxlabWeaponClassPriceEffect
extends Effect

static func get_id() -> String:
	return "foxlab_effect_weapon_class_price"

func apply(player_index: int) -> void:
	var effect = Effect.new()
	effect.custom_key = "specific_items_price"
	effect.storage_method = Effect.StorageMethod.KEY_VALUE
	effect.value = value
	var applied: Dictionary = {}
	for weapon in ItemService.weapons:
		if weapon.weapon_id in applied:
			continue
		for set in weapon.sets:
			if set.my_id == key:
				effect.key = weapon.weapon_id
				effect.apply(player_index)
				applied[weapon.weapon_id] = 1


func unapply(player_index: int) -> void:
	var effect = Effect.new()
	effect.custom_key = "specific_items_price"
	effect.storage_method = Effect.StorageMethod.KEY_VALUE
	effect.value = value
	var applied: Dictionary = {}
	for weapon in ItemService.weapons:
		if weapon.weapon_id in applied:
			continue
		for set in weapon.sets:
			if set.my_id == key:
				effect.key = weapon.weapon_id
				effect.unapply(player_index)
				applied[weapon.weapon_id] = 1

func get_args(_player_index: int) -> Array:
	var set = ItemService.get_set(key)
	return [str(value), tr(set.name)]
