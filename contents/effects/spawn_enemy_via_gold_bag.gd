extends "res://items/global/effect.gd"

export var charmed: bool = false
export var max_proc: int = -1

static func get_id() -> String:
	return "foxlab_spawn_enemy_via_gold_bag"

# key为"boss"或"looting_enemies"，value为每次召唤消耗的材料袋材料数
# charmed为召唤的敌人是否魅惑，max_proc为每波最多转换次数（负数不限制，消耗到材料袋空为止）
# 条目格式：[key_hash, value, charmed, max_proc]
func apply(player_index: int) -> void:
	RunData.get_player_effect(custom_key_hash, player_index).append([key_hash, value, charmed, max_proc])


func unapply(player_index: int) -> void:
	RunData.get_player_effect(custom_key_hash, player_index).erase([key_hash, value, charmed, max_proc])


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized["charmed"] = charmed
	serialized["max_proc"] = str(max_proc)

	return serialized


func deserialize_and_merge(effect: Dictionary) -> void:
	.deserialize_and_merge(effect)

	charmed = effect.get("charmed", false)
	max_proc = effect.get("max_proc", -1) as int


func get_args(_player_index: int) -> Array:
	var type_name: String = tr(key.to_upper())
	if charmed:
		type_name += Text.text("FOXLAB_CHARMED_HINT")
	if max_proc >= 0:
		type_name += Text.text("FOXLAB_MAX_PROC_HINT", [str(max_proc)])
	return [str(value), type_name]
