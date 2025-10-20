class_name GetRandCharacterEffect
extends DoubleValueEffect

export(int) var value_base = 2 # set to == value by default to indicate this effect is not cursed

const SAME_CHAR_CHANCE = 0.05
const MIN_TRANSFORM_CHANCE = 10.0
const MAX_TRANSFORM_NUM = 3.05
const MIN_TRANSFORM_NUM = 0.95
# character_builder, character_druid, character_technomage, character_engineer, character_brolab_僧侣_493, character_brolab_砺练者_422, character_brolab_机械恶魔_43
var debug_item_name: Array = []
var curse_character: bool = false

var chars_to_get: Array = []
var starting_items: Array = []

var chars_name: String = ""


static func get_id() -> String:
	return "get_rand_character"
	
func _get_armor_chance(player_index: int, armor_increases_chance: bool) -> float:
	var num = -1 if armor_increases_chance else 1
	# 如果armor_increases_chance为 false，护甲越高概率越低
	var armor = RunData.get_armor_coef(num * Utils.get_stat("stat_armor", player_index))
	return armor
	
func _get_transform_chance(player_index: int) -> float:
	var armor = _get_armor_chance(player_index, false)
	return  max(armor * value2, MIN_TRANSFORM_CHANCE)
	
func _can_character_be_modified(character: CharacterData) -> bool:
	if "res://items/" in character.resource_path or "res://dlcs/" in character.resource_path:
		for effect in character.effects: 
			# cyborg, demon
			if effect is ConvertStatEffect:
				return false
			# ghost, cryptid, sailor
			if effect.key == "dodge_cap":
				return false
			# sailor, wild, knight
			if effect.key == "min_weapon_tier" or effect.key == "max_weapon_tier":
				return false
			# generalist
			if effect.key == "max_melee_weapons" or effect.key == "max_ranged_weapons":
				return false
		return true
	return false

func _is_wave_started(player_index: int) -> bool:
	# 对于无面，简单判断bool就可以判断有没有开始游戏
	if RunData.get_player_effect_bool("fox_无脸_wave_started", player_index):
		return true
	# 其他角色如果拿了面具
	# 如果是初始携带或者第一波商店出现面具，会有问题，但由于面具是紫装，只要不乱搞不会出现这种情况，能规避
	if RunData.current_wave <= 1:
		return false
	# 这个是特殊处理，防止无面在第一波之后的波次重新开始游戏，RunData.reset()还没有设置当前波次
	for effect in RunData.get_player_character(player_index).effects:
		if effect.has_meta("brolab_receive_stat_key") and effect.brolab_receive_stat_key == "fox_无脸_wave_started":
			return false
	return true
	
func _update_character_bg(character: CharacterData, player_index: int) -> CharacterData:
	var diff_info = ProgressData.get_character_difficulty_info(character.my_id, RunData.current_zone)
	var new_item = character.duplicate()
	if diff_info.max_difficulty_beaten.difficulty_value < 0:
		new_item.tier = Tier.COMMON
	if diff_info.max_difficulty_beaten.difficulty_value == 0:
		new_item.tier = Tier.DANGER_0
	elif diff_info.max_difficulty_beaten.difficulty_value > 0:
		new_item.tier = diff_info.max_difficulty_beaten.difficulty_value
	return new_item
	
func unapply(player_index: int) -> void:
	pass

func apply(player_index: int) -> void:	
	var wave_started = _is_wave_started(player_index)	
	if chars_name.empty() or not wave_started: # 防止上一局游戏结束时候的显示的结果就是这一局开始的结果
		if not wave_started:
			chars_name = ""
			starting_items.clear()
		chars_to_get = _get_rand_chars(player_index)
	if not wave_started:
		RunData.remove_item_displayed(RunData.get_player_character(player_index),player_index)
	
	var transform_chance = _get_transform_chance(player_index)
	DebugService.log_data("transform success chance: %s%%" % [str(stepify(transform_chance,0.01))])
	if wave_started and not Utils.get_chance_success(transform_chance / 100.0):
		DebugService.log_data("transform failed")
		return		
	
	cleanup(player_index)
	
	var prev_items = RunData.get_player_effect(custom_key,player_index)
	for character in chars_to_get:
		RunData.add_item(_update_character_bg(character, player_index), player_index)
		DebugService.log_data("add character " + character.my_id)
		prev_items.append([character.my_id, character.is_cursed])

	chars_to_get.clear()
		
	for item in starting_items:
		if item is ItemData:
			RunData.add_item(item, player_index)
			DebugService.log_data("add item " + item.my_id)
			prev_items.append([item.my_id, item.is_cursed])

		else:
			var weapon = RunData.add_weapon(item, player_index)
			#即便是相同的武器ID也可能会有不同的效果，所以用序列化精确判断
			prev_items.append(weapon.serialize())
			DebugService.log_data("add weapon " + weapon.my_id)

	starting_items.clear()

	if Utils.get_chance_success(transform_chance / 100.0):
		_duplicate_weapon(player_index)
		
	_revert_negative_curse(player_index)		
		
	if value_base == value:
		chars_name = ""
		
func _revert_negative_curse(player_index: int):
	#诅咒小于0会秒杀敌人，如果变身后诅咒小于零并且诅咒的修改大于-100%，说明不是玩负诅咒的特殊角色
	var curse_value = Utils.get_stat("stat_curse", player_index)
	var curse_gain = RunData.get_stat_gain("stat_curse", player_index)
	if curse_value >= 0 or curse_gain < 0:
		return

	var effects = RunData.get_player_effects(player_index)
	var curse_temp = TempStats.get_stat("stat_curse", player_index)
	var curse_linked = LinkedStats.get_stat("stat_curse", player_index)
	var new_curse_permanent = (-curse_value - curse_temp - curse_linked) / curse_gain
	effects["stat_curse"] = new_curse_permanent
	Utils.reset_stat_cache(player_index)

func _duplicate_weapon(player_index: int):
	var gain_stat_effect :Array= RunData.get_player_effect("fox_无脸_upgrade_on_transform",player_index)
	if  gain_stat_effect.empty() or RunData.current_wave == gain_stat_effect.back():
		return

	gain_stat_effect.clear()
	gain_stat_effect.append(RunData.current_wave)
	DebugService.log_data("begin to duplicate a weapon")
	var weapon = Utils.get_rand_element(RunData.get_player_weapons(player_index)).duplicate()
	var weapon_for_effect:WeaponData = Utils.get_rand_element(ItemService.weapons)
	while weapon_for_effect.effects.empty():
		weapon_for_effect = Utils.get_rand_element(ItemService.weapons)
	weapon_for_effect = weapon_for_effect.duplicate()
	var new_effects := []
	for effect in weapon_for_effect.effects:
		effect = effect.duplicate()
		new_effects.append(effect)
		if effect is WeaponStackEffect: # stick
			effect.weapon_stacked_name = weapon.name
			effect.weapon_stacked_id = weapon.weapon_id
		elif effect is PercentDamageEffect: # lute etc
			effect.source_id = weapon.weapon_id
		elif effect.custom_key == "yztato_destory_weapons":
			effect.key = weapon.my_id
			effect.text_key = "每波结束时，只保留%s" % [tr(weapon.name)]
	DebugService.log_data("get weapon for effect " + tr(weapon_for_effect.my_id))
	weapon_for_effect.effects = new_effects
	weapon.effects.append_array(new_effects)
	var current = weapon
	var upgrade_into = current.upgrades_into
	while upgrade_into != null:
		upgrade_into = upgrade_into.duplicate()
		upgrade_into.effects.append_array(weapon_for_effect.effects)
		current.upgrades_into = upgrade_into
		current = upgrade_into
		upgrade_into = current.upgrades_into
	RunData.add_weapon(weapon, player_index)
	DebugService.log_data("duplicate weapon " + weapon.my_id)

func cleanup(player_index: int) -> void:
	# 防止游戏开始前的变身的初始物品，在这里被清理了，这些变身只添加角色，不添加初始物品（已经被游戏本体添加了）
	if  not _is_wave_started(player_index) :
		return
		
	var prev_items :Array= RunData.get_player_effect(custom_key,player_index)
	var weapon_to_remove = []
	for i in range(prev_items.size()):
		var weapon_data = prev_items[i]
		if weapon_data is Dictionary:
			var weapon = WeaponData.new()
			weapon.deserialize_and_merge(weapon_data)
			DebugService.log_data("remove " + weapon.my_id)
			RunData.remove_weapon(weapon, player_index)
			weapon_to_remove.append(i)
	weapon_to_remove.invert()
	for i in weapon_to_remove:
		prev_items.remove(i)
		
	var items_to_remove:Dictionary={}
	var player_items = RunData.get_player_items(player_index)
	player_items.invert() #要移除的往往是新获得的物品
	for item_data in player_items:
		for i in range(prev_items.size()):
			if items_to_remove.has(i):
				continue
			if [item_data.my_id, item_data.is_cursed] == prev_items[i] :
				items_to_remove[i] = item_data
			elif (item_data.my_id.begins_with("item_builder_turret") and prev_items[i][0].begins_with("item_builder_turret"))\
				and (item_data.is_cursed == prev_items[i][1]):
				items_to_remove[i] = item_data	
	for item_data in items_to_remove.values():
		DebugService.log_data("remove " + item_data.my_id)
		RunData.remove_item(item_data, player_index)
	prev_items.clear()


func get_args(player_index: int) -> Array:
	if chars_name.empty():
		chars_to_get = _get_rand_chars(player_index)
	return [str(chars_to_get.size()), chars_name, "%s%%" % [stepify(_get_transform_chance(player_index), 0.01)]]
	
func _get_convert_stat_result(character: CharacterData, convert_stat_dict:Dictionary):
	if not character.my_id in convert_stat_dict:
		for effect in character.effects:
			if effect is ConvertStatEffect:
				convert_stat_dict[character.my_id] = 1
				return
		convert_stat_dict[character.my_id] = 0
	
func _are_chars_compatiable(player_index: int, candidate: CharacterData, chars_data: Array) -> bool:
	var convert_stat_dict = RunData.get_player_effect("fox_无脸_convert_stat_characters", player_index)
	var player_character = RunData.get_player_character(player_index)
	_get_convert_stat_result(player_character, convert_stat_dict)
	_get_convert_stat_result(candidate, convert_stat_dict)
	DebugService.log_data("player: %s, value: %s" % [player_character.my_id,convert_stat_dict[player_character.my_id]])
	DebugService.log_data("candidate: %s, value: %s" % [candidate.my_id, convert_stat_dict[candidate.my_id]])
	var conver_stat_num = convert_stat_dict[player_character.my_id]
	for character in chars_data:
		DebugService.log_data("already exists:%s, value: %s " %[ character.my_id, convert_stat_dict[character.my_id]])
		conver_stat_num += convert_stat_dict[character.my_id]
		
	conver_stat_num += convert_stat_dict[candidate.my_id]
	DebugService.log_data("convert_stat_num: %d" % [conver_stat_num])
	return ( conver_stat_num <= 1)

func _get_one_character(player_index: int, chars_id: Array, chars_data: Array) -> CharacterData:
	var current_char: CharacterData = null
	while current_char == null:
		var candidate:CharacterData = null
		if !debug_item_name.empty():
			candidate = ItemService.get_element(ItemService.characters, debug_item_name.front())
			debug_item_name.pop_front()
		if candidate == null:
			candidate = Utils.get_rand_element(ItemService.characters)
			while candidate.my_id in chars_id:
				if !Utils.get_chance_success(SAME_CHAR_CHANCE):
					candidate = Utils.get_rand_element(ItemService.characters)
		if _are_chars_compatiable(player_index, candidate, chars_data):
			current_char = candidate
	return current_char

func _get_rand_chars(player_index: int) -> Array:
	var chars_return:Array=[]
	var chars_id:Array = []
	if RunData.get_player_character(player_index) != null:
		chars_id.append(RunData.get_player_character(player_index).my_id)
	var char_value :float = clamp(value * _get_armor_chance(player_index, true), MIN_TRANSFORM_NUM, MAX_TRANSFORM_NUM)
	var char_value_floored :int = int(char_value)
	var residual_value = 1 if Utils.get_chance_success(char_value - char_value_floored) else 0
	var final_value =  char_value_floored + residual_value
	for char_idx in range(final_value):
		var current_char:CharacterData = _get_one_character(player_index, chars_id, chars_return)
		if _can_character_be_modified(current_char):
			if curse_character:
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				current_char = dlc.curse_item(current_char, player_index)
			current_char = ItemService.apply_item_effect_modifications(current_char, player_index)
		chars_return.append(current_char)
		chars_id.append(current_char.my_id)
		chars_name += tr(current_char.name)

		if current_char.is_cursed:
			chars_name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("BROLAB_CURSED_TEXT")]
		if char_idx + 1 < final_value:
			chars_name += ", "
		
		var container = starting_items
		# 游戏本体已经添加的初始物品，也就是游戏开始前的变身是自带初始物品的角色，在这里只记录，不添加了，下次变身的时候清理这些物品
		var special_starting :Array = []
		var wave_started = _is_wave_started(player_index)
		if not wave_started:
			container = special_starting
		var prev_items :Array= RunData.get_player_effect(custom_key,player_index)
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
						item = dlc.curse_item(item, player_index, true)
					container.append(item)
			elif effect.custom_key == "cursed_starting_weapon" and ProgressData.is_dlc_available_and_active("abyssal_terrors"):
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var weapon = ItemService.get_element(ItemService.weapons, effect.key)
					if dlc:
						weapon = dlc.curse_item(weapon, player_index, true)
					container.append(weapon)
			elif effect.key == "brolab_effect_receive_item_at_wave" \
				and effect.brolab_receive_item_wave == 1:
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var item = ItemService.get_element(ItemService.items, effect.brolab_receive_item_id)
					if dlc and effect.brolab_cursed_item:
						item = dlc.curse_item(item, player_index, true)
					container.append(item)
					
		for starting in special_starting:
			if starting is WeaponData:
				prev_items.append(starting.serialize())
			else:
				prev_items.append([starting.my_id, starting.is_cursed])
	return chars_return
	
func serialize() -> Dictionary:
	var serialized =.serialize()
	serialized.value_base = value_base
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	value_base = serialized.value_base if "value_base" in serialized else 2
