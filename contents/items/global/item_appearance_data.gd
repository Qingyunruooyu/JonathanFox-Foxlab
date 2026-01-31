extends "res://items/global/item_appearance_data.gd"

export(bool) var foxlab_hide_potato = false

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.foxlab_hide_potato = foxlab_hide_potato
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	foxlab_hide_potato = serialized.foxlab_hide_potato if serialized.has("foxlab_hide_potato") else false
