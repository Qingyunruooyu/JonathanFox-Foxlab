extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_entity_price"

func apply_effects_core(player_index: int, apply: bool):
	var function = ""
	match key_hash:
		Keys.pet_hash:
			function = "is_pet_item"
		Keys.structure_hash:
			function = "is_structure_item"
		_:
			return
	var effect = Effect.new()
	effect.custom_key_hash = Keys.specific_items_price_hash
	effect.storage_method = Effect.StorageMethod.KEY_VALUE
	effect.value = value
	var applied: Dictionary = {}
	for weapon in ItemService.weapons:
		if weapon.weapon_id_hash in applied:
			continue
		if weapon.call(function):
			effect.key_hash = weapon.weapon_id_hash
			if apply:
				effect.apply(player_index)
			else:
				effect.unapply(player_index)
			applied[weapon.weapon_id_hash] = 1
	for item in ItemService.items:
		if item.my_id_hash in applied:
			continue
		if item.call(function):
			effect.key_hash = item.my_id_hash
			if apply:
				effect.apply(player_index)
			else:
				effect.unapply(player_index)
			applied[item.my_id_hash] = 1

func apply(player_index: int) -> void:
	apply_effects_core(player_index, true)

func unapply(player_index: int) -> void:
	apply_effects_core(player_index, false)

