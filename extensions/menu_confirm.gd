extends "res://ui/menus/pages/menu_confirm.gd"

func _on_ConfirmButton_pressed() -> void :
	if RunData.wave_in_progress:
		for player_index in range(RunData.get_player_count()):
		#if RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
			# 上面这句无需检查，因为有可能无面拿了孟婆，然后记忆了面具之后把孟婆替换掉了，且下面函数内部有判空机制
			RunData.foxlab_forget_item(player_index)
	._on_ConfirmButton_pressed()
