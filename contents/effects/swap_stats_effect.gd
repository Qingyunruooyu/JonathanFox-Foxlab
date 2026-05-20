extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_swap_stats"

func apply(player_index: int) -> void:
	var stats_in_container = Utils.foxlab_get_stats_in_container()
	var effects = RunData.get_player_effects(player_index)
	for stats in stats_in_container:
		var stats_to_swap = []
		for stat in stats:
			var effect_hash = Keys.generate_hash("gain_" + Keys.hash_to_string[stat])
			# 跳过修改减少100%的属性
			if effects.has(effect_hash) and effects[effect_hash] == -100:
				continue
			stats_to_swap.append(stat)
		var range_seq = null
		if value >= 0:
			range_seq = range(0, stats_to_swap.size() - 1)
		else:
			range_seq = range(stats_to_swap.size() - 2, -1, -1)
		for i in range_seq:
			swap_stat(stats_to_swap[i], stats_to_swap[i+1], player_index)

static func get_stat_value(stat_key: int, player_index: int):
	return WeaponService.get_structure_attack_speed(player_index) if stat_key == Keys.structure_attack_speed_hash else Utils.get_stat(stat_key, player_index)

static func swap_stat(left_stat_key: int, right_stat_key: int, player_index: int):
	var left_stat_gain = RunData.get_stat_gain(left_stat_key, player_index)
	var right_stat_gain = RunData.get_stat_gain(right_stat_key, player_index)
	# print("swap ", Keys.hash_to_string[left_stat_key], ", ", Keys.hash_to_string[right_stat_key])
	var effects = RunData.get_player_effects(player_index)

	# RunData + TempStats + (LinkedStats (+ structures_cooldown_reduction)) = stat value
	var left_stat_value = get_stat_value(left_stat_key, player_index)
	var right_stat_value = get_stat_value(right_stat_key, player_index)
	var left_stat_temp = TempStats.get_stat(left_stat_key, player_index)
	var right_stat_temp = TempStats.get_stat(right_stat_key, player_index)
	var left_stat_linked = left_stat_value - left_stat_temp - RunData.get_stat(left_stat_key, player_index)
	var right_stat_linked = right_stat_value - right_stat_temp - RunData.get_stat(right_stat_key, player_index)

	var new_left_permanent = (right_stat_value - left_stat_temp - left_stat_linked) / left_stat_gain
	var new_right_permanent = (left_stat_value - right_stat_temp - right_stat_linked) / right_stat_gain

	effects[left_stat_key] = new_left_permanent
	effects[right_stat_key] = new_right_permanent
	Utils.reset_stat_cache(player_index)

func unapply(_player_index: int) -> void:
	pass

func get_text(player_index: int, _colored: bool = true) -> String:
	var text:String = tr(text_key.to_upper())
	var zero_stat = []
	var stats_in_container = Utils.foxlab_get_stats_in_container()
	var effects = RunData.get_player_effects(player_index)
	for stats in stats_in_container:
		for stat in stats:
			var effect_hash = Keys.generate_hash("gain_" + Keys.hash_to_string[stat])
			# 跳过修改减少100%的属性
			if effects.has(effect_hash) and effects[effect_hash] == -100:
				if zero_stat.empty():
					zero_stat.append(text)
					zero_stat.append(tr("EFFECT_FOXLAB_STAT_IGNORE_IN_SWAP"))
				var stat_str = Keys.hash_to_string[stat]
				if stat == Keys.stat_curse_hash:
					zero_stat.append("[color=#%s]%s[/color]" % [Utils.CURSE_COLOR.to_html(), tr(stat_str.to_upper())])
				else:
					zero_stat.append(tr(stat_str.to_upper()))
	if zero_stat.empty():
		return text
	return "\n".join(zero_stat)
