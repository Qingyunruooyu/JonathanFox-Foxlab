extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_food_price"

#由于是比较名字，而果冻名字刚好是水母盾的子集，所以先排除水母盾
const EXCEPTION_ITEMS = ["item_jellyshield"]

const FOOD_ITEMS = ["item_cake", "item_coffee", "item_gummy_berserker", "item_lemonade",
		"item_fresh_meat", "item_mushroom", "item_potato", "item_pumpkin", "item_sad_tomato",
		"item_scared_sausage", "item_shmoop", "item_terrified_onion", "item_weird_food",
		"item_wheat", "item_dangerous_bunny", "item_spicy_sauce", "item_celery_tea", "item_fried_rice",
		"item_jelly", "item_honey", "item_jerky"]

func apply_effects_core(player_index: int, apply: bool):
	var effect = Effect.new()
	effect.custom_key_hash = Keys.specific_items_price_hash
	effect.storage_method = Effect.StorageMethod.KEY_VALUE

	for item_name in EXCEPTION_ITEMS:
		var item_hash = Keys.generate_hash(item_name)
		effect.key_hash = item_hash
		if apply:
			effect.apply(player_index)
		else:
			effect.unapply(player_index)

	effect.value = value

	var applied: Dictionary = {}
	for item_name in FOOD_ITEMS:
		var item_hash = Keys.generate_hash(item_name)
		if item_hash in applied:
			continue
		effect.key_hash = item_hash
		if apply:
			effect.apply(player_index)
		else:
			effect.unapply(player_index)
		applied[item_hash] = 1

func apply(player_index: int) -> void:
	apply_effects_core(player_index, true)

func unapply(player_index: int) -> void:
	apply_effects_core(player_index, false)

func get_args(_player_index: int) -> Array:
	return [str(value)]
