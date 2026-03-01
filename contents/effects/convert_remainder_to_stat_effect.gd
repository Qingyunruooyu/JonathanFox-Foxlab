class_name FoxLabConvertRemainderToStatEffect
extends "res://effects/items/convert_stat_effect.gd"
# 将key所指示的属性除以value得到的余数，设置为to_stat指示的属性

# key 属性
# key的属性值：被除数
# value 除数
# pct_converted 属性key用于转换计算的比例
export(int) var offset = 1 #余数的偏移
#-1：相应减少， 1：保持不变， 0：清零
export(int) var keep_value = -1 #转换后，原始属性key的值是否相应减少
export(float) var to_stat_scaling = 1.0 #转换为几倍
export(bool) var is_negative_key = false # key指示的stat仅在负数/正数时起效

static func get_id() -> String:
	return "foxlab_effect_convert_remainder"

func get_args(_player_index: int) -> Array:
	return [str(pct_converted), tr(key.to_upper()), tr(to_stat.to_upper()),
	 str(value), str(offset), str(to_stat_scaling)]

func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.offset = offset
	serialized.keep_value = keep_value
	serialized.to_stat_scaling = to_stat_scaling
	serialized.is_negative_key = is_negative_key

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	offset = serialized.offset as int
	keep_value = serialized.keep_value if "keep_value" in serialized else -1
	to_stat_scaling = serialized.to_stat_scaling
	is_negative_key = serialized.is_negative_key

