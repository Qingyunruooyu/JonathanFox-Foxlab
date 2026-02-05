extends "res://ui/menus/shop/item_description.gd"

func set_item(item_data: ItemParentData, player_index: int, item_count: int = 1)->void :
	.set_item(item_data, player_index, item_count)
	if item_data is ItemData and not item_data is CharacterData and not item_data is UpgradeData and not item_data is DifficultyData:
		if item_data.max_nb <= 0:
			var number = RunData.get_nb_item(item_data.my_id_hash, player_index);
			_category.text += "(%s/∞)" % [str(number)]
		elif item_data.max_nb == 1:
			var number = RunData.get_nb_item(item_data.my_id_hash, player_index);
			if number > 1:
				_category.text += "(%s/1)" % [str(number)]
