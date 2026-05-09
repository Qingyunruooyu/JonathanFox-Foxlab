extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_odd_eyes"

func apply_effects_core(player_index: int, apply: bool):
	var level_up_map = Utils.foxlab_get_primary_stat_level_up_map()[0]
	var stats_in_panel = Utils.foxlab_get_stats_in_container()[0]
	var effect = DoubleKeyValueEffect.new()
	effect.custom_key_hash = Keys.gain_stat_for_equipped_item_with_stat_hash
	effect.storage_method = StorageMethod.KEY_VALUE
	for i in range(0, stats_in_panel.size() - 1):
		# 道具直接提升的属性
		effect.key2_hash = stats_in_panel[i]
		# 要减少的下一行的属性
		effect.key_hash = stats_in_panel[i+1]
		effect.value = -level_up_map[effect.key_hash]
		if apply:
			effect.apply(player_index)
		else:
			effect.unapply(player_index)
	for i in range(1, stats_in_panel.size()):
		# 道具直接提升的属性
		effect.key2_hash = stats_in_panel[i]
		# 要增加的上一行的属性
		effect.key_hash = stats_in_panel[i-1]
		effect.value = level_up_map[effect.key_hash]
		if apply:
			effect.apply(player_index)
		else:
			effect.unapply(player_index)


func apply(player_index: int) -> void:
	apply_effects_core(player_index, true)

func unapply(player_index: int) -> void:
	apply_effects_core(player_index, false)


