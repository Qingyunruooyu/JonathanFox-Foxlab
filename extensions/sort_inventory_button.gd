extends "res://ui/menus/pages/sort_inventory_button.gd"

func foxlab_need_pin(elements: Array) -> bool:
	var has_character = false
	var has_item = false
	for element in elements:
		match element.item.get_category():
			Category.CHARACTER:
				has_character = true
			Category.ITEM:
				has_item = true
			_:
				return false
		if has_character and has_item:
			return true
	return false

func _sort_inventory(index: int = - 10, _inventory: Inventory = null):
	._sort_inventory(index, _inventory)
	var elements = inventory_to_sort.get_children()
	if elements.size() > inventory_to_sort.columns and foxlab_need_pin(elements):
		for i in range(elements.size() - 1, -1, -1):
			var element = elements[i]
			if element.item.get_category() == Category.CHARACTER or element.item.my_id_hash in Utils.foxlab_item_pinned_in_inventory:
				inventory_to_sort.move_child(element, 0)
