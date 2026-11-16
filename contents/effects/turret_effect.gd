extends "res://effects/items/turret_effect.gd"

static func get_id() -> String:
	return "foxlab_turret"

func get_text(player_index: int, colored: bool = true) -> String:
	var texts = []
	var primary_text = .get_text(player_index, colored)
	if primary_text != "":
		texts.append(primary_text)
	for effect in effects:
		var sub_text = effect.get_text(player_index, colored)
		if sub_text != "":
			texts.append(sub_text)
	return "\n".join(texts)
