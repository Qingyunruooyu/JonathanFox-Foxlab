extends "res://ui/menus/ingame/item_panel_ui.gd"

func set_data(p_item_data: ItemParentData, player_index: int) -> void :
	.set_data(p_item_data, player_index)
	RunData.foxlab_set_item_description(_item_description, p_item_data, player_index)

