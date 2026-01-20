class_name FoxLabAlterAppendEffect
extends "res://effects/items/double_key_value_effect.gd"


static func get_id() -> String:
	return "foxlab_effect_alter_append"


func apply(player_index: int) -> void:
	var effects :Array= RunData.get_player_effect(custom_key, player_index)
	var applied : = [false, false]
	var key_index = 0 # 0表示key，1表示key2
	for existing_item in effects:
		if existing_item[0] == key:
			if not applied[0]:
				existing_item[1] += value
				applied[0] = true
			key_index = 0
		if existing_item[0] == key2:
			if not applied[1]:
				existing_item[1] += value2
				applied[1] = true
			key_index = 1
	if not applied[0]:
		effects.append([key, value])
		key_index = 0
	if not applied[1]:
		effects.append([key2, value2])
		key_index = 1

	# 这两个在upapply的时候不会擦除
	effects.append([key if key_index else key2, 0]) #最后一个元素是key，先append key2；反之亦然
	effects.append([key2 if key_index else key, 0]) #append另一个

func unapply(player_index: int) -> void:
	var effect_items: Array =  RunData.get_player_effect(custom_key, player_index)
	var applied : = [false, false]
	var item_to_remove = []
	for i in effect_items.size():
		var effect_item = effect_items[i]
		if not applied[0] and effect_item[0] == key:
			effect_item[1] -= value
			if effect_item[1] == 0:
				item_to_remove.push_front(i)
			applied[0] = true
		elif not applied[1] and effect_item[0] == key2:
			effect_item[1] -= value2
			if effect_item[1] == 0:
				item_to_remove.push_front(i)
			applied[1] = true
		if applied[0] and applied[1]:
			break
	for rm_idx in item_to_remove:
		effect_items.remove(rm_idx)
