extends "res://items/global/effect.gd"

var is_item_added := false

static func get_id() -> String:
	return "foxlab_get_item"

func apply(player_index: int) -> void:
	var item_to_add  = null
	if key_hash in Keys.item_builder_turret_n_hash:
		var struct_range = RunData.get_player_effect(Keys.structure_range_hash, player_index)
		var new_level = BuilderTurret.get_level(struct_range)
		item_to_add = ItemService.foxlab_get_builder_turret_at_level(new_level, player_index)
	else:
		item_to_add = ItemService.get_element(ItemService.items, key_hash)
	if item_to_add != null:
		for _i in range(value):
			RunData.add_item(item_to_add, player_index)
			is_item_added = true
		RunData.emit_signal("foxlab_item_added", item_to_add, value, player_index)
		RunData.emit_signal("foxlab_item_gear_changed", player_index)

func _remove_item(player_index: int, item_id_hash: int, rm_count: int) -> int :
	if rm_count < value and RunData.get_nb_item(item_id_hash, player_index) > 0:
		var items_ref = RunData.get_player_items_ref(player_index)
		for i in range(items_ref.size() - 1, -1, -1):
			var item = items_ref[i]
			if item_id_hash == item.my_id_hash and item.curse_factor == 0.0:
				RunData.foxlab_remove_item_by_index(i, player_index)
				rm_count = rm_count + 1
				if not (rm_count < value and RunData.get_nb_item(item_id_hash, player_index) > 0):
					break
	return rm_count

func unapply(player_index: int) -> void:
	if not is_item_added:
		return
	call_deferred("deferred_unapply", player_index)

func deferred_unapply(player_index) -> void:
	if key_hash in Keys.item_builder_turret_n_hash:
		var rm_count = 0
		for i in range(4):
			var item_id_hash = Keys.item_builder_turret_n_hash[i]
			rm_count = _remove_item(player_index, item_id_hash, rm_count)
			if rm_count >= value:
				return
	else:
		_remove_item(player_index, key_hash, 0)

	RunData.emit_signal("foxlab_item_gear_changed", player_index)

func serialize() -> Dictionary:
	var serialized =.serialize()
	serialized.is_item_added = is_item_added
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	is_item_added = serialized.is_item_added if "is_item_added" in serialized else false
