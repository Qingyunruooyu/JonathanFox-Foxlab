class_name FoxLabStatQueryEffect
extends "res://effects/weapons/null_effect.gd"

static func get_id() -> String:
	return "foxlab_effect_stat_query"

func get_args(_player_index: int) -> Array:
	match value:
		0: # 一般的
			return [str(stepify(Utils.get_stat(key_hash, _player_index), 0.1)), tr(key.to_upper())]
		1: # 永久的
			return [str(stepify(RunData.get_stat(key_hash, _player_index), 0.1)), tr("EFFECT_FOXLAB_PERMANENT") + tr(key.to_upper())]
		2: # 效果而非属性，布尔
			return [tr("FOXLAB_ENABLE") if RunData.get_player_effect_bool(key_hash, _player_index) \
					else tr("FOXLAB_DISABLE"), tr(key.to_upper())]
		3: # 效果而非属性
			return [str(RunData.get_player_effect(key_hash, _player_index)), tr(key.to_upper())]
		4: # 效果而非属性，负数置为0
			return [str(max(0, RunData.get_player_effect(key_hash, _player_index))), tr(key.to_upper())]
		5: # 效果而非属性，反向布尔，排险者的异变
			var state_crisis = ""
			if RunData.get_player_effect(key_hash, _player_index) < 0:
				state_crisis = "[color=#%s]%s[/color]" % [ProgressData.settings.color_positive, tr("FOXLAB_ENABLE")]
			else:
				state_crisis = "[color=#%s]%s[/color]" % [ProgressData.settings.color_negative, tr("FOXLAB_DISABLE")]
			return [state_crisis]
		6: # key-value类型的数值，如百鬼夜行
			var effects = RunData.get_player_effects(_player_index)
			var stat_value = 0.0
			var effect_items: Array = effects[custom_key_hash]
			for existing_item in effect_items:
				if existing_item[0] == key_hash:
					stat_value  = existing_item[1]
					break
			return [str(stepify(stat_value, 0.001)), tr(key.to_upper())]
		7: #股民的购买力
			var gain_stat_max_hp = RunData.get_player_effect(Keys.gain_stat_max_hp_hash, _player_index)
			if gain_stat_max_hp <= -100:
				return [tr("FOXLAB_DISABLE"), tr("EFFECT_FOXLAB_PURCHASING_POWER")]
			return [ str(stepify(1 / ((100 + gain_stat_max_hp) / 100.0), 0.01) * 100) + "%", tr("EFFECT_FOXLAB_PURCHASING_POWER")]
		8: #下波临时属性
			var val = 0
			for effect in RunData.get_player_effect(Keys.stats_next_wave_hash, _player_index):
				if effect[0] == key_hash:
					val += effect[1]
			return [str(val), tr("EFFECT_FOXLAB_NEXT_WAVE") + tr(key.to_upper())]
		9: #字符串数组
			var items: Array = RunData.get_player_effect(key_hash, _player_index)
			return [tr("FOXLAB_DISABLE") if items.empty() else ", ".join(items), tr(key.to_upper())]
		10: #无面是否能复制武器
			var upgrade_wave =  RunData.get_player_effect(Utils.fox_faceless_upgrade_on_transform_wave_hash, _player_index)
			var txt = ""
			if upgrade_wave == RunData.current_wave:
				txt =  "[color=#%s]%s[/color]" % [ProgressData.settings.color_negative, tr("EFFECT_FOXLAB_FACELESS_DISABLE")]
			else:
				txt =  "[color=#%s]%s[/color]" % [ProgressData.settings.color_positive, tr("EFFECT_FOXLAB_FACELESS_ENABLE")]
			return [txt]
		_:
			return []

