extends "res://ui/menus/ingame/upgrades_ui.gd"

func _recheck_extra_items(player_index: int) -> void :
	._recheck_extra_items(player_index)
	var items_to_remove: = []
	# 获得的道具使箱子里额外道具的概率 <=0 的时候，额外道具不再出现
	# 比如面具变身成功，把魔术师换掉之后，本来要掉落的魔术帽不应该再出现了；如果此前面具变身失败、没有换掉魔术师，就正常掉落魔术帽
	for extra_item in _extra_items_to_process[player_index]:
		if extra_item != Keys.random_hash:
			var extra_item_effects: Array = RunData.get_player_effect(Keys.extra_item_in_crate_hash, player_index)
			var is_still_extra: = false
			for effect in extra_item_effects:
				if extra_item == effect[0] and effect[1] > 0:
					is_still_extra = true
			if not is_still_extra:
				items_to_remove.append(extra_item)
	for item_to_remove in items_to_remove:
		_extra_items_to_process[player_index].erase(item_to_remove)

func _check_extra_items_in_crate_effect(player_index: int) -> void :
	var before = _extra_items_to_process[player_index].size()
	._check_extra_items_in_crate_effect(player_index)
	if  _extra_items_to_process[player_index].size() > before:
		_extra_items_to_process[player_index].shuffle()
