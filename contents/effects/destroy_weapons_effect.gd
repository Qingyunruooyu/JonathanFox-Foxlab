extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_destroy_weapons"

func apply(player_index: int) -> void:
	if RunData.get_player_effect_bool(Keys.lock_current_weapons_hash, player_index):
		return

	for weapon in RunData.get_player_weapons_ref(player_index):
		var base_recycling_value = weapon.value
		var specific_recycling_price_factor = 1.0
		for specific_item_price in RunData.get_player_effect(Keys.specific_items_price_hash, player_index):
			assert (specific_item_price[0] is int)
			if Keys.hash_to_string[specific_item_price[0]] in weapon.my_id:
				specific_recycling_price_factor = specific_item_price[1] / 100.0
				break
		base_recycling_value *= specific_recycling_price_factor
		var recycle_value = ItemService.get_recycling_value(RunData.current_wave, base_recycling_value, player_index)
		RunData.add_gold(recycle_value, player_index)
		RunData.update_recycling_tracking_value(weapon, player_index)
	RunData.remove_all_weapons(player_index)
	SoundManager.play(preload("res://resources/sounds/metal_small_movement_06.wav"))

func unapply(_player_index: int) -> void:
	pass
