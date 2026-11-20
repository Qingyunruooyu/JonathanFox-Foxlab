extends "res://items/global/effect.gd"

export(Array, String) var required_item_set = []


static func get_id() -> String:
	return "foxlab_dlc_depend"


func get_text(player_index: int, colored: bool = true) -> String:
	for item_set in required_item_set:
		if not item_set in ProgressData.active_update_data:
			return ""
	return .get_text(player_index, colored)


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.required_item_set = required_item_set.duplicate()
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	required_item_set = serialized.required_item_set.duplicate() if "required_item_set" in serialized else []
