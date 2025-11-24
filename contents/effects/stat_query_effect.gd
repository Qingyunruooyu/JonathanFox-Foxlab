class_name FoxLabStatQueryEffect
extends NullEffect

static func get_id() -> String:
	return "foxlab_effect_stat_query"

func get_args(_player_index: int) -> Array:
	match value:
		0: # 一般的
			return [str(Utils.get_stat(key, _player_index)), tr(key.to_upper())]
		1: # 永久的
			return [str(RunData.get_stat(key, _player_index)), tr("EFFECT_FOXLAB_PERMANENT") + tr(key.to_upper())]
		2: # 效果而非属性，布尔
			return [tr("FOXLAB_ENABLE") if RunData.get_player_effect_bool(key, _player_index) \
					else tr("FOXLAB_DISABLE"), tr(key.to_upper())]
		3: # 效果而非属性
			return [str(RunData.get_player_effect(key, _player_index)), tr(key.to_upper())]
		4: # 效果而非属性，负数置为0
			return [str(max(0, RunData.get_player_effect(key, _player_index))), tr(key.to_upper())]
		5: # 效果而非属性，反向布尔，排险者的异变
			var state_crisis = ""
			if RunData.get_player_effect(key, _player_index) < 0:
				var pos_color = ("#" + ProgressData.settings.color_positive) if ProgressData.settings.has("color_positive") else Utils.POS_COLOR_STR
				state_crisis = "[color=%s]%s[/color]" % [pos_color, tr("FOXLAB_ENABLE")]
			else:
				var neg_color = ("#" + ProgressData.settings.color_negative) if ProgressData.settings.has("color_negative") else Utils.NEG_COLOR_STR
				state_crisis = "[color=%s]%s[/color]" % [neg_color, tr("FOXLAB_DISABLE")]
			return [state_crisis]
		_:
			return []

