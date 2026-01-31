extends "res://ui/menus/pages/sort_inventory_button.gd"

func _sort_inventory(index: int = - 10, _inventory: Inventory = null):
	._sort_inventory(index, _inventory)
	var push_character_ahead = false
	for i in range(RunData.get_player_count()):
		if RunData.get_player_character(i) and RunData.get_nb_item(Utils.item_foxlab_mask_hash, i) > 0:
			push_character_ahead = true
			break
	if push_character_ahead:
		for element_instance in inventory_to_sort.get_children():
			if element_instance.item is CharacterData or element_instance.item.my_id_hash == Utils.item_foxlab_mask_hash or  element_instance.item.my_id_hash in Keys.item_builder_turret_n_hash:
				inventory_to_sort.move_child(element_instance, 0)
