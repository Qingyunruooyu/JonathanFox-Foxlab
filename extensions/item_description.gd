extends "res://ui/menus/shop/item_description.gd"

var foxlab_item_is_special_upgrade = false
var foxlab_expand_indefinitely = true

func _ready() -> void :
    foxlab_expand_indefinitely = expand_indefinitely

func foxlab_should_scroll() -> bool:
	return (RunData.shop_effects_checked and item is WeaponData and item.effects.size() > 9)\
		or (not RunData.is_coop_run and foxlab_item_is_special_upgrade)

func foxlab_update_visibility() -> void:
	expand_indefinitely = (get_effects() == _effects)
	_vbox_container.visible = show_details and expand_indefinitely
	_scroll_container.visible = show_details and not expand_indefinitely

########## 扩展 ############
func get_weapon_stats():
	if .get_weapon_stats() == _weapon_stats_scrolled || foxlab_should_scroll():
		return _weapon_stats_scrolled
	return _weapon_stats

func get_effects():
	if .get_effects() == _effects_scrolled || foxlab_should_scroll():
		return _effects_scrolled
	return _effects

func set_item(item_data: ItemParentData, player_index: int, item_count: int = 1)->void :
	foxlab_item_is_special_upgrade = item_data is UpgradeData and not Utils.foxlab_is_vanilla_upgrade(item_data)
	if foxlab_item_is_special_upgrade:
		item_data = item_data.get_meta("foxlab_item", item_data)

	expand_indefinitely = foxlab_expand_indefinitely
	.set_item(item_data, player_index, item_count)
	foxlab_update_visibility()

	if item_data is ItemData and not item_data is CharacterData and not item_data is UpgradeData and not item_data is DifficultyData:
		if item_data.max_nb <= 0:
			var number = RunData.get_nb_item(item_data.my_id_hash, player_index);
			_category.text += " (%s/∞)" % [str(number)]
		elif item_data.max_nb == 1:
			var number = RunData.get_nb_item(item_data.my_id_hash, player_index);
			if number > 1:
				_category.text += " (%s/1)" % [str(number)]

