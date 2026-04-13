extends "res://items/global/effect.gd"

export(Array, String)  var stats_swapped = ["stat_max_hp", "stat_max_hp"]

var stats_swapped_hash = []

static func get_id() -> String:
	return "foxlab_swap_stat"

func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)
	if stats_swapped_hash.empty() and not stats_swapped.empty():
		stats_swapped_hash = Utils.convert_to_hash_array(stats_swapped)
	duplication.stats_swapped_hash = self.stats_swapped_hash
	return duplication

func _generate_hashes() -> void:
	._generate_hashes()
	stats_swapped_hash = Utils.convert_to_hash_array(stats_swapped)

func apply(player_index: int) -> void:
	var left_stat_key = stats_swapped_hash[0]
	var right_stat_key = stats_swapped_hash[1]

	var left_stat_gain = RunData.get_stat_gain(left_stat_key, player_index)
	if left_stat_gain == 0:
		return
	var right_stat_gain = RunData.get_stat_gain(right_stat_key, player_index)
	if right_stat_gain == 0:
		return

	var effects = RunData.get_player_effects(player_index)
	var left_stat_temp = TempStats.get_stat(left_stat_key, player_index)
	var right_stat_temp = TempStats.get_stat(right_stat_key, player_index)
	var left_stat_linked = LinkedStats.get_stat(left_stat_key, player_index)
	var right_stat_linked = LinkedStats.get_stat(right_stat_key, player_index)

	var left_stat_value = Utils.get_stat(left_stat_key, player_index)
	var right_stat_value = Utils.get_stat(right_stat_key, player_index)

	var new_left_permanent = (right_stat_value - left_stat_temp - left_stat_linked) / left_stat_gain
	var new_right_permanent = (left_stat_value - right_stat_temp - right_stat_linked) / right_stat_gain

	effects[left_stat_key] = new_left_permanent
	effects[right_stat_key] = new_right_permanent
	Utils.reset_stat_cache(player_index)

func unapply(_player_index: int) -> void:
	pass

func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.stats_swapped = stats_swapped

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	stats_swapped = serialized.stats_swapped if "stats_swapped" in serialized else []
	stats_swapped_hash = Utils.convert_to_hash_array(stats_swapped)
