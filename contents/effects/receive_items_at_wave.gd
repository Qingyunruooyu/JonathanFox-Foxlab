extends "res://effects/items/double_value_effect.gd"

static func get_id() -> String:
	return "foxlab_receive_item_at_wave"

# key为获得的道具id，value为个数，value2为诅咒标记（>0必诅咒，==0不诅咒，<0按apply_item_effect_modifications结果）
# custom_key决定获得时机：foxlab_effect_receive_item_at_wave 敌袭开始时；foxlab_effect_receive_item_at_wave_end 敌袭结束后
# storage_method须为KEY_VALUE，条目格式：[道具key, 个数, 诅咒标记]
func get_args(_player_index: int) -> Array:
	var item_name: String = tr(key.to_upper())
	if value2 > 0:
		item_name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
	return [str(value), item_name]