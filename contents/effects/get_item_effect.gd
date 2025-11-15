class_name FoxLabGetItemEffect
extends Effect

var is_item_added := false

static func get_id() -> String:
	return "foxlab_effect_get_item"

func apply(player_index: int) -> void:
	var item_to_add  = null
	if key.begins_with("item_builder_turret"):
		var struct_range = RunData.get_player_effect("structure_range", player_index)
		var new_level = BuilderTurret.get_level(struct_range)
		item_to_add = ItemService.foxlab_get_builder_turret_at_level(new_level, player_index)
	else:
		item_to_add = ItemService.get_element(ItemService.items, key)
	if item_to_add != null:
		for i in range(value):
			RunData.add_item(item_to_add, player_index)
			is_item_added = true

func _remove_item(player_index: int, item_id: String, rm_count: int) -> int :
	if RunData.get_nb_item(item_id, player_index) > 0:
		var item_to_rm =  ItemService.get_element(ItemService.items, item_id)
		while rm_count < value and RunData.get_nb_item(item_id, player_index) > 0:
			RunData.remove_item(item_to_rm, player_index)
			rm_count = rm_count + 1
	return rm_count

func unapply(player_index: int) -> void:
	if not is_item_added:
		return

	if key.begins_with("item_builder_turret"):
		var rm_count = 0
		for i in range(4):
			var item_id = "item_builder_turret_" + str(i)
			rm_count = _remove_item(player_index, item_id, rm_count)
			if rm_count >= value:
				return
	else:
		_remove_item(player_index, key, 0)

func serialize() -> Dictionary:
	var serialized =.serialize()
	serialized.is_item_added = is_item_added
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	is_item_added = serialized.is_item_added if "is_item_added" in serialized else false
