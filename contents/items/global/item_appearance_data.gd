extends ItemAppearanceData

export(bool) var hide_vanilla_potato = false



func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.hide_vanilla_potato = hide_vanilla_potato
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	hide_vanilla_potato = serialized.hide_vanilla_potato if serialized.has("hide_vanilla_potato") else false
