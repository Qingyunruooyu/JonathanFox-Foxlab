extends "res://ui/menus/shop/item_description.gd"

func set_item(item_data: ItemParentData, player_index: int, item_count: = 1) -> void :
	.set_item(item_data, player_index, item_count)
	if _category.text == tr("ITEM"):
		var number = RunData.get_nb_item(item_data.my_id, player_index);
		_category.text += "(%s/∞)" % [str(number)]
	elif _category.text == tr("UNIQUE"):
		var number = RunData.get_nb_item(item_data.my_id, player_index);
		if number > 1:
			_category.text += "(%s/1)" % [str(number)]
