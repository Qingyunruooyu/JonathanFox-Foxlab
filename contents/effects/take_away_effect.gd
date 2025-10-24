class_name TakeAwayEffect
extends DoubleValueEffect

static func get_id() -> String:
	return "take_away"

func apply(player_index: int) -> void:
	pass

func unapply(player_index: int) -> void:
	var player_items_raw:Array = RunData.players_data[player_index].items
	 #要移除的往往是新获得的物品
	var items_to_remove: = []
	var count = 0
	for index in range(player_items_raw.size(), 0, -1):
		if count == value:
			break
		var item_data: ItemData = player_items_raw[index - 1]
		if item_data.my_id == key and item_data.is_cursed == (value2 != 0):
			items_to_remove.append(item_data)
			count += 1

	for item_data in items_to_remove:
		DebugService.log_data("take away " + item_data.my_id)
		RunData.remove_item(item_data, player_index)

