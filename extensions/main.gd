extends "res://main.gd"


func on_levelled_up(player_index: int) -> void :
	.on_levelled_up(player_index)
	var effects = RunData.get_player_effects(player_index)
	effects["stat_levels"] = RunData.get_player_level(player_index)

func _ready():
	for player_index in _players.size():
		var player = _players[player_index]

		var need_reset_player: bool = false
		# value, foxlab_receive_item_id, foxlab_receive_item_wave, curse_factor, is_cursed, end_wave
		var receive_item_effects: Array = RunData.get_player_effect("foxlab_effect_receive_item_at_wave", player_index)
		if not receive_item_effects.empty():
			# Cache
			var _item = ItemService.get_item_from_id("item_acid")

			var remove_array: Array = []
			for receive_item_effect in receive_item_effects:
				if receive_item_effect[2] <= RunData.current_wave:
					var end_wave = -1
					if receive_item_effect.size() > 5:
						end_wave = receive_item_effect[5]
					if end_wave <= 0:
						remove_array.push_back(receive_item_effect)
					elif end_wave < RunData.current_wave:
						remove_array.push_back(receive_item_effect)
						continue

					var item_data = ItemService.get_element(ItemService.items, receive_item_effect[1])
					if not item_data == null:
						var is_cursed: bool = receive_item_effect[4]
						var dlc = null
						var actual_item_data = item_data

						if is_cursed:
							dlc = ProgressData.get_dlc_data("abyssal_terrors")

						for i in receive_item_effect[0]:
							if dlc:
								actual_item_data = dlc.curse_item(item_data, player_index, false)
							if actual_item_data.my_id == "item_axolotl":
								for effect in actual_item_data.effects:
									if effect is SwapMaxMinStatEffect:
										effect.stats_swapped = effect._find_min_max_stat_keys(player_index)
							RunData.add_item(actual_item_data, player_index)

						_floating_text_manager.display_icon(receive_item_effect[0], item_data.icon, _floating_text_manager.stat_pos_sounds, _floating_text_manager.stat_neg_sounds, player.global_position - Vector2(0, 50), _floating_text_manager.direction, -10.0)

						need_reset_player = true

			for remove_entry in remove_array:
				receive_item_effects.erase(remove_entry)

		# [key, value, starting_wave, end_wave]
		var stats_end_of_wave_after_wave: Array = RunData.get_player_effect("foxlab_stats_end_of_wave_after_wave", player_index)
		if not stats_end_of_wave_after_wave.empty():
			var remove_array: = []
			for j in stats_end_of_wave_after_wave.size():
				var eff = stats_end_of_wave_after_wave[j]
				if RunData.current_wave == int(eff[2]):
					var effect_items: Array = RunData.get_player_effect("stats_end_of_wave", player_index)
					var has_effect: bool = false
					for existing_item in effect_items:
						if existing_item[0] == eff[0]:
							existing_item[1] += int(eff[1])
							has_effect = true
							break
					if not has_effect:
						effect_items.append([eff[0], int(eff[1])])
				if RunData.current_wave == (int(eff[3]) + 1):
					var effect_items: Array = RunData.get_player_effect("stats_end_of_wave", player_index)
					for i in effect_items.size():
						var effect_item = effect_items[i]
						if effect_item[0] == eff[0]:
							effect_item[1] -= eff[1]
							if effect_item[1] == 0:
								effect_items.remove(i)
							break

					remove_array.push_back(eff)
			for j in remove_array:
				stats_end_of_wave_after_wave.erase(j)

		if need_reset_player:
			player.update_player_stats(true)

func _on_HalfWaveTimer_timeout() -> void :
	._on_HalfWaveTimer_timeout()

	for i in range(RunData.get_player_count()):
		if not RunData.get_player_effect("foxlab_multiply_stats_half_wave", i).empty():
			_wave_timer_label.change_color(Utils.CURSE_COLOR)
			for j in range(RunData.get_player_count()):
				_floating_text_manager.display("FOXLAB_MIDNIGHT",
							 _floating_text_manager.players[j].global_position, Utils.CURSE_COLOR)
			break

	EntityService.reset_cache()
