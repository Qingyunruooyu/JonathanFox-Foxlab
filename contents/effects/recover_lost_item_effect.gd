extends "res://effects/items/double_value_effect.gd"

static func get_id() -> String:
	return "foxlab_recover_lost_item"

func get_text(player_index: int, colored: bool = true) -> String:
	var text = .get_text(player_index, colored)
	var names: Array = []
	for item_hash in Utils.foxlab_recover_item_blacklist:
		names.append("[color=#%s]%s[/color]" % [ProgressData.settings.color_negative, tr(Keys.hash_to_string[item_hash].to_upper())])
	if names.empty():
		return text
	return text + "\n" + Text.text(tr("FOXLAB_WONT_RECOVER"), [", ".join(names)])
