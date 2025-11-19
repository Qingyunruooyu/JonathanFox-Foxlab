class_name FoxLabStatQueryEffect
extends NullEffect

static func get_id() -> String:
	return "foxlab_effect_stat_query"

func get_args(_player_index: int) -> Array:
	match value:
		0: # 一般的
			return [str(Utils.get_stat(key, _player_index)), tr(key.to_upper())]
		1: # 永久的
			return [str(RunData.get_stat(key, _player_index)), tr(key.to_upper())]
		2: # 布尔
			return [tr("FOXLAB_ENABLE") if RunData.get_player_effect_bool(key, _player_index) \
					else tr("FOXLAB_DISABLE"), tr(key.to_upper())]
		_: 
			return []
	
