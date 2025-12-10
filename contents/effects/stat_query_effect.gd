class_name FoxLabStatQueryEffect
extends NullEffect

static func get_id() -> String:
	return "foxlab_effect_stat_query"

func get_args(_player_index: int) -> Array:
	match value:
		0: # 一般的
			return [str(stepify(Utils.get_stat(key, _player_index), 0.1)), tr(key.to_upper())]
		1: # 永久的
			return [str(stepify(RunData.get_stat(key, _player_index), 0.1)), tr("EFFECT_FOXLAB_PERMANENT") + tr(key.to_upper())]
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
		6: # key-value类型的数值，如百鬼夜行
			var effects = RunData.get_player_effects(_player_index)
			var stat_value = 0.0
			var effect_items: Array = effects[custom_key]
			for existing_item in effect_items:
				if existing_item[0] == key:
					stat_value  = existing_item[1]
					break
			return [str(stepify(stat_value, 0.001)), tr(key.to_upper())]
		7: #股民的购买力
			var gain_stat_max_hp = RunData.get_player_effect("gain_stat_max_hp", _player_index)
			if gain_stat_max_hp <= -100:
				return [tr("FOXLAB_DISABLE"), tr("EFFECT_FOXLAB_PURCHASING_POWER")]
			return [ str(stepify(1 / ((100 + gain_stat_max_hp) / 100.0), 0.01) * 100) + "%", tr("EFFECT_FOXLAB_PURCHASING_POWER")]
		8: #下波临时属性
			var val = 0
			for effect in RunData.get_player_effect("stats_next_wave", _player_index):
				if effect[0] == key:
					val += effect[1]
			return [str(val), tr("EFFECT_FOXLAB_NEXT_WAVE") + tr(key.to_upper())]
		_:
			return []

