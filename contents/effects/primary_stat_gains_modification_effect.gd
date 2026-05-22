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
	if not stats_exception.empty():
		var exceptions = []
		for stat in stats_exception:
			if stat == "stat_curse":
				exceptions.append("[color=#%s]%s[/color]" % [Utils.CURSE_COLOR.to_html(), tr("STAT_CURSE")])
			else:
				exceptions.append(tr(stat.to_upper()))
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
