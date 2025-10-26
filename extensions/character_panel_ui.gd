extends "res://ui/menus/ingame/character_panel_ui.gd"

func set_data(p_item_data: ItemParentData, _player_index: int) -> void :
	var list_of_items: Array = []
	var ret_item_data = p_item_data.duplicate()
	var recover:Array = []
	for effect in ret_item_data.effects:
		match effect.custom_key:
			"cursed_starting_weapon":
				effect.custom_key = "starting_weapon"
				recover.append(effect)
	.set_data(ret_item_data, _player_index)
	for effect in recover:
		effect.custom_key = "cursed_starting_weapon"
