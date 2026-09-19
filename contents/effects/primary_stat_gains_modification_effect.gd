extends "res://items/global/effect.gd"

export(Array, String) var stats_exception
export(String) var stat_displayed = ""

static func get_id() -> String:
	return "foxlab_stat_gain_mod"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	var stats_exception_hash = Utils.convert_to_hash_array(stats_exception)
	for stat_gain in Utils.foxlab_primary_stat_gain_map:
		if not Utils.foxlab_primary_stat_gain_map[stat_gain] in stats_exception_hash:
			effects[stat_gain] += value


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	var stats_exception_hash = Utils.convert_to_hash_array(stats_exception)
	for stat_gain in Utils.foxlab_primary_stat_gain_map:
		if not Utils.foxlab_primary_stat_gain_map[stat_gain] in stats_exception_hash:
			effects[stat_gain] -= value

func get_args(_player_index: int) -> Array:
	var display_text = tr(stat_displayed.to_upper())
	var exceptions = []
	for stat in Utils._primary_stat_keys:
		var stat_str = Keys.hash_to_string[stat]
		var gain_stat = "gain_" + stat_str
		var gain_stat_hash = Keys.generate_hash(gain_stat)
		if stat_str in stats_exception or not gain_stat_hash in Utils.foxlab_primary_stat_gain_map:
			exceptions.append(Utils.foxlab_get_colored_stat_str(stat))
	if not exceptions.empty():
		display_text += Text.text(tr("FOXLAB_EXCEPT"), ["/".join(exceptions)], [get_sign(effect_sign, value)])
	return [display_text, str(abs(value))]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.stats_exception = stats_exception
	serialized.stat_displayed = stat_displayed
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	stats_exception = serialized.stats_exception
	stat_displayed = serialized.stat_displayed
