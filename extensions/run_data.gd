extends "res://singletons/run_data.gd"

#孟婆相关
var foxlab_remembered_items = [ [], [], [], [] ]
var foxlab_remembered_weapons = [ [], [], [], [] ]
var foxlab_shop_items = [ [], [], [], [] ]

#鬼差相关
var foxlab_is_midnight = [false, false, false, false]

#替罪羊相关
var foxlab_scapegoat_no_hurt = [[], [], [], []]

#面具相关，面具成功触发时发出信号
signal foxlab_sec_char_changed(new_characters, player_index)
#刷新商店的道具/武器仓库界面
signal foxlab_item_gear_changed(player_index)
signal foxlab_weapon_gear_changed(player_index)

func foxlab_remember_item(item: ItemParentData, player_index: int):
	var previous_remembered:Array = get_player_effect(Utils.foxlab_previous_remembered_hash, player_index)
	# DebugService.log_data("item: %s, cursed: %s" % [tr(item.name), item.is_cursed])
	if item.my_id_hash in previous_remembered:
		DebugService.log_data("already remembered")
		return

	if item.get_category() == Category.WEAPON:
		var weapon = item as WeaponData
		if not weapon.effects.empty():
			foxlab_remembered_weapons[player_index].push_back(weapon)
	else:
		foxlab_remembered_items[player_index].push_back(item as ItemData)
		# DebugService.log_data("before add item, item num: %d/%d" % [get_nb_item(item.my_id_hash, player_index), players_data[player_index].items.size() ])
		add_item(item, player_index)
		# DebugService.log_data("after add item, item num: %d/%d" % [get_nb_item(item.my_id_hash, player_index), players_data[player_index].items.size() ])

func foxlab_modify_weapon(player_index: int):
	if foxlab_remembered_weapons[player_index].empty():
		return
	var begin_effect = NullEffect.new()
	begin_effect.key = "foxlab_remember_shop_items"
	begin_effect.key_hash = Utils.foxlab_remember_shop_items_hash
	begin_effect.custom_key = "foxlab_remembered_effect_begin"
	begin_effect.custom_key_hash = Utils.foxlab_remembered_effect_begin_hash
	begin_effect.text_key = "foxlab_effect_remembered_weapon"
	for weapon in get_player_weapons_ref(player_index):
		if weapon == players_data[player_index].selected_weapon:
			players_data[player_index].selected_weapon = players_data[player_index].selected_weapon.duplicate()
		weapon.effects.append(begin_effect)
		for weapon_for_effect in foxlab_remembered_weapons[player_index]:
			var new_effects:Array = foxlab_get_effects_from_another_weapon(weapon, weapon_for_effect, false)
			Utils.reset_stat_cache(player_index)
			for effect in new_effects:
				effect.apply(player_index)
			weapon.effects.append_array(new_effects)
	LinkedStats.reset_player(player_index)

func foxlab_update_remembered_item(player_index: int):
	var previous_remembered:Array = get_player_effect(Utils.foxlab_previous_remembered_hash, player_index)
	previous_remembered.clear()
	var previous_remembered_names:Array = get_player_effect(Utils.foxlab_previous_remembered_names_hash, player_index)
	previous_remembered_names.clear()
	for item in foxlab_remembered_items[player_index]:
		previous_remembered.append(item.my_id_hash)
		var name = tr(item.name)
		if item.is_cursed:
			name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
		previous_remembered_names.append(name)
	for weapon in foxlab_remembered_weapons[player_index]:
		previous_remembered.append(weapon.my_id_hash)
		var name = " %s %s" % [tr(weapon.name), ItemService.get_tier_number(weapon.tier)]
		if weapon.is_cursed:
			name += "([color=#%s]%s[/color])" % [Utils.CURSE_COLOR.to_html(), tr("FOXLAB_CURSED_TEXT")]
		previous_remembered_names.append(name)
	RunData.add_tracked_value(player_index, Utils.character_foxlab_mnemosyne_hash, previous_remembered.size())

# 大部分时候没用，非主角位置的孟婆，记忆了商店的面具道具将孟婆换掉之后
# 由于已经没有孟婆了，敌袭结束记忆保留，如果之后面具再次随机出孟婆，如果前一次孟婆的记忆还在，会重复添加
func foxlab_forget_item_entry(player_index:int):
	foxlab_remembered_weapons[player_index].clear()
	foxlab_remembered_items[player_index].clear()

func foxlab_forget_item(player_index: int):
	if not foxlab_remembered_items[player_index].empty():
		var effects = RunData.get_player_effects(player_index)
		var previous_loot_next_wave = effects[Keys.extra_loot_aliens_next_wave_hash]
		var previous_hp_next_wave = effects[Keys.hp_start_next_wave_hash]
		for item in foxlab_remembered_items[player_index]:
			if item in players_data[player_index].items:
				# DebugService.log_data("item num: %d/%d" % [ get_nb_item(item.my_id_hash, player_index), players_data[player_index].items.size() ])
				remove_item(item, player_index)
				# DebugService.log_data("remove %s, curse: %s, item num: %d/%d" % [ item.my_id, str(item.is_cursed), get_nb_item(item.my_id_hash, player_index), players_data[player_index].items.size() ])
		#被临时道具顶掉了角色外观，恢复回来
		if not ProgressData.settings.no_item_appearance:
			add_item_displayed(get_player_character(player_index), player_index)
		foxlab_remembered_items[player_index].clear()
		# 数字型临时属性，回收的时候会让属性减少，实际上在出发的时候就被Main清空了
		# 数组型由于不存在那个key了，所以回收的时候无事发生
		effects[Keys.extra_loot_aliens_next_wave_hash] = previous_loot_next_wave
		effects[Keys.hp_start_next_wave_hash] =  previous_hp_next_wave

	if not foxlab_remembered_weapons[player_index].empty():
		for weapon in get_player_weapons_ref(player_index):
			Utils.reset_stat_cache(player_index)
			var effects: Array = weapon.effects
			# 倒着找，只找最后一次记忆的效果段 （孟婆记忆面具，面具换掉孟婆从而保留的效果，不会失去）
			for i in range(effects.size(), 0, -1):
				if effects[i - 1].custom_key_hash == Utils.foxlab_remembered_effect_begin_hash:
					while effects.size() >= i:
						effects.pop_back().unapply(player_index)
					break
		foxlab_remembered_weapons[player_index].clear()
		LinkedStats.reset_player(player_index)

func foxlab_adjust_weapon_effect(effect: Effect, weapon: WeaponData):
	if effect is WeaponStackEffect: # stick
		effect.weapon_stacked_name = weapon.name
		effect.weapon_stacked_id = weapon.weapon_id
		effect.weapon_stacked_id_hash = weapon.weapon_id_hash
	elif effect is PercentDamageEffect: # lute etc
		effect.source_id = weapon.weapon_id
		effect.source_id_hash = weapon.weapon_id_hash
	elif effect.custom_key == "yztato_destory_weapons":
		effect.key = weapon.weapon_id #保留的是武器大名，不是带等级的my_id
		effect.key_hash = weapon.weapon_id_hash #保留的是武器大名，不是带等级的my_id

func foxlab_get_effects_from_another_weapon(weapon: WeaponData, weapon_for_effect: WeaponData, is_const_effect: bool) -> Array:
	var begin_effect = NullEffect.new()
	begin_effect.key = " %s %s" % [tr(weapon_for_effect.name), ItemService.get_tier_number(weapon_for_effect.tier)]
	begin_effect.text_key = "EFFECT_FOXLAB_WEAPON_TEXT_CURSED" if weapon_for_effect.is_cursed else "EFFECT_FOXLAB_WEAPON_TEXT"
	if is_const_effect:
		begin_effect.custom_key = "foxlab_const_effect_begin"
		begin_effect.custom_key_hash = Utils.foxlab_const_effect_begin_hash
	var new_effects := [begin_effect]
	for effect in weapon_for_effect.effects:
		effect = effect.duplicate()
		new_effects.append(effect)
		foxlab_adjust_weapon_effect(effect, weapon)
	if is_const_effect:
		var end_effect = NullEffect.new()
		end_effect.text_key = "[EMPTY]"
		end_effect.custom_key = "foxlab_const_effect_end"
		end_effect.custom_key_hash = Utils.foxlab_const_effect_end_hash
		new_effects.append(end_effect)
	return new_effects

func get_foxlab_buddhas_hand_meta(player_index: int):
	return players_data[player_index].foxlab_buddhas_hand_meta

func get_foxlab_mask_meta(player_index: int):
	return players_data[player_index].foxlab_mask_meta

func foxlab_process_gold(value: int, player_index: int):
	if value > 0:
		if RunData.get_player_effect_bool(Utils.foxlab_add_xp_on_getting_gold_hash, player_index):
			if wave_in_progress:
				add_xp(value, player_index)
			else:
				RunData.get_player_effects(player_index)[Utils.foxlab_pending_xp_hash] += value
	elif value < 0:
		if RunData.get_player_effect_bool(Utils.foxlab_lost_hp_on_losing_gold_hash, player_index):
			RunData.get_player_effects(player_index)[Utils.foxlab_lost_hp_hash] -= value
			if wave_in_progress:
				emit_signal("healing_effect", 0, player_index, Keys.empty_hash)

###### 扩展 ######
func _reset_per_wave_properties() -> void :
	._reset_per_wave_properties()
	foxlab_is_midnight = [false, false, false, false]
	foxlab_scapegoat_no_hurt = [[], [], [], []]

func add_gold(value: int, player_index: int) -> void :
	.add_gold(value, player_index)
	foxlab_process_gold(value, player_index)

func remove_gold(value: int, player_index: int) -> void :
	var player_data = players_data[player_index]
	if foxlab_is_midnight[player_index]:
		player_data.gold = (player_data.gold - value) as int
		emit_signal("gold_changed", player_data.gold, player_index)
	else:
		.remove_gold(value, player_index)
	foxlab_process_gold(-value, player_index)

func on_wave_start(timer: WaveTimer) -> void :
	.on_wave_start(timer)
	var effects = get_player_effects(0)
	effects[Utils.foxlab_shop_effects_checked_hash] = 0
	for i in range(get_player_count()):
		get_player_effects(i)[Utils.foxlab_buy_item_increase_tier_current_hash] = 0
	DebugService.log_data("foxlab_shop_effects_checked: set false")
	#公牛等没有武器的角色，不会执行add_starting_items_and_weapons
	effects[Utils.foxlab_wave_started_hash] = 1
	ItemService.foxlab_add_pet_structure_stats()

func get_next_level_xp_needed(player_index) -> float:
	var xp_needed = .get_next_level_xp_needed(player_index)
	if xp_needed > 0:
		return xp_needed
	# 防止需要的经验不是正数，导致无限升级爆栈
	var xp_needed_effect = max(get_player_effect(Utils.next_level_xp_needed_hash, player_index), -99)
	return get_xp_needed(get_player_level(player_index) + 1) * (1.0 + xp_needed_effect / 100.0)

func foxlab_item_recycle_test():
	var failed_items = []
	for item in ItemService.items + ItemService.characters:
		if item.my_id in failed_items:
			continue
		print("test ", item.my_id)
		add_item(item, 0)
		remove_item(item, 0)
		if not item.can_be_looted or item is CharacterData:
			continue
		var new_item = ItemService.apply_item_effect_modifications(item, 0)
		add_item(new_item, 0)
		remove_item(new_item, 0)
	return true

func add_starting_items_and_weapons() -> void :
#	assert(foxlab_item_recycle_test())
	var effects = get_player_effects(0)
	.add_starting_items_and_weapons()
	effects[Utils.foxlab_wave_started_hash] = 1
	foxlab_remembered_items = [ [], [], [], [] ]
	foxlab_remembered_weapons = [ [], [], [], [] ]
	foxlab_shop_items = [ [], [], [], [] ]
	ItemService.foxlab_add_pet_structure_stats()

func is_wave_started() -> bool:
	return get_player_effect_bool(Utils.foxlab_wave_started_hash, 0)

var FOXLAB_ELITE_CHARS = [Keys.generate_hash("character_foxlab_war_master"),
						Keys.generate_hash("character_foxlab_survivor"),
						Keys.generate_hash("character_foxlab_kidnapper"),
						Keys.generate_hash("character_foxlab_wormhole_traveler"),
						Keys.generate_hash("character_foxlab_venom"),
						Keys.generate_hash("character_foxlab_bounty_hunter")]
var FOXLAB_HORDE_CHARS = [Keys.generate_hash("character_foxlab_pufferfish")]

func init_elites_spawn(base_wave: int = 10, horde_chance: float = 0.4) -> void :
	for player_index in get_player_count():
		var current_character = get_player_character(player_index)
		if current_character != null:
			if current_character.my_id_hash in FOXLAB_ELITE_CHARS:
				horde_chance = 0.0
			elif get_player_count() == 1 and current_character.my_id_hash in FOXLAB_HORDE_CHARS:
				horde_chance = 1.0
	.init_elites_spawn(base_wave, horde_chance)

# 初始携带就能增加统计数据的角色/道具（如面具、佛手、无面）
func revert_all_selections() -> void :
	.revert_all_selections()
	for player_index in range(get_player_count()):
		tracked_item_effects[player_index] = init_tracked_effects()

func get_player_appearances(player_index: int) -> Array:
	if players_data[player_index].appearances.empty():
		for item in get_player_items_ref(player_index):
			add_item_displayed(item, player_index)
	return .get_player_appearances(player_index)

func get_player_current_health(player_index: int) -> int:
	return .get_player_current_health(player_index) - RunData.get_player_effect(Utils.foxlab_lost_hp_hash, player_index)

func get_player_sets(player_index: int) -> Array:
	var sets = .get_player_sets(player_index)
	# 开局选择道具而不是武器
	if sets.empty():
		var selected_item = players_data[player_index].selected_item
		if selected_item != null:
			# 道具是构筑物，视为工具（程序员、傀儡忍者、技术宅等）
			if selected_item.is_structure_item():
				sets.append(Keys.generate_hash("set_tool"))
			# 其他，视为枪械（架构师）
			else:
				sets.append(Keys.generate_hash("set_gun"))
	return sets