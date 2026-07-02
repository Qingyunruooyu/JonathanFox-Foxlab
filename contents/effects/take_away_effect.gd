extends "res://effects/items/double_value_effect.gd"

static func get_id() -> String:
	return "foxlab_take_away"

func apply(_player_index: int) -> void:
	pass

func unapply(player_index: int) -> void:
	call_deferred("deferred_unapply", player_index)

func deferred_unapply(player_index) -> void:
	var player_items_raw:Array = RunData.get_player_items_ref(player_index)
	 #要移除的往往是新获得的物品
	var count = 0
	for index in range(player_items_raw.size() - 1, -1, -1):
		if count >= value:
			break
		var item_data = player_items_raw[index]
		if item_data.my_id_hash == key_hash and item_data.is_cursed == (value2 != 0):
			#DebugService.log_data("take away " + item_data.my_id)
			RunData.foxlab_remove_item_by_index(index, player_index)
			count += 1

