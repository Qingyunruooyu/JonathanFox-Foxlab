extends "res://ui/menus/shop/shop_item.gd"

onready var foxlab_material_icon = preload("res://items/materials/material_ui.png")

func set_shop_item(p_item_data: ItemParentData, p_wave_value: int = RunData.current_wave)->void :
	.set_shop_item(p_item_data, p_wave_value)
	if !RunData.get_player_effect_bool("hp_shop", player_index):
		if RunData.is_coop_run:
			_button.set_material_icon(foxlab_material_icon, CoopService.get_player_color(player_index))
		else:
			_button.set_material_icon(foxlab_material_icon, Utils.GOLD_COLOR)

	RunData.foxlab_set_item_description(_item_description, p_item_data, player_index)
