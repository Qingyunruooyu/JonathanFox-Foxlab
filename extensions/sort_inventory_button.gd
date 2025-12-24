extends "res://ui/menus/pages/sort_inventory_button.gd"

func _sort_inventory_button(index: int = - 10, _inventory: Inventory = null):
	._sort_inventory_button(index, _inventory)
	var push_character_ahead = false
	for i in range(RunData.get_player_count()):
		if RunData.get_player_character(i) and RunData.get_nb_item("item_foxlab_mask", i) > 0:
			push_character_ahead = true
			break
	if push_character_ahead:
		for element_instance in inventory_to_sort.get_children():
			if element_instance.item is CharacterData or element_instance.item.my_id == "item_foxlab_mask" or  "item_builder_turret" in element_instance.item.my_id:
				inventory_to_sort.move_child(element_instance, 0)
