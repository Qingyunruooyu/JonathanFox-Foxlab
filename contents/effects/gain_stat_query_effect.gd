extends "res://effects/weapons/null_effect.gd"

static func get_id() -> String:
	return "foxlab_gain_stat_query"

func get_text(player_index: int, _colored: bool = true) -> String:
	var text:String = tr("EFFECT_FOXLAB_GAIN_STAT_QUERY")
	for stat_gain in Utils.foxlab_primary_stat_gain_map.keys():
		var gain_value = RunData.get_player_effect(stat_gain, player_index)
		if gain_value == 0:
			continue
		var stat = Utils.foxlab_primary_stat_gain_map[stat_gain]
		var value_str = str(gain_value) + "%"
		if gain_value > 0:
			value_str = "+" + value_str
		text += "\n" + Text.text(tr("EFFECT_FOXLAB_STAT_QUERY"), [value_str,
				Utils.foxlab_get_colored_stat_str(stat)],
				[Sign.NEGATIVE if gain_value < 0 else Sign.POSITIVE, Sign.NEUTRAL])
	return text
