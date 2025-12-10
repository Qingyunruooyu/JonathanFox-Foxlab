extends CharacterData

var item_data = preload("res://mods-unpacked/JonathanFox-FoxLab/contents/items/all/item_data.gd")

func _get_tracking_text(player_index: int) -> String:
	if not my_id in item_data.MOD_ITEMS:
		return ._get_tracking_text(player_index)
	return item_data.foxlab_get_tracking_text(my_id, tracking_text, player_index)
