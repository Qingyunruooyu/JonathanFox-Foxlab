extends "res://items/characters/character_data.gd"

func _get_tracking_text(player_index: int) -> String:
	if RunData.init_tracked_items.get(my_id_hash) is Array:
		return Utils.foxlab_get_tracking_text(my_id_hash, tracking_text, player_index)
	return ._get_tracking_text(player_index)

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	for i in serialized.item_appearances.size():
			var slz_data = serialized.item_appearances[i]
			if "foxlab_hide_potato" in slz_data:
				var deserialized = load("res://mods-unpacked/JonathanFox-FoxLab/contents/items/global/item_appearance_data.gd").new()
				deserialized.deserialize_and_merge(slz_data)
				item_appearances[i] = deserialized
