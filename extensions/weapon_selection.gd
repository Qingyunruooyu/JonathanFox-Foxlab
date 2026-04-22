extends "res://ui/menus/run/weapon_selection.gd"

func _get_unlocked_elements(player_index: int) -> Array:
	var elements_unlocked = ._get_unlocked_elements(player_index)
	if RunData.get_player_character(player_index).my_id_hash == Utils.character_foxlab_faceless_hash:
		var mask_item = ItemService.get_element(ItemService.items, Utils.item_foxlab_mask_hash)
		for effect in mask_item.effects:
			if effect.get_id() == "foxlab_get_rand_character":
				effect.try_generate(player_index)
		for meta in RunData.get_foxlab_mask_meta(player_index):
			for character in meta.chars:
				for item in ItemService.get_ordered_starting_weapons(character.starting_weapons):
					if not elements_unlocked.has(item.my_id_hash) and ProgressData.weapons_unlocked.has(item.weapon_id_hash):
						elements_unlocked.push_back(item.my_id_hash)
				for item in ItemService.get_ordered_starting_items(character.starting_items):
					if not elements_unlocked.has(item.my_id_hash) and ProgressData.items_unlocked.has(item.my_id_hash):
						elements_unlocked.push_back(item.my_id_hash)

	return elements_unlocked

func _get_all_possible_elements(player_index: int) -> Array:
	var elements = ._get_all_possible_elements(player_index)
	if RunData.get_player_character(player_index).my_id_hash == Utils.character_foxlab_faceless_hash:
		var mask_item = ItemService.get_element(ItemService.items, Utils.item_foxlab_mask_hash)
		for effect in mask_item.effects:
			if effect.get_id() == "foxlab_get_rand_character":
				effect.try_generate(player_index)
		for meta in RunData.get_foxlab_mask_meta(player_index):
			for character in meta.chars:
				for item in ItemService.get_ordered_starting_weapons(character.starting_weapons):
					if not item in elements:
						elements.push_back(item)
				for item in ItemService.get_ordered_starting_items(character.starting_items):
					if not item in elements:
						elements.push_back(item)
	return elements
