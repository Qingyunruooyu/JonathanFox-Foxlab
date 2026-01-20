class_name FoxLabConvertStatEffect
extends "res://effects/items/convert_stat_effect.gd"

static func get_id() -> String:
	return "foxlab_effect_convert_stat"

# 中途关闭游戏重开后, unapply失效的问题
func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)[custom_key]
	var num =  effects.size()
	.unapply(player_index)
	var num_after =  effects.size()
	if num_after < num:
		return
	for effect in effects:
		if effect.get_id() == get_id() and effect.get_args(player_index) == get_args(player_index):
			effects.erase(effect)
			return

