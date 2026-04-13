class_name FoxLabGetRandCharacterEffect
extends "res://effects/items/double_value_effect.gd"

const SAME_CHAR_CHANCE = 0.33
const MIN_TRANSFORM_CHANCE = 10.0
const MAX_TRANSFORM_NUM = 3.05
const MIN_TRANSFORM_NUM = 0.95
const VALUE_BASE = 2
# character_builder, character_druid, character_technomage, character_engineer, character_foxlab_monk, character_foxlab_survivor, character_foxlab_infernal_machine
# character_foxlab_architect
var debug_item_name: Array = []
var curse_character: bool = false

static func get_id() -> String:
	return "foxlab_effect_get_rand_character"

func _get_armor_chance(player_index: int, armor_increases_chance: bool) -> float:
	var num = -1 if armor_increases_chance else 1
	# 如果armor_increases_chance为 false，护甲越高概率越低
	var armor = RunData.get_armor_coef(num * Utils.get_stat(Keys.stat_armor_hash, player_index))
	return armor

func _get_transform_chance(player_index: int) -> float:
	var armor = _get_armor_chance(player_index, false)
	return  max(armor * value2, MIN_TRANSFORM_CHANCE)

func _can_character_be_modified(character: CharacterData) -> bool:
	if character.resource_path.begins_with("res://items/") or character.resource_path.begins_with("res://dlcs/"):
		for effect in character.effects:
			# cyborg, demon
			if effect is ConvertStatEffect and effect.custom_key_hash == Keys.convert_stats_end_of_wave_hash:
				return false
		return true
	return false

func _is_wave_started(player_index: int) -> bool:
	var started = RunData.is_wave_started()
	DebugService.log_data("check fox_wave_started: %s" % [str(started)])
	return started

func _update_character_bg(character: CharacterData, player_index: int) -> CharacterData:
	var diff_info = ProgressData.get_character_difficulty_info(character.my_id_hash, RunData.current_zone)
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

func try_generate(player_index: int):
	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_mask_meta(player_index)[is_cursed]
	if meta.names == "":
		meta.chars = _get_rand_chars(player_index)

func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	# [变身堆栈数，正在变身否]
	var stack_effect:Array = effects[Utils.fox_faceless_transform_stack_hash]
	if stack_effect[1]:
		stack_effect[0] += 1
		DebugService.log_data("add transform stack: %d" % [stack_effect[0]])
		return
	stack_effect[1] = true
	DebugService.log_data("start transform, stack: %d" % [stack_effect[0]])

	try_generate(player_index)
	var transform_chance = _get_transform_chance(player_index)
	DebugService.log_data("transform success chance: %s%%" % [str(stepify(transform_chance,0.01))])
	var wave_started = _is_wave_started(player_index)
	if wave_started and not Utils.get_chance_success(transform_chance / 100.0):
		DebugService.log_data("transform failed")
		_after_transform(player_index, stack_effect)
		return

	var is_vagabond_on0 = RunData.get_player_effect_bool(Keys.all_weapons_count_for_sets_hash, player_index)

	cleanup(player_index)

	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_mask_meta(player_index)[is_cursed]
	RunData.emit_signal("foxlab_sec_char_changed", meta.chars, player_index)
	var prev_items = meta.prevs
	# always place ConvertStatEffect of characters ahead
	var convert_stats_half_wave:Array = RunData.get_player_effect(Keys.convert_stats_half_wave_hash, player_index)
	var convert_stats_end_of_wave:Array = RunData.get_player_effect(Keys.convert_stats_end_of_wave_hash, player_index)
	var convert_stats_half_wave_bak:Array = convert_stats_half_wave.duplicate()
	var convert_stats_end_of_wave_bak:Array = convert_stats_end_of_wave.duplicate()
	convert_stats_half_wave.clear()
	convert_stats_end_of_wave.clear()
	for character in meta.chars:
		RunData.add_item(_update_character_bg(character, player_index), player_index)
		DebugService.log_data("add character " + character.my_id)
		prev_items.append([character.my_id_hash, character.curse_factor])
	convert_stats_half_wave.append_array(convert_stats_half_wave_bak)
	convert_stats_end_of_wave.append_array(convert_stats_end_of_wave_bak)
	meta.chars.clear()

	for item in meta.items:
		RunData.add_item(item, player_index)
		DebugService.log_data("add item " + item.my_id)
		prev_items.append([item.my_id_hash, item.curse_factor])
	for weapon in meta.weapons:
		var weapon_to_add = RunData.add_weapon(weapon, player_index)
		prev_items.append(weapon_to_add)
		DebugService.log_data("add weapon " + weapon_to_add.my_id + str(weapon_to_add))
	meta.items.clear()
	meta.weapons.clear()

	RunData.add_tracked_value(player_index, Utils.item_foxlab_mask_hash, 1)

	if RunData.get_player_weapons_ref(player_index).size() > 0 and Utils.get_chance_success(transform_chance / 100.0):
		_duplicate_weapon(player_index)

	var is_vagabond_on1 = RunData.get_player_effect_bool(Keys.all_weapons_count_for_sets_hash, player_index)
	if is_vagabond_on0 != is_vagabond_on1:
		RunData.update_sets(player_index)

	var index = RunData.tracked_item_effects[player_index][Utils.item_foxlab_mask_hash] as int
	var color = ProgressData.settings.color_positive if (index & 1) else ProgressData.settings.color_negative
	var history = "[color=#%s]%s[/color]" % [ color, meta.names]
	RunData.get_player_effect(Utils.foxlab_mask_history_hash, player_index).append(history)
	meta.names = ""

	_after_transform(player_index, stack_effect)


func _after_transform(player_index: int, stack_effect: Array) -> void:
	stack_effect[1] = false
	DebugService.log_data("end transform, stack: %d" % [stack_effect[0]])
	if stack_effect[0] > 0:
		stack_effect[0] -= 1
		apply(player_index)

func _duplicate_weapon(player_index: int):
	var effects =  RunData.get_player_effects(player_index)
	var upgrade_enabled = effects[Utils.fox_faceless_enable_upgrade_on_transform_hash]
	var upgrade_wave = effects[Utils.fox_faceless_upgrade_on_transform_wave_hash]
	if  not upgrade_enabled or RunData.current_wave == upgrade_wave:
		return

	DebugService.log_data("begin to duplicate a weapon, previous wave: " + str(upgrade_wave))
	effects[Utils.fox_faceless_upgrade_on_transform_wave_hash] = RunData.current_wave if _is_wave_started(player_index) else 1
	var weapon = Utils.get_rand_element(RunData.get_player_weapons_ref(player_index)).duplicate()
	#附魔后加一个价值， 避免建造者的炮塔不识货
	weapon.value += 1
	var weapon_for_effect = Utils.get_rand_element(ItemService.weapons)
	# 附魔的武器的等级最多超过当前武器1级
	while weapon_for_effect.effects.empty() or (weapon.tier + 1 < weapon_for_effect.tier):
		weapon_for_effect = Utils.get_rand_element(ItemService.weapons)
	weapon_for_effect = weapon_for_effect.duplicate()
	weapon_for_effect = ItemService.apply_item_effect_modifications(weapon_for_effect, player_index)
	DebugService.log_data("get weapon for effect " + tr(weapon_for_effect.my_id))

	var new_effects :Array = RunData.foxlab_get_effects_from_another_weapon(weapon, weapon_for_effect, true)
	weapon.effects.append_array(new_effects)
	RunData.add_weapon(weapon, player_index)
	DebugService.log_data("duplicate weapon " + weapon.my_id)
	RunData.add_tracked_value(player_index, Utils.character_foxlab_faceless_hash, 1)

func cleanup(player_index: int) -> void:
	# 防止游戏开始前的变身的初始物品，在这里被清理了，这些变身只添加角色，不添加初始物品（已经被游戏本体添加了）
	if  not _is_wave_started(player_index) :
		return
	var metas = RunData.get_foxlab_mask_meta(player_index)
	var prev_items = []
	for meta in metas:
		if not meta.prevs.empty():
			prev_items.append_array(meta.prevs)
	if prev_items.empty():
		return

	var weapon_to_remove = []
	for i in range(prev_items.size()):
		var weapon = prev_items[i]
		assert (not weapon is Dictionary)
		if weapon is WeaponData:
			var player_weapons_raw: Array = RunData.get_player_weapons_ref(player_index)
			var should_remove_weapon = false
			if weapon in player_weapons_raw:
				should_remove_weapon = true
			else:
				for exist_weapon in player_weapons_raw:
					if ItemService.is_same_weapon(exist_weapon, weapon):
						should_remove_weapon = true
						break
			if should_remove_weapon:
				RunData.remove_weapon(weapon, player_index)
				DebugService.log_data("remove " + weapon.my_id + str(weapon))
			else:
				DebugService.log_data("not remove missing " + weapon.my_id + str(weapon))
			weapon_to_remove.append(i)
	weapon_to_remove.invert()
	for i in weapon_to_remove:
		prev_items.remove(i)

	var items_to_remove:Dictionary={}
	var items_to_remove_order:Array = []
	var player_items_raw = RunData.get_player_items_ref(player_index)
	# 要移除的往往是新获得的物品，而且先加入的应该后退出才能保证REPLACE类型的数据正确地恢复
	# 1. 比如宝宝+多面手，宝宝-5武器栏，多面手是置1为12，进场的时候12武器栏，离场的时候，应该是多面手把武器栏恢复成1，然后宝宝+5恢复成6
	# 如果顺序弄反了，先宝宝离场武器栏变17然后多面手离场，武器变1了
	# 2. 如果是多面手+宝宝，则进场的时候多面手6->12，宝宝是12-5=7，离场的时候多面手把武器栏直接置为6
	# 如果顺序弄反了，先多面手离场武器栏恢复6，然后宝宝离场武器栏+5变11
	for index in range(player_items_raw.size(), 0, -1):
		var item_data = player_items_raw[index - 1]
		for i in range(prev_items.size()):
			if items_to_remove.has(i) or item_data.curse_factor != prev_items[i][1]:
				continue

			if item_data.my_id_hash == prev_items[i][0] or (item_data.my_id_hash in Keys.item_builder_turret_n_hash and prev_items[i][0] in Keys.item_builder_turret_n_hash) :
				items_to_remove[i] = item_data
				items_to_remove_order.push_back(item_data)
				break

		if items_to_remove_order.size() == prev_items.size():
			break
	for item_data in items_to_remove_order:
		DebugService.log_data("remove " + item_data.my_id + str(item_data))
		RunData.remove_item(item_data, player_index)

	for meta in metas:
		meta.prevs.clear()


func get_args(player_index: int) -> Array:
	if RunData.get_player_character(player_index) == null:
		return ["%s ~ %s" % [str(floor(MIN_TRANSFORM_NUM)), str(ceil(MAX_TRANSFORM_NUM))], tr("FOXLAB_RANDOM"), tr("FOXLAB_RANDOM")]
	try_generate(player_index)
	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_mask_meta(player_index)[is_cursed]
	return [str(meta.chars.size()),meta.names, str(stepify(_get_transform_chance(player_index), 0.01))]

func _get_convert_stat_result(character: CharacterData, convert_stat_dict:Dictionary):
	if not character.my_id_hash in convert_stat_dict:
		for effect in character.effects:
			if effect is ConvertStatEffect and not effect.custom_key.begins_with("fox"):
				convert_stat_dict[character.my_id_hash] = 1
				return
		convert_stat_dict[character.my_id_hash] = 0

func _are_chars_compatible(player_index: int, candidate: CharacterData, chars_data: Array) -> bool:
	if ItemService.characters.size() != ItemService.get_foxlab_transform_characters().size():
		return true
	var convert_stat_dict = RunData.get_player_effect(Utils.fox_faceless_convert_stat_characters_hash, 0)
	var player_character = RunData.get_player_character(player_index)
	_get_convert_stat_result(player_character, convert_stat_dict)
	_get_convert_stat_result(candidate, convert_stat_dict)
	DebugService.log_data("player: %s, value: %s" % [player_character.my_id,convert_stat_dict[player_character.my_id_hash]])
	DebugService.log_data("candidate: %s, value: %s" % [candidate.my_id, convert_stat_dict[candidate.my_id_hash]])
	var conver_stat_num = convert_stat_dict[player_character.my_id_hash]
	for character in chars_data:
		DebugService.log_data("already exists:%s, value: %s " %[ character.my_id, convert_stat_dict[character.my_id_hash]])
		conver_stat_num += convert_stat_dict[character.my_id_hash]

	conver_stat_num += convert_stat_dict[candidate.my_id_hash]
	DebugService.log_data("convert_stat_num: %d" % [conver_stat_num])
	return ( conver_stat_num <= 1)

func _get_one_character(player_index: int, chars_id: Array, chars_data: Array) -> CharacterData:
	var current_char = null
	while current_char == null:
		var candidate = null
		if !debug_item_name.empty():
			var item_name_hash = Keys.generate_hash(debug_item_name.pop_front())
			candidate = ItemService.get_element(ItemService.characters, item_name_hash)
		if candidate == null:
			candidate = Utils.get_rand_element(ItemService.get_foxlab_transform_characters())
			while candidate.my_id_hash in chars_id:
				if !Utils.get_chance_success(SAME_CHAR_CHANCE):
					candidate = Utils.get_rand_element(ItemService.get_foxlab_transform_characters())
		if _are_chars_compatible(player_index, candidate, chars_data):
			current_char = candidate
	return current_char

func _get_rand_chars(player_index: int) -> Array:
	var chars_return:Array=[]
	var chars_id:Array = []
	if RunData.get_player_character(player_index) != null:
		chars_id.append(RunData.get_player_character(player_index).my_id_hash)
	var char_value :float = clamp(value * _get_armor_chance(player_index, true), MIN_TRANSFORM_NUM, MAX_TRANSFORM_NUM)
	var char_value_floored :int = int(char_value)
	var residual_value = 1 if Utils.get_chance_success(char_value - char_value_floored) else 0
	var final_value =  char_value_floored + residual_value
	var is_cursed:int = value != VALUE_BASE
	var meta = RunData.get_foxlab_mask_meta(player_index)[is_cursed]
	for char_idx in range(final_value):
		var current_char = _get_one_character(player_index, chars_id, chars_return)
		if _can_character_be_modified(current_char):
			if curse_character:
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				current_char = dlc.curse_item(current_char, player_index)
			current_char = ItemService.apply_item_effect_modifications(current_char, player_index)
		chars_return.append(current_char)
		chars_id.append(current_char.my_id_hash)
		meta.names += tr(current_char.name)

		if current_char.is_cursed:
			meta.names += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
		if char_idx + 1 < final_value:
			meta.names += ", "

		var container = []
		for effect in current_char.effects:
			if effect.custom_key_hash == Keys.starting_item_hash:
				for i in range(effect.value):
					var item = ItemService.get_element(ItemService.items, effect.key_hash)
					container.append(item)
			elif effect.custom_key_hash == Keys.starting_weapon_hash:
				for i in range(effect.value):
					var weapon = ItemService.get_element(ItemService.weapons,effect.key_hash)
					container.append(weapon)
			elif effect.custom_key_hash == Keys.cursed_starting_item_hash  and ProgressData.is_dlc_available_and_active("abyssal_terrors"):
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var item = ItemService.get_element(ItemService.items, effect.key_hash)
					if dlc:
						item = dlc.curse_item(item, player_index, true)
					container.append(item)
			elif effect.custom_key_hash == Keys.cursed_starting_weapon_hash and ProgressData.is_dlc_available_and_active("abyssal_terrors"):
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var weapon = ItemService.get_element(ItemService.weapons, effect.key_hash)
					if dlc:
						weapon = dlc.curse_item(weapon, player_index, true)
					container.append(weapon)
			elif effect.key == "brolab_effect_receive_item_at_wave" \
				and effect.brolab_receive_item_wave == 1\
				and effect.brolab_receive_item_end_wave == 1:
				var dlc = ProgressData.get_dlc_data("abyssal_terrors")
				for i in range(effect.value):
					var item = ItemService.get_element(ItemService.items, Keys.generate_hash(effect.brolab_receive_item_id))
					if dlc and effect.brolab_cursed_item:
						item = dlc.curse_item(item, player_index, true)
					container.append(item)

		if _is_wave_started(player_index):
			for starting in container:
				if starting is WeaponData:
					meta.weapons.push_back(starting)
				else:
					meta.items.push_back(starting)
		# 游戏本体已经添加的初始物品，也就是游戏开始前的变身是自带初始物品的角色，在这里只记录，不添加了，下次变身的时候清理这些物品
		else:
			var prev_items = meta.prevs
			for starting in container:
				if starting is WeaponData:
					prev_items.append(starting)
				else:
					prev_items.append([starting.my_id_hash, starting.curse_factor])
	if meta.names == "":
		meta.names = tr("FOXLAB_DISABLE")
	return chars_return
