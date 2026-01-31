extends "res://ui/menus/pages/menu_confirm.gd"

func _on_ConfirmButton_pressed() -> void :
	if RunData.wave_in_progress:
		for player_index in range(RunData.get_player_count()):
			if RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
				RunData.foxlab_forget_item(player_index)
	._on_ConfirmButton_pressed()
