extends "res://ui/menus/shop/item_description.gd"

var foxlab_expand_indefinitely = true

func _ready() -> void :
	foxlab_expand_indefinitely = expand_indefinitely

func set_item(item_data: ItemParentData, player_index: int, item_count: int = 1)->void :
	var is_special_upgrade = item_data is UpgradeData and not Utils.foxlab_is_vanilla_upgrade(item_data)
	if is_special_upgrade:
		item_data = item_data.get_meta("foxlab_item", item_data)

	if (RunData.shop_effects_checked and item_data.effects.size() > 9) or (not RunData.is_coop_run and is_special_upgrade):
		expand_indefinitely = false
	else:
		expand_indefinitely = foxlab_expand_indefinitely

	_vbox_container.visible = show_details and expand_indefinitely
	_scroll_container.visible = show_details and not expand_indefinitely

	.set_item(item_data, player_index, item_count)

	if item_data is ItemData and not item_data is CharacterData and not item_data is UpgradeData and not item_data is DifficultyData:
		if item_data.max_nb <= 0:
			var number = RunData.get_nb_item(item_data.my_id_hash, player_index);
			_category.text += "(%s/∞)" % [str(number)]
		elif item_data.max_nb == 1:
			var number = RunData.get_nb_item(item_data.my_id_hash, player_index);
			if number > 1:
				_category.text += "(%s/1)" % [str(number)]

