extends "res://singletons/run_data.gd"

var foxlab_remembered_items = [ [], [], [], [] ]
var foxlab_remembered_weapons = [ [], [], [], [] ]
var foxlab_shop_items = [ [], [], [], []]

func foxlab_remember_item(item: ItemParentData, player_index: int):
	var previous_remembered:Array = get_player_effect("foxlab_previous_remembered", player_index)
	DebugService.log_data("item: %s, cursed: %s" % [tr(item.name), item.is_cursed])
	if item.my_id in previous_remembered:
		DebugService.log_data("already remembered")
		return

	if item.get_category() == Category.WEAPON:
		var weapon = item as WeaponData
		if not weapon.effects.empty():
			foxlab_remembered_weapons[player_index].push_back(weapon)
	else:
		foxlab_remembered_items[player_index].push_back(item as ItemData)
		DebugService.log_data("before add item, item num: %d/%d" % [get_nb_item(item.my_id, player_index), players_data[player_index].items.size() ])
		add_item(item, player_index)
		DebugService.log_data("after add item, item num: %d/%d" % [get_nb_item(item.my_id, player_index), players_data[player_index].items.size() ])

func foxlab_modify_weapon(player_index: int):
	if foxlab_remembered_weapons[player_index].empty():
		return
	for weapon in get_player_weapons(player_index):
		if weapon == players_data[player_index].selected_weapon:
			players_data[player_index].selected_weapon = players_data[player_index].selected_weapon.duplicate()
		var null_effect = NullEffect.new()
		null_effect.key = "foxlab_remember_shop_items"
		null_effect.text_key = "foxlab_effect_remembered_weapon"
		weapon.effects.append(null_effect)
		for weapon_for_effect in foxlab_remembered_weapons[player_index]:
			var new_effects:Array = foxlab_get_effects_from_another_weapon(weapon, weapon_for_effect)
			Utils.reset_stat_cache(player_index)
			for effect in new_effects:
				effect.apply(player_index)
			weapon.effects.append_array(new_effects)
	LinkedStats.reset_player(player_index)

func foxlab_update_remembered_item(player_index: int):
	var previous_remembered:Array = get_player_effect("foxlab_previous_remembered", player_index)
	previous_remembered.clear()
	var previous_remembered_names:Array = get_player_effect("foxlab_previous_remembered_names", player_index)
	previous_remembered_names.clear()
	for item in foxlab_remembered_items[player_index]:
		previous_remembered.append(item.my_id)
		var name = tr(item.name)
		if item.is_cursed:
			name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
		previous_remembered_names.append(name)
	for weapon in foxlab_remembered_weapons[player_index]:
		previous_remembered.append(weapon.my_id)
		var name = " %s %s" % [tr(weapon.name), ItemService.get_tier_number(weapon.tier)]
		if weapon.is_cursed:
			name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
		previous_remembered_names.append(name)
	RunData.add_tracked_value(player_index, "character_foxlab_mnemosyne", previous_remembered.size())

func foxlab_forget_item(player_index: int):
	if not foxlab_remembered_items[player_index].empty():
		var effects = RunData.get_player_effects(player_index)
		var previous_loot_next_wave = effects["extra_loot_aliens_next_wave"]
		var previous_hp_next_wave = effects["hp_start_next_wave"]
		for item in foxlab_remembered_items[player_index]:
			if item in players_data[player_index].items:
				DebugService.log_data("item num: %d/%d" % [ get_nb_item(item.my_id, player_index), players_data[player_index].items.size() ])
				remove_item(item, player_index)
				DebugService.log_data("remove %s, curse: %s, item num: %d/%d" % [ item.my_id, str(item.is_cursed), get_nb_item(item.my_id, player_index), players_data[player_index].items.size() ])
		add_item_displayed(get_player_character(player_index), player_index)
		foxlab_remembered_items[player_index].clear()
		# 数字型临时属性，回收的时候会让属性减少，实际上在出发的时候就被Main清空了
		# 数组型由于不存在那个key了，所以回收的时候无事发生
		effects["extra_loot_aliens_next_wave"] = previous_loot_next_wave
		effects["hp_start_next_wave"] =  previous_hp_next_wave

	for weapon in get_player_weapons(player_index):
		Utils.reset_stat_cache(player_index)
		var effects: Array = weapon.effects
		for i in range(effects.size()):
			if effects[i].text_key == "foxlab_effect_remembered_weapon":
				while effects.size() > i:
					effects.pop_back().unapply(player_index)
				break
	LinkedStats.reset_player(player_index)
	foxlab_remembered_weapons[player_index].clear()
	foxlab_shop_items[player_index].clear()

func foxlab_adjust_weapon_effect(effect: Effect, weapon: WeaponData):
	if effect is WeaponStackEffect: # stick
		effect.weapon_stacked_name = weapon.name
		effect.weapon_stacked_id = weapon.weapon_id
	elif effect is PercentDamageEffect: # lute etc
		effect.source_id = weapon.weapon_id
	elif effect.custom_key == "yztato_destory_weapons":
		effect.key = weapon.weapon_id #保留的是武器大名，不是带等级的my_id
		effect.text_key = tr("EFFECT_FOXLAB_WEAPON_TEXT_ONLY") % [tr(weapon.name)]

func foxlab_get_effects_from_another_weapon(weapon: WeaponData, weapon_for_effect: WeaponData) -> Array:
	var null_effect = NullEffect.new()
	null_effect.key = " %s %s" % [tr(weapon_for_effect.name), ItemService.get_tier_number(weapon_for_effect.tier)]
	null_effect.text_key = "EFFECT_FOXLAB_WEAPON_TEXT_CURSED" if weapon_for_effect.is_cursed else "EFFECT_FOXLAB_WEAPON_TEXT"
	var new_effects := [null_effect]
	for effect in weapon_for_effect.effects:
		effect = effect.duplicate()
		new_effects.append(effect)
		foxlab_adjust_weapon_effect(effect, weapon)
	return new_effects

###### 道具计数相关 #####
#本来应该写到item_description.gd，但因为Yoko-Optimize强制写入这个文件并禁止其他MOD写入，就写到这里了
func foxlab_set_item_description(item_description: ItemDescription, item_data: ItemParentData, player_index: int) -> void :
	if item_data is ItemData and not item_data is CharacterData:
		if item_data.max_nb <= 0:
			var number = get_nb_item(item_data.my_id, player_index);
			item_description._category.text += "(%s/∞)" % [str(number)]
		elif item_data.max_nb == 1:
			var number = get_nb_item(item_data.my_id, player_index);
			if number > 1:
				item_description._category.text += "(%s/1)" % [str(number)]

###### 扩展 ######
func on_wave_start(timer: WaveTimer) -> void :
	.on_wave_start(timer)
	get_player_effects(0)["foxlab_shop_effects_checked"] = 0
	DebugService.log_data("foxlab_shop_effects_checked: set false")

func get_next_level_xp_needed(player_index) -> float:
	var xp_needed = .get_next_level_xp_needed(player_index)
	if xp_needed > 0:
		return xp_needed
	# 防止需要的经验不是正数，导致无限升级爆栈
	var xp_needed_effect = max(get_player_effect("next_level_xp_needed", player_index), -99)
	return get_xp_needed(get_player_level(player_index) + 1) * (1.0 + xp_needed_effect / 100.0)

func add_starting_items_and_weapons() -> void :
	var effects = get_player_effects(0)
	.add_starting_items_and_weapons()
	effects["fox_wave_started"] = 1
	foxlab_remembered_items = [ [], [], [], [] ]
	foxlab_remembered_weapons = [ [], [], [], [] ]
	foxlab_shop_items = [ [], [], [], [] ]

func is_wave_started() -> bool:
	return get_player_effect_bool("fox_wave_started", 0)

const FOXLAB_ELITE_CHARS = ["character_foxlab_war_master", "character_foxlab_survivor", "character_foxlab_kidnapper", "character_foxlab_wormhole_traveler", "character_foxlab_venom", "character_foxlab_bounty_hunter"]
const FOXLAB_HORDE_CHARS = ["character_foxlab_pufferfish"]

func init_elites_spawn(base_wave: int = 10, horde_chance: float = 0.4) -> void :
	for player_index in get_player_count():
		var current_character = get_player_character(player_index)
		if current_character != null:
			if current_character.my_id in FOXLAB_ELITE_CHARS:
				horde_chance = 0.0
			elif get_player_count() == 1 and current_character.my_id in FOXLAB_HORDE_CHARS:
				horde_chance = 1.0
	.init_elites_spawn(base_wave, horde_chance)
