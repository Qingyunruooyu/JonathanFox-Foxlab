class_name FoxLabRawKeyEffect
extends "res://effects/items/double_key_value_effect.gd"

static func get_id() -> String:
	return "foxlab_effect_raw_key"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effect(custom_key_hash, player_index)
	for existing_effect in effects:
		if existing_effect[0] == key and existing_effect[2] == key2_hash and existing_effect[3] == value2:
			existing_effect[1] += value
			return
	effects.push_back([key, value, key2_hash, value2])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effect(custom_key_hash, player_index)
	for i in effects.size():
		var existing_effect = effects[i]
		if existing_effect[0] == key and existing_effect[2] == key2_hash and existing_effect[3] == value2:
			existing_effect[1] -= value
			if existing_effect[1] == 0:
				effects.remove(i)
			return


