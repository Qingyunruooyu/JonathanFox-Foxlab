class_name FoxLabGainStatQueryEffect
extends "res://effects/weapons/null_effect.gd"

static func get_id() -> String:
	return "foxlab_effect_gain_stat_query"

func get_text(player_index: int, colored: bool = true) -> String:
	var text:String = tr("EFFECT_FOXLAB_GAIN_STAT_QUERY")
	for stat in Utils.get_primary_stat_keys():
		var stat_str = Keys.hash_to_string[stat]
		var stat_gain = Keys.generate_hash("gain_" + stat_str)
		var gain_value = RunData.get_player_effect(stat_gain, player_index)
		if gain_value == 0:
			continue
		var value_str = str(gain_value) + "%"
		if gain_value > 0:
			value_str = "+" + value_str
		if stat == Keys.stat_curse_hash:
			text += "\n" + Text.text(tr("EFFECT_FOXLAB_STAT_QUERY"), [value_str,
				"[color=#%s]%s[/color]" % [Utils.CURSE_COLOR.to_html(), tr(stat_str.to_upper())]],
				 [Sign.OVERRIDE, Sign.NEUTRAL])
		else:
			text += "\n" + Text.text(tr("EFFECT_FOXLAB_STAT_QUERY"), [value_str,
				 str(tr(stat_str.to_upper()))],
				 [Sign.NEGATIVE if gain_value < 0 else Sign.POSITIVE, Sign.NEUTRAL])
	return text
