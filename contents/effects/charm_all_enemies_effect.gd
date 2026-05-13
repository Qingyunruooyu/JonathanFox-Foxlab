extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_charm_all"

func apply(player_index: int) -> void:
	.apply(player_index)
	var items_got:Dictionary = RunData.get_player_effect(Utils.foxlab_charm_all_items_hash, player_index)
	if not key_hash in items_got:
		items_got[key_hash] = 0

func get_args(player_index: int) -> Array:
	var stat_hsh = Keys.stat_max_hp_hash
	var stat_value = Utils.get_capped_stat(stat_hsh, player_index) as int
	var items_got:Dictionary = RunData.get_player_effect(Utils.foxlab_charm_all_items_hash, player_index)
	# 初始的概率100%，每通过此法拿到一个，概率多除以1
	var chance = stepify(100.0 / (1.0 + items_got.get_or_add(key_hash, 0)), 1.0)
	return [str(value), tr(key.to_upper()), str(stat_value), tr("STAT_MAX_HP"), str(chance)]
