class_name GetRandCharacterEffect
extends DoubleValueEffect

export(int) var value_base = 2 # set to == value by default to indicate this effect is not cursed

const SAME_CHAR_CHANCE = 0.05
# character_builder, character_druid, character_technomage, character_engineer, character_brolab_僧侣_493
var debug_item_name: String = ""

var chars_to_get: Array = []
var starting_items: Array = []
# before wave one started
var special_starting_items: Array = []

var chars_name: String = ""


static func get_id() -> String:
	return "get_rand_character"
	
func _get_armor_chance(player_index: int, armor_increases_chance: bool) -> float:
	var num = -1 if armor_increases_chance else 1
	var armor = RunData.get_armor_coef(num * Utils.get_stat("stat_armor", player_index))
	return armor


func unapply(player_index: int) -> void:
	pass

func apply(player_index: int) -> void:		
	if chars_name.empty():
		chars_to_get = _get_rand_chars(player_index)
	if RunData.current_wave <= 1:
		RunData.remove_item_displayed(RunData.get_player_character(player_index),player_index)
	
	var armor = _get_armor_chance(player_index, false)
	if not (RunData.current_wave <= 1 or Utils.get_chance_success(value2 * armor / 100.0)):
		return		
	
	cleanup(player_index)
	
	var prev_items = RunData.get_player_effect(custom_key,player_index)
	for character in chars_to_get:
		RunData.add_item(character, player_index)
		prev_items.append(character)

	chars_to_get.clear()
		
	for item in starting_items:
		if item is ItemData:
			RunData.add_item(item, player_index)
			prev_items.append(item)

		else:
			var weapon = RunData.add_weapon(item, player_index)
			prev_items.append(weapon)

	starting_items.clear()

	if value_base == value:
		chars_name = ""

func cleanup(player_index: int) -> void:
	var prev_items = RunData.get_player_effect(custom_key,player_index)
	if  RunData.get_player_effect_bool("fox_无脸_wave_started", player_index) and not special_starting_items.empty():
		prev_items.append_array(special_starting_items)
		special_starting_items.clear()
	for item_data in prev_items:
		if item_data is WeaponData:
			RunData.remove_weapon(item_data, player_index)
		elif "ITEM_BUILDER_TURRET" == item_data.name:
			var structure_range = RunData.get_player_effect("structure_range", player_index)
			var level = BuilderTurret.get_level(structure_range)
			var player_items = RunData.get_player_items(player_index)
			for item in player_items:
				if item.my_id == "item_builder_turret_" + str(level) or item.my_id == item_data.my_id:
					RunData.remove_item(item, player_index)
					break
		else:
			RunData.remove_item(item_data, player_index, true)
	prev_items.clear()


func get_args(player_index: int) -> Array:
	if chars_name.empty():
		chars_to_get = _get_rand_chars(player_index)
	var armor = _get_armor_chance(player_index, false)
	return [str(chars_to_get.size()), chars_name, "%s%%" % [stepify(value2 * armor,0.01)]]

func _get_rand_chars(player_index: int) -> Array:
	var chars_return:Array=[]
	var chars_id:Array = []
	if RunData.get_player_character(player_index) != null:
		chars_id.append(RunData.get_player_character(player_index).my_id)
	var char_value :float = value * _get_armor_chance(player_index, true)
	var char_value_floored :int = int(char_value)
	var residual_value = 1 if Utils.get_chance_success(char_value - char_value_floored) else 0
	var final_value =  char_value_floored + residual_value
	for char_idx in range(final_value):
		var current_char:CharacterData = null
		if !debug_item_name.empty():
			current_char = ItemService.get_element(ItemService.characters, debug_item_name)
			debug_item_name = ""
		else:
			current_char = Utils.get_rand_element(ItemService.characters)
			while current_char.my_id in chars_id:
				if !Utils.get_chance_success(SAME_CHAR_CHANCE):
					current_char = Utils.get_rand_element(ItemService.characters)
		current_char = ItemService.apply_item_effect_modifications(current_char, player_index)
		chars_return.append(current_char)
		chars_id.append(current_char.my_id)
		chars_name += tr(current_char.name)

		if current_char.is_cursed:
			chars_name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("BROLAB_CURSED_TEXT")]
		if char_idx + 1 < final_value:
			chars_name += ", "
		
		var container = starting_items
		if not RunData.get_player_effect_bool("fox_无脸_wave_started", player_index):
			container = special_starting_items
		for effect in current_char.effects:
			if effect.custom_key == "starting_item":
				for i in range(effect.value):
					var item = ItemService.get_element(ItemService.items, effect.key)
					container.append(item)
			elif effect.custom_key == "starting_weapon":
				for i in range(effect.value):
					var weapon = ItemService.get_element(ItemService.weapons,effect.key)
					container.append(weapon)
			elif effect.custom_key == "cursed_starting_item"  and ProgressData.is_dlc_available_and_active("abyssal_terrors"):
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var item = ItemService.get_element(ItemService.items, effect.key)
					if dlc:
						item = dlc.curse_item(item, player_index)
					container.append(item)
			elif effect.custom_key == "cursed_starting_weapon" and ProgressData.is_dlc_available_and_active("abyssal_terrors"):
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var weapon = ItemService.get_element(ItemService.weapons, effect.key)
					if dlc:
						weapon = dlc.curse_item(weapon, player_index)
					container.append(weapon)
			elif effect.key == "brolab_effect_receive_item_at_wave" \
				and effect.brolab_receive_item_wave == 1 and RunData.current_wave > 1:
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var item = ItemService.get_element(ItemService.items, effect.brolab_receive_item_id)
					if dlc and effect.brolab_cursed_item:
						item = dlc.curse_item(item, player_index)
					starting_items.append(item)
				
	return chars_return
	
func serialize() -> Dictionary:
	var serialized =.serialize()

	serialized.chars_name = chars_name
	serialized.value_base = value_base

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	chars_name = serialized.chars_name if "chars_name" in serialized else ""
	value_base = serialized.value_base if "value_base" in serialized else 2

