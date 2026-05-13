extends "res://items/global/item_data.gd"

func _get_tracking_text(player_index: int) -> String:
	if RunData.init_tracked_items.get(my_id_hash) is Array:
		return Utils.foxlab_get_tracking_text(my_id_hash, tracking_text, player_index)
	return ._get_tracking_text(player_index)
