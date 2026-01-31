extends "res://items/characters/character_data.gd"

func _get_tracking_text(player_index: int) -> String:
	if not my_id_hash in Utils.foxlab_multi_tracking_items:
		return ._get_tracking_text(player_index)
	return Utils.foxlab_get_tracking_text(my_id_hash, tracking_text, player_index)
