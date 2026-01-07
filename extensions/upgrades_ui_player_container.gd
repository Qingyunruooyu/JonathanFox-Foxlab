extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

func show_item(item_data: ItemParentData) -> void :
	.show_item(item_data)
	RunData.foxlab_set_item_description(_item_description, item_data, player_index)
