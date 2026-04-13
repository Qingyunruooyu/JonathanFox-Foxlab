extends "res://items/global/effect.gd"


export var foxlab_receive_item_id: String = "item_acid"
export var foxlab_receive_item_wave: int = 5
export var foxlab_receive_item_end_wave: int = -1
export (bool) var foxlab_cursed_item: bool = false

var foxlab_receive_item_id_hash: int = Keys.empty_hash

static func get_id() -> String:
	return "foxlab_receive_item_at_wave"

func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)
	if foxlab_receive_item_id_hash == Keys.empty_hash and foxlab_receive_item_id != "":
		foxlab_receive_item_id_hash = Keys.generate_hash(foxlab_receive_item_id)
	duplication.foxlab_receive_item_id_hash = self.foxlab_receive_item_id_hash
	return duplication

func _generate_hashes() -> void:
	._generate_hashes()
	foxlab_receive_item_id_hash = Keys.generate_hash(foxlab_receive_item_id)

func apply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).append([value, foxlab_receive_item_id_hash, foxlab_receive_item_wave, curse_factor, foxlab_cursed_item, foxlab_receive_item_end_wave])


func unapply(player_index: int) -> void:
	var effect: Array = RunData.get_player_effect(key_hash, player_index)
	var index: int = -1
	for i in effect.size():
		var entry = effect[i]
		if entry[3] == curse_factor and entry[4] == foxlab_cursed_item and entry[5] == foxlab_receive_item_end_wave:
			index = i
			break

	if not index == -1:
		effect.remove(index)


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized["foxlab_receive_item_id"] = foxlab_receive_item_id
	serialized["foxlab_receive_item_wave"] = foxlab_receive_item_wave
	serialized["foxlab_cursed_item"] = foxlab_cursed_item
	serialized["foxlab_receive_item_end_wave"] = foxlab_receive_item_end_wave

	return serialized


func deserialize_and_merge(effect: Dictionary) -> void:
	.deserialize_and_merge(effect)

	foxlab_receive_item_id = effect.get("foxlab_receive_item_id", "item_acid")
	foxlab_receive_item_id_hash = Keys.generate_hash(foxlab_receive_item_id)
	foxlab_receive_item_wave = effect.get("foxlab_receive_item_wave", 5)
	foxlab_cursed_item = effect.get("foxlab_cursed_item", false)
	foxlab_receive_item_end_wave = effect.get("foxlab_receive_item_end_wave", -1)


func get_args(_player_index: int) -> Array:
	var item_data = ItemService.get_element(ItemService.items, foxlab_receive_item_id_hash)

	var item_name: String = ""
	if not item_data == null:
		item_name = tr(item_data.name)
	else:
		item_name = foxlab_receive_item_id.to_upper()
	if foxlab_cursed_item:
		item_name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]

	return [
		str(foxlab_receive_item_wave) if foxlab_receive_item_end_wave <= 0 else "%d ~ %d" % [foxlab_receive_item_wave, foxlab_receive_item_end_wave],
		item_name,
		str(value)
	]
