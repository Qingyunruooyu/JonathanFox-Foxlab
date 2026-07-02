extends "res://ui/menus/shop/base_shop.gd"

var foxlab_mask_success_sound = preload("res://entities/units/enemies/pursuer/sci-fi_code_fail_13.wav")
var foxlab_current_shop_item_pos = [[null, null], [null, null], [null, null], [null, null]]
var foxlab_pinned_weapon_element = [null, null, null, null]
var foxlab_uncursed_weapon_element = [null, null, null, null]

func foxlab_switch_turret_item(old_level: int, new_level: int, p_player_index: int) -> void :
	var player_items_ref = RunData.get_player_items_ref(p_player_index)

	for i in range(player_items_ref.size() - 1, -1, -1):
		var item = player_items_ref[i]
		if item.my_id_hash == Keys.item_builder_turret_n_hash[old_level]:
			RunData.foxlab_remove_item_by_index(i, p_player_index)
			break

	var new_item = ItemService.foxlab_get_builder_turret_at_level(new_level, p_player_index)
	RunData.add_item(new_item, p_player_index)

func foxlab_modify_weapon_upgrade(weapon: WeaponData):
	assert(weapon.upgrades_into != null)
	var has_extra_effects = false
	for effect in weapon.effects:
		if effect.custom_key_hash == Utils.foxlab_const_effect_begin_hash:
			has_extra_effects = true
			break
	if not has_extra_effects:
		return
	var upgrades_into = weapon.upgrades_into.duplicate()
	var new_effects = upgrades_into.effects.duplicate()
	var is_in_extra_range = false
	for effect in weapon.effects:
		if effect.custom_key_hash == Utils.foxlab_const_effect_begin_hash:
			is_in_extra_range = true
		if is_in_extra_range:
			new_effects.push_back(effect)
		if effect.custom_key_hash == Utils.foxlab_const_effect_end_hash:
			is_in_extra_range = false
	upgrades_into.effects = new_effects

	if weapon.type ==  WeaponData.Type.MELEE and \
		weapon.stats.deal_dmg_on_return == true and\
		upgrades_into.stats.deal_dmg_on_return == false:
		var melee_stats = upgrades_into.stats.duplicate()
		melee_stats.deal_dmg_on_return = true
		upgrades_into.stats = melee_stats

	weapon.upgrades_into = upgrades_into


#面具弹出相关
func _on_foxlab_sec_char_changed(new_characters, player_index):
	var pos = foxlab_current_shop_item_pos[player_index]
	SoundManager.play(foxlab_mask_success_sound, - 2, 0.2, true)
	if pos[0] == null or pos[1] == null:
		return
	var offset = Vector2(-30, 30)
	var popup_pos = pos[0]
	var direction: Vector2
	var color = Color(ProgressData.settings.color_positive)
	if RunData.is_coop_run:
		popup_pos.x += 35
		direction = Vector2(0, - 30)
	else:
		popup_pos.x += pos[1]
		direction = Vector2(25, - 100)
	for character in new_characters:
		var icon = character.icon
		var icon_scale = Utils.foxlab_fit_item_icon_scale(character)
		_floating_text_manager.display("+1", popup_pos, color, icon, _floating_text_manager.duration * 2, true, direction, false, icon_scale)
		popup_pos -= offset

func _on_foxlab_item_gear_changed(player_index):
	var player_gear_container = _get_gear_container(player_index)
	var items = RunData.get_player_items(player_index)
	player_gear_container.call_deferred("set_items_data", items)

func _on_foxlab_weapon_gear_changed(player_index):
	var player_gear_container = _get_gear_container(player_index)
	var weapons = RunData.get_player_weapons(player_index)
	player_gear_container.call_deferred("set_weapons_data", weapons)

func _on_foxlab_item_pin_button_pressed(weapon_data: WeaponData, player_index: int) -> void :
	var inventory = _get_gear_container(player_index).weapons_container._elements
	var target_element = null
	for element in inventory.get_children():
		if target_element == null and element.item == weapon_data:
			target_element = element
			element._baned.modulate = Color(ProgressData.settings.color_negative)
			element._baned.modulate.a = 0.3
			element._baned.visible = true
		else:
			element._baned.visible = false

	if target_element:
		foxlab_pinned_weapon_element[player_index] = target_element
	_on_item_cancel_button_pressed(weapon_data, player_index)

func foxlab_pin_weapon(weapon_data: WeaponData, player_index: int) -> void :
	var element = foxlab_pinned_weapon_element[player_index]
	if element:
		# 名字相同但是不是同一把武器
		if weapon_data.my_id_hash == element.item.my_id_hash and not(weapon_data == element.item):
			var inventory = _get_gear_container(player_index).weapons_container._elements
			# 原版合成逻辑：遍历到第一个诅咒状态不同的武器，break掉，开始合成
			# 否则找最后一个同名武器
			if weapon_data.is_cursed and element.item.is_cursed:
				var target_weapon = element.item if element.item.curse_factor < weapon_data.curse_factor else weapon_data
				target_weapon.is_cursed = false
				foxlab_uncursed_weapon_element[player_index] = target_weapon
			var target_index = 0 if weapon_data.is_cursed != element.item.is_cursed else inventory.get_child_count() - 1
			inventory.move_child(element, target_index)
		element._baned.visible = false
		foxlab_pinned_weapon_element[player_index] = null

######### 扩展 #########
func _ready() -> void :
	if not RunData.is_connected("foxlab_sec_char_changed", self, "_on_foxlab_sec_char_changed"):
		var _err = RunData.connect("foxlab_sec_char_changed", self, "_on_foxlab_sec_char_changed")
	if not RunData.is_connected("foxlab_item_gear_changed", self, "_on_foxlab_item_gear_changed"):
		var _err = RunData.connect("foxlab_item_gear_changed", self, "_on_foxlab_item_gear_changed")
	if not RunData.is_connected("foxlab_weapon_gear_changed", self, "_on_foxlab_weapon_gear_changed"):
		var _err = RunData.connect("foxlab_weapon_gear_changed", self, "_on_foxlab_weapon_gear_changed")

	for player_index in RunData.get_player_count():
		# 新按钮连接信号
		var item_popup = _get_item_popup(player_index)
		if not item_popup.is_connected("foxlab_item_pin_button_pressed", self, "_on_foxlab_item_pin_button_pressed"):
			var _err = item_popup.connect("foxlab_item_pin_button_pressed", self, "_on_foxlab_item_pin_button_pressed", [player_index])

	if RunData.get_player_effect_bool(Utils.foxlab_shop_effects_checked_hash, 0):
		DebugService.log_data("foxlab_shop_effects_checked: is true")
		return
	DebugService.log_data("foxlab_shop_effects_checked: is false")
	ItemService.foxlab_just_enter_shop = [true, true, true, true]
	for player_index in RunData.get_player_count():
		# 建造者的炮塔更新
		var struct_range = RunData.get_player_effect(Keys.structure_range_hash, player_index)
		var new_level = BuilderTurret.get_level(struct_range)
		var update_item = false
		for level in range(new_level):
			var number = RunData.get_nb_item(Keys.item_builder_turret_n_hash[level], player_index)
			for _i in range(number):
				foxlab_switch_turret_item(level, new_level, player_index)
				update_item = true
		if update_item:
			_on_foxlab_item_gear_changed(player_index)

		# 保留随机一把武器
		if RunData.get_player_effect_bool(Utils.foxlab_keep_random_weapon_hash, player_index) and RunData.get_player_weapons_ref(player_index).size() > 0:
			var weapons = RunData.get_player_weapons(player_index)
			var weapon_idx_to_keep = Utils.randi_range(0, weapons.size() - 1)
			var weapon_to_keep:WeaponData = weapons[weapon_idx_to_keep]
			for i in range(weapons.size()):
				if i != weapon_idx_to_keep:
					RunData.remove_weapon(weapons[i], player_index)
			_on_foxlab_weapon_gear_changed(player_index)
			var recycling_value = ItemService.get_recycling_value(RunData.current_wave, weapon_to_keep.value, player_index, true, false)
			RunData.add_gold(recycling_value, player_index)
			_update_stats(player_index)
			RunData.add_tracked_value(player_index, Utils.character_foxlab_staff_officer_hash, recycling_value)

	RunData.get_player_effects(0)[Utils.foxlab_shop_effects_checked_hash] = 1
	DebugService.log_data("foxlab_shop_effects_checked: set true")

func _combine_weapon(weapon_data: WeaponData, player_index: int, is_upgrade: bool) -> void :
	foxlab_pin_weapon(weapon_data, player_index)
	foxlab_modify_weapon_upgrade(weapon_data)
	._combine_weapon(weapon_data, player_index, is_upgrade)
	if foxlab_uncursed_weapon_element[player_index]:
		foxlab_uncursed_weapon_element[player_index].is_cursed = true
		foxlab_uncursed_weapon_element[player_index] = null

func on_shop_item_stolen(shop_item: ShopItem, player_index: int) -> void :
	if _item_steals[player_index] > 0:
		var extra_enemies = RunData.get_player_effect(Utils.foxlab_item_steal_warmhole_spawn_hash, player_index)
		if extra_enemies > 0:
			var effect_items: Array = RunData.get_player_effects(player_index)[Keys.stats_next_wave_hash]
			var applied = false
			for existing_item in effect_items:
				if existing_item[0] == Utils.foxlab_extra_enemies_hash:
					existing_item[1] += extra_enemies
					applied = true
					break
			if not applied:
				effect_items.push_back([Utils.foxlab_extra_enemies_hash, extra_enemies])
	.on_shop_item_stolen(shop_item, player_index)

func on_shop_item_bought(shop_item: ShopItem, player_index: int) -> void :
	foxlab_current_shop_item_pos[player_index][0] = shop_item._button.rect_global_position
	foxlab_current_shop_item_pos[player_index][1] = shop_item._button.rect_size.x / 2.0

	# 同名但是诅咒系数不同的道具，如果不是从左往右买，就会错位。比如商店一个诅咒镜子和一个普通镜子，如果买普通镜子，会把排前面的诅咒镜子干掉
	var items_pull_back = []
	for item in _shop_items[player_index]:
		if item[0].my_id_hash == shop_item.item_data.my_id_hash and item[0].curse_factor != shop_item.item_data.curse_factor:
			items_pull_back.append(item)
	for item in items_pull_back:
		_shop_items[player_index].erase(item)
		_shop_items[player_index].append(item)

	.on_shop_item_bought(shop_item, player_index)
	var item_data = shop_item.item_data
	var has_hourglass = item_data.my_id_hash == Keys.item_hourglass_hash

	if shop_item.value != 0 and RunData.get_player_effect_bool(Utils.foxlab_buy_item_increase_tier_hash, player_index):
		if item_data.tier <= Tier.COMMON:
			RunData.get_player_effects(player_index)[Utils.foxlab_buy_item_increase_tier_current_hash] -= 1
		elif item_data.tier >= Tier.LEGENDARY:
			RunData.get_player_effects(player_index)[Utils.foxlab_buy_item_increase_tier_current_hash] += 1

	if shop_item.value != 0 and RunData.get_player_effect_bool(Utils.foxlab_bonus_item_on_bought_hash, player_index):
		var items = [ ]
		var player_gear_container = _get_gear_container(player_index)
		var args = ItemService.GetRandItemForWaveArgs.new()
		var owned_items: Array = RunData.get_player_items(player_index)
		for shop_item_arr in get_player_shop_items(player_index):
			if shop_item_arr[0] is ItemData:
				owned_items.push_back(shop_item_arr[0])
		args.owned_and_shop_items = owned_items
		# 不可逆的道具排除掉
		args.excluded_items = [[ItemService.get_item_from_id(Keys.item_axolotl_hash), 0], [ItemService.get_item_from_id(Utils.item_foxlab_mask_hash), 0]]
		for i in RunData.get_player_effect(Utils.foxlab_bonus_item_on_bought_hash, player_index):
			var item = ItemService._get_rand_item_for_wave(RunData.current_wave, player_index, ItemService.TierData.ITEMS, args)
			items.append(item)
			RunData.add_item(item, player_index)
			player_gear_container.items_container._elements.add_element(item, true)
			args.owned_and_shop_items.append(item)
			if item.my_id_hash == Keys.item_hourglass_hash:
				has_hourglass = true
		_on_foxlab_sec_char_changed(items, player_index)

		_update_stats(player_index)
		_get_shop_items_container(player_index).reload_shop_items()

	if has_hourglass:
		update_go_next_button_text()

	if shop_item.value != 0:
		RunData.get_player_effects(player_index)[Utils.foxlab_price_digit_hash] = (shop_item.value % 10) as int

	if item_data.get_category() == Category.WEAPON and\
		item_data.tier >= RunData.get_player_effect(Utils.foxlab_bonus_reroll_weapon_tier_hash, player_index):
		_has_bonus_free_reroll[player_index] = true
		set_reroll_button_price(player_index)

func buy_item(item_data: ItemData, player_index: int) -> void :
	var prev_weapon_slot = RunData.get_player_effect(Keys.weapon_slot_hash, player_index)
	var prev_hourglass = RunData.get_player_effect(Keys.item_hourglass_hash, player_index)

	.buy_item(item_data, player_index)

	if (RunData.get_player_effect(Keys.weapon_slot_hash, player_index) != prev_weapon_slot):
		_on_foxlab_weapon_gear_changed(player_index)

	if RunData.get_player_effect(Keys.item_hourglass_hash, player_index) != prev_hourglass:
		update_go_next_button_text()

func _on_RerollButton_pressed(player_index: int) -> void :
	ItemService.foxlab_just_enter_shop[player_index] = false

	var player_locked_items = RunData.get_player_locked_shop_items(player_index)
	# 买完了但还是全锁：失去锁定但是之前锁定过物品的时候会出现
	if player_locked_items.size() >= ItemService.NB_SHOP_ITEMS:
		var remove_random_locked = true
		for item in _get_shop_items_container(player_index)._shop_items:
			if item.active:
				remove_random_locked = false
				break
		if remove_random_locked:
			RunData.unlock_player_shop_item(Utils.get_rand_element(player_locked_items)[0], player_index)

	var prev_weapon_slot = RunData.get_player_effect(Keys.weapon_slot_hash, player_index)

	var player_effects = RunData.get_player_effects(player_index)
	var effects:Array = player_effects[Utils.foxlab_force_remove_on_reroll_hash]
	var update_item = false
	var non_exist_num = 0;
	while not effects.size() == non_exist_num:
		var item_id = effects[non_exist_num][0]
		var item = RunData.get_player_item(item_id, player_index)
		if item != null:
			RunData.remove_item(item, player_index)
			update_item = true
		else:
			DebugService.log_data("item not exist: " + Keys.hash_to_string[item_id])
			non_exist_num += 1

	._on_RerollButton_pressed(player_index)
	player_effects[Utils.foxlab_buy_item_increase_tier_current_hash] = 0

	var lose_item_num = RunData.get_player_effect(Utils.foxlab_lose_item_on_reroll_hash, player_index)
	if lose_item_num > 0:
		var items_ref = RunData.get_player_items_ref(player_index)
		var has_hourglass = false
		for i in range(items_ref.size() - 1, -1, -1):
			var item_data = items_ref[i]
			if item_data.can_be_looted and not item_data is CharacterData:
				if item_data.my_id_hash == Keys.item_hourglass_hash:
					has_hourglass = true
				update_item = true
				RunData.foxlab_remove_item_by_index(i, player_index)
				var reroll_button: = _get_reroll_button(player_index)
				var pos = reroll_button.rect_global_position
				if not RunData.is_coop_run:
					pos.y += reroll_button.rect_size.y / 2
				else:
					pos.x += reroll_button.rect_size.x - 80
				_floating_text_manager.display_icon(-1, item_data.icon, _floating_text_manager.stat_pos_sounds, _floating_text_manager.stat_neg_sounds, pos, _floating_text_manager.direction)
				lose_item_num -= 1
				if lose_item_num <= 0:
					break
		_update_stats(player_index)
		if has_hourglass:
			update_go_next_button_text()

	if RunData.get_player_effect(Keys.weapon_slot_hash, player_index) != prev_weapon_slot:
		_on_foxlab_weapon_gear_changed(player_index)

	if update_item:
		_on_foxlab_item_gear_changed(player_index)

func _on_GoButton_pressed(player_index: int) -> void :
	if RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
		RunData.foxlab_shop_items[player_index] = _get_shop_items_container(player_index)._shop_items
	._on_GoButton_pressed(player_index)

func _on_tree_exited() -> void :
	._on_tree_exited()

	var wave_reset_count: = 0
	for player_index in RunData.get_player_count():
		foxlab_current_shop_item_pos[player_index] = [null, null]
		RunData.foxlab_forget_item_entry(player_index)
		if not RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
			continue
		for item in RunData.foxlab_shop_items[player_index]:
			if is_instance_valid(item) and item.active and not item.locked:
				RunData.foxlab_remember_item(item.item_data, player_index)
		for item in RunData.locked_shop_items[player_index]:
			RunData.foxlab_remember_item(item[0], player_index)
		RunData.foxlab_modify_weapon(player_index)
		RunData.foxlab_update_remembered_item(player_index)

		var effects = RunData.get_player_effects(player_index)
		var hourglass_count = effects[Keys.item_hourglass_hash]
		if hourglass_count > 0:
			var source_item = RunData.get_player_item(Keys.item_hourglass_hash, player_index)
			if source_item:
				wave_reset_count += hourglass_count
				RunData.remove_item(source_item, player_index)

	RunData.current_wave -= wave_reset_count

func _on_shop_item_focused(shop_item: ShopItem, player_index: int) -> void :
	._on_shop_item_focused(shop_item, player_index)
	if not RunData.is_coop_run and shop_item.active and UIService.current_device != CoopService.PlayerType.KEYBOARD_AND_MOUSE:
		show_shop_item_tags(shop_item)

func _on_shop_item_unfocused(shop_item: ShopItem, player_index: int) -> void :
	._on_shop_item_unfocused(shop_item, player_index)
	hide_tags(shop_item)

func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void :
	.fill_shop_items(player_locked_items, player_index, just_entered_shop)

	if RunData.get_player_effect_bool(Utils.foxlab_curse_item_by_price_hash, player_index):
		var pos = RunData.get_player_effect(Utils.foxlab_price_digit_hash, player_index) - 1
		if pos >= 0 and pos < get_player_shop_items(player_index).size():
			var item = get_player_shop_items(player_index)[pos]
			for dlc_id in RunData.enabled_dlcs:
				var dlc_data = ProgressData.get_dlc_data(dlc_id)
				if dlc_data and dlc_data.has_method("curse_item"):
					item[0] = dlc_data.curse_item(item[0], player_index)
	RunData.get_player_effects(player_index)[Utils.foxlab_price_digit_hash] = 0
