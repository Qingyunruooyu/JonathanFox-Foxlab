extends "res://ui/menus/shop/base_shop.gd"

var foxlab_mask_success_sound = preload("res://entities/units/enemies/crash_zone/basic/pursuer/sci-fi_code_fail_13.wav")
var foxlab_current_shop_item_pos = [[null, null], [null, null], [null, null], [null, null]]
var foxlab_pinned_weapon_element = [null, null, null, null]
# 临时去掉风味标记的武器 [WeaponData, String flag]，合成后恢复
var foxlab_temp_deflavored = [null, null, null, null]
var foxlab_bonus_item = [[], [], [], []]

func foxlab_switch_turret_item(old_level: int, new_level: int, p_player_index: int) -> void :
	var player_items_ref = RunData.get_player_items_ref(p_player_index)

	for i in range(player_items_ref.size() - 1, -1, -1):
		var item = player_items_ref[i]
		if item.my_id_hash == Keys.item_builder_turret_n_hash[old_level]:
			RunData.foxlab_remove_item_by_index(i, p_player_index, false)
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


#面具/道具弹出相关
func _on_foxlab_item_added(new_items, player_index):
	var pos = foxlab_current_shop_item_pos[player_index]
	SoundManager.play(foxlab_mask_success_sound, - 2, 0.2, true)
	if pos[0] == null or pos[1] == null:
		return
	var popup_pos = pos[0]
	var direction: Vector2
	if RunData.is_coop_run:
		popup_pos.x += 35
		direction = Vector2(0, - 30)
	else:
		popup_pos.x += pos[1]
		direction = Vector2(25, - 100)
	foxlab_display_items_added(new_items, popup_pos, direction, false)

func foxlab_display_items_added(items: Array, popup_pos: Vector2, direction: Vector2, play_sound: bool = true) -> void:
	if play_sound:
		SoundManager.play(foxlab_mask_success_sound, -2, 0.2, true)
	var offset = Vector2(-30, 30)
	var color = Color(ProgressData.settings.color_positive)
	for item in items:
		var icon = item.icon
		var icon_scale = Utils.foxlab_fit_item_icon_scale(item.icon)
		_floating_text_manager.display("+1", popup_pos, Utils.CURSE_COLOR if item.is_cursed else (Utils.get_evolution_color(1) if item.is_meca else color), icon, _floating_text_manager.duration * 2, true, direction, false, icon_scale)
		popup_pos -= offset

# 必须传 _ref（实时数组）而非 get_player_items() 的拷贝：deferred 到帧末才执行，
# 若传快照拷贝，同帧稍后 foxlab_add_bonus_items 等同步增量更新会被旧快照的全量重建覆盖
func _on_foxlab_item_gear_changed(player_index):
	var player_gear_container = _get_gear_container(player_index)
	var items = RunData.get_player_items_ref(player_index)
	player_gear_container.call_deferred("set_items_data", items)

func _on_foxlab_gear_recovered(item_data, player_index):
	var rect = _get_gear_container(player_index).get_global_rect()
	var popup_pos = rect.position + Vector2(rect.size.x * 0.5, 20) + Vector2(Utils.randi_range(-15, 15), 0)
	foxlab_display_items_added([item_data], popup_pos, Vector2(0, -30))

func _on_foxlab_weapon_gear_changed(player_index):
	var player_gear_container = _get_gear_container(player_index)
	var weapons = RunData.get_player_weapons_ref(player_index)
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
			# 原版 get_combine_candidates 按 players_data.weapons 数据数组遍历收集候选，
			# 给"与商店武器异风味"的 +2 分；同分时取数据数组中先出现的。
			# 在数据数组里把 pinned 挪到最前，确保同分时最先命中。
			var shop_flavor = ItemService.get_flavor(weapon_data)
			var pinned_flavor = ItemService.get_flavor(element.item)
			if shop_flavor != ItemFlavor.PLAIN and shop_flavor == pinned_flavor:
				# 同风味对（双诅咒/双机械化/双变异）：临时去掉一侧标记让它变 PLAIN 得 +2 分
				var flag = "is_cursed" if shop_flavor == ItemFlavor.CURSED \
					else ("is_meca" if shop_flavor == ItemFlavor.MECA else "is_mutant")
				var target_weapon = element.item
				if shop_flavor == ItemFlavor.CURSED:
					# 双诅咒：去系数低的
					target_weapon = element.item if element.item.curse_factor < weapon_data.curse_factor else weapon_data
				target_weapon.set(flag, false)
				foxlab_temp_deflavored[player_index] = [target_weapon, flag]
			# 数据数组重排：pinned 的武器挪到最前（get_player_weapons_ref 遍历最先命中）
			var weapons = RunData.get_player_weapons_ref(player_index)
			var pinned_idx = weapons.find(element.item)
			if pinned_idx > 0:
				weapons.remove(pinned_idx)
				weapons.insert(0, element.item)
		element._baned.visible = false
		foxlab_pinned_weapon_element[player_index] = null

func foxlab_add_bonus_items(player_index: int):
	var items = foxlab_bonus_item[player_index]
	if not items.empty():
		var player_gear_container = _get_gear_container(player_index)
		for bonus_item in items:
			RunData.add_item(bonus_item, player_index)
			player_gear_container.items_container._elements.add_element(bonus_item, true)
		_on_foxlab_item_added(items, player_index)
		items.clear()

func foxlab_remember_shop_items(player_index: int) -> void:
	RunData.foxlab_forget_item_entry(player_index)
	if not RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
		return
	for item in RunData.locked_shop_items[player_index]:
		RunData.foxlab_remember_item(item[0], player_index)
	for item in RunData.foxlab_shop_items[player_index]:
		if is_instance_valid(item) and item.active and not item.locked:
			RunData.foxlab_remember_item(item.item_data, player_index)
	RunData.foxlab_modify_weapon(player_index)
	RunData.foxlab_update_remembered_item(player_index)

# 原版 on_shop_item_bought/on_shop_item_banned 按 my_id 擦除商店元组列表里的首个匹配，
# 这里把实际被操作的那个元组挪到同名组首位，保证原版擦中的就是它；无重名时它本来就在首位
func foxlab_move_shop_tuple_to_front(shop_item, player_index: int) -> void :
	var player_shop_items = _shop_items[player_index]
	var target = [shop_item.item_data, shop_item.wave_value]
	var first_same_name = -1
	var precise = -1
	for i in player_shop_items.size():
		if player_shop_items[i][0].my_id_hash != shop_item.item_data.my_id_hash:
			continue
		if first_same_name == -1:
			first_same_name = i
		if Utils.foxlab_same_shop_tuple(player_shop_items[i], target):
			precise = i
			break
	if precise > first_same_name:
		var tuple = player_shop_items[precise]
		player_shop_items.remove(precise)
		player_shop_items.insert(first_same_name, tuple)

######### 扩展 #########
func _ready() -> void :
	if not RunData.is_connected("foxlab_sec_char_changed", self, "_on_foxlab_item_added"):
		var _err = RunData.connect("foxlab_sec_char_changed", self, "_on_foxlab_item_added")
	if not RunData.is_connected("foxlab_item_gear_changed", self, "_on_foxlab_item_gear_changed"):
		var _err = RunData.connect("foxlab_item_gear_changed", self, "_on_foxlab_item_gear_changed")
	if not RunData.is_connected("foxlab_weapon_gear_changed", self, "_on_foxlab_weapon_gear_changed"):
		var _err = RunData.connect("foxlab_weapon_gear_changed", self, "_on_foxlab_weapon_gear_changed")
	if not RunData.is_connected("foxlab_gear_recovered", self, "_on_foxlab_gear_recovered"):
		var _err = RunData.connect("foxlab_gear_recovered", self, "_on_foxlab_gear_recovered")

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
	# 只有进商店才会重置随机敌人，和糖果袋出随机精英一样
	RunData.foxlab_is_horde_wave = null
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
	if foxlab_temp_deflavored[player_index]:
		var entry = foxlab_temp_deflavored[player_index]
		entry[0].set(entry[1], true)
		foxlab_temp_deflavored[player_index] = null

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

	# 同名不同数据的商品（如诅咒/普通），原版按 my_id 擦除首个匹配会错位，
	# 把实际购买的元组挪到同名组首位，保证原版擦中的就是它
	foxlab_move_shop_tuple_to_front(shop_item, player_index)

	# 不知道为啥买了之后，shop_item.value恢复原价了，这里是为了区分是购买还是窃取
	var shop_value = shop_item.value
	var item_data = shop_item.item_data

	if shop_value != 0 and RunData.get_player_effect_bool(Utils.foxlab_bonus_item_on_bought_hash, player_index):
		var items = foxlab_bonus_item[player_index]
		items.clear()
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
			args.owned_and_shop_items.append(item)

	.on_shop_item_bought(shop_item, player_index)

	if shop_value != 0 and RunData.get_player_effect_bool(Utils.foxlab_buy_item_increase_tier_hash, player_index):
		if item_data.tier <= Tier.COMMON:
			RunData.get_player_effects(player_index)[Utils.foxlab_buy_item_increase_tier_current_hash] -= 1
		elif item_data.tier >= Tier.LEGENDARY:
			RunData.get_player_effects(player_index)[Utils.foxlab_buy_item_increase_tier_current_hash] += 1

	if shop_value != 0:
		RunData.get_player_effects(player_index)[Utils.foxlab_price_digit_hash] = (shop_value % 10) as int

	if item_data.get_category() == Category.WEAPON and\
		item_data.tier >= RunData.get_player_effect(Utils.foxlab_bonus_reroll_weapon_tier_hash, player_index):
		_has_bonus_free_reroll[player_index] = true
		set_reroll_button_price(player_index)

func on_shop_item_banned(shop_item, player_index: int) -> void :
	foxlab_move_shop_tuple_to_front(shop_item, player_index)
	.on_shop_item_banned(shop_item, player_index)

func buy_weapon(item_data: WeaponData, player_index: int) -> void :
	.buy_weapon(item_data, player_index)

	foxlab_add_bonus_items(player_index)

func buy_item(item_data: ItemData, player_index: int) -> void :
	var prev_weapon_slot = RunData.get_player_effect(Keys.weapon_slot_hash, player_index)
	var prev_hourglass = RunData.get_player_effect(Keys.item_hourglass_hash, player_index)

	.buy_item(item_data, player_index)

	foxlab_add_bonus_items(player_index)

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

	for player_index in RunData.get_player_count():
		foxlab_current_shop_item_pos[player_index] = [null, null]
		foxlab_remember_shop_items(player_index)
		if RunData.get_player_effect_bool(Utils.foxlab_lose_item_on_reroll_hash, player_index) and\
			not ProgressData.settings.no_item_appearance:
				RunData.add_item_displayed(RunData.get_player_character(player_index), player_index)

	# 孟婆记忆能把商店沙漏、探测仪加入背包
	var wave_reset_count = RunData.get_wave_reset_count()
	if wave_reset_count > 0:
		for player_index in RunData.get_player_count():
			var source_item = RunData.get_player_item(Keys.item_hourglass_hash, player_index)
			if source_item:
				RunData.remove_item(source_item, player_index)
		RunData.current_wave -= wave_reset_count

	for player_index in RunData.get_player_count():
		for item in RunData.foxlab_remembered_items[player_index]:
			if item.my_id_hash != Keys.item_lifeform_scanner_hash:
				continue
			if not RunData.switch_next_elite_to_horde(RunData.current_wave):
				break
			RunData.remove_item(item, player_index)

func _on_shop_item_focused(shop_item: ShopItem, player_index: int) -> void :
	._on_shop_item_focused(shop_item, player_index)
	if not RunData.is_coop_run and shop_item.active and UIService.current_device != CoopService.PlayerType.KEYBOARD_AND_MOUSE:
		show_shop_item_tags(shop_item)

func _on_shop_item_unfocused(shop_item: ShopItem, player_index: int) -> void :
	._on_shop_item_unfocused(shop_item, player_index)
	hide_tags(shop_item)

func foxlab_shop_has_same_name(player_index: int) -> bool:
	var seen = {}
	for shop_tuple in _shop_items[player_index]:
		var id_hash = shop_tuple[0].my_id_hash
		if seen.has(id_hash):
			return true
		seen[id_hash] = true
	return false

func _update_visual_locks() -> void :
	# 无重名时基类按 my_id 匹配即可；有重名才需要精确区分
	var has_same_name = false
	for player_index in RunData.get_player_count():
		if foxlab_shop_has_same_name(player_index):
			has_same_name = true
			break
	if not has_same_name:
		._update_visual_locks()
		return

	# 存档恢复后 locked_shop_items 与 _shop_items 是两批各自反序列化的实例，
	# 先按元组签名把锁定条目重链到商店元组的实例上，之后整个商店会话的锁定/解锁/购买都走实例比较
	for player_index in RunData.get_player_count():
		for locked_item in RunData.locked_shop_items[player_index]:
			for shop_tuple in _shop_items[player_index]:
				if Utils.foxlab_same_shop_tuple(shop_tuple, locked_item):
					locked_item[0] = shop_tuple[0]
					break

	unlock_all_shop_items_visually()
	for player_index in RunData.get_player_count():
		var shop_items_container = _get_shop_items_container(player_index)
		var player_shop_items = _shop_items[player_index]
		var player_locked_items = RunData.get_player_locked_shop_items(player_index)
		for locked_item in player_locked_items:
			var first_same_name = -1
			var precise = -1
			for i in player_shop_items.size():
				if shop_items_container.is_shop_item_locked_visually(i):
					continue
				if player_shop_items[i][0].my_id_hash != locked_item[0].my_id_hash:
					continue
				if first_same_name == -1:
					first_same_name = i
				if Utils.foxlab_same_shop_tuple(player_shop_items[i], locked_item):
					precise = i
					break
			var target = precise if precise != -1 else first_same_name
			if target != -1:
				shop_items_container.lock_shop_item_visually(target)

func foxlab_upgrade_locked_items(player_locked_items: Array, player_index: int) -> void:
	var chance = RunData.get_player_effect(Utils.foxlab_upgrade_locked_item_on_reroll_hash, player_index)
	if chance <= 0:
		return
	var primal_dread = Utils.foxlab_get_dlc("primal_dread")
	var abyssal_terrors = Utils.foxlab_get_dlc("abyssal_terrors")

	for locked_item in player_locked_items:
		if not Utils.get_chance_success(chance / 100.0):
			continue
		var vanilla_item = _foxlab_get_vanilla_copy(locked_item[0])
		if vanilla_item == null:
			continue
		var upgraded = null
		if locked_item[0].is_cursed:
			# 已诅咒：从原版基底重掷，诅咒系数严格更深才替换
			if abyssal_terrors != null:
				var recursed = abyssal_terrors.curse_item(vanilla_item, player_index, false, locked_item[0].curse_factor)
				if recursed.curse_factor > locked_item[0].curse_factor:
					upgraded = recursed
		elif locked_item[0] is WeaponData and locked_item[0].is_meca:
			# 已机械化武器：从原版基底保持rank1重掷一对属性，打分严格更优才替换
			if primal_dread != null:
				var current_score = _foxlab_meca_pair_score(locked_item[0], player_index)
				for _i in 500:
					var rerolled = primal_dread.meca_item(vanilla_item, player_index)
					if _foxlab_meca_pair_score(rerolled, player_index) > current_score:
						upgraded = rerolled
						break
		elif not locked_item[0].is_mutant:
			# 无附加状态：与普通刷新一致尝试一次，获得任一状态即视为升级
			for _i in 500:
				var modified = ItemService.apply_item_effect_modifications(vanilla_item, player_index)
				if modified != vanilla_item:
					upgraded = modified
					break
		if upgraded != null:
			locked_item[0] = upgraded
			RunData.add_tracked_value(player_index, Utils.item_foxlab_fishing_net_hash, 1)

func _foxlab_get_vanilla_copy(item_data):
	if item_data is WeaponData:
		return ItemService.foxlab_get_weapon_from_weapon_id(item_data.weapon_id_hash, item_data.tier)
	return ItemService.get_item_from_id(item_data.my_id_hash)

func _foxlab_meca_pair_score(weapon: WeaponData, player_index: int) -> int:
	var merged_character = ItemService._foxlab_get_merged_character(player_index)
	var is_structure_weapon = EntityService.is_weapon_spawning_structure(weapon)
	var score = 0
	for effect in weapon.effects:
		if not effect is EffectOption:
			continue
		var stat_name = Keys.hash_to_string[effect.key_hash]
		if merged_character != null and stat_name in merged_character.wanted_tags:
			score += 1
		if not is_structure_weapon and (effect.key_hash == Keys.stat_attack_speed_hash
			or effect.key_hash == Keys.stat_percent_damage_hash
			or effect.key_hash == Keys.stat_crit_chance_hash):
			score += 1
		var in_scaling = false
		for scaling_stat in weapon.stats.scaling_stats:
			if scaling_stat[0] == effect.key_hash and float(scaling_stat[1]) > 0.0:
				in_scaling = true
				break
		if in_scaling or (is_structure_weapon and effect.key_hash == Keys.stat_engineering_hash):
			score += 2
	return score

func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void :
	if not just_entered_shop:
		foxlab_upgrade_locked_items(player_locked_items, player_index)
	.fill_shop_items(player_locked_items, player_index, just_entered_shop)

	var lose_item_num = RunData.get_player_effect(Utils.foxlab_lose_item_on_reroll_hash, player_index)
	if not just_entered_shop and lose_item_num > 0:
		var items_ref = RunData.get_player_items_ref(player_index)
		var has_hourglass = false
		var color = Color(ProgressData.settings.color_negative)
		var update_item = false
		for i in range(items_ref.size() - 1, -1, -1):
			var item_data = items_ref[i]
			if Utils.foxlab_is_sellable_item(item_data):
				if item_data.my_id_hash == Keys.item_hourglass_hash:
					has_hourglass = true
				elif item_data.my_id_hash == Keys.item_axolotl_hash and item_data.effects.size() > 0 and "has_been_applied" in item_data.effects[0]:
					item_data.effects[0].has_been_applied = false
				update_item = true
				RunData.foxlab_remove_item_by_index(i, player_index, false)
				var reroll_button= _get_reroll_button(player_index)
				var pos = reroll_button.rect_global_position
				if not RunData.is_coop_run:
					pos.y += reroll_button.rect_size.y / 2
				else:
					pos.x += reroll_button.rect_size.x - 80
				var icon_scale = Utils.foxlab_fit_item_icon_scale(item_data.icon)
				_floating_text_manager.display("-1", pos, Utils.CURSE_COLOR if item_data.is_cursed else color, item_data.icon,\
					_floating_text_manager.duration * 2, true, _floating_text_manager.direction, false, icon_scale)
				lose_item_num -= 1
				if lose_item_num <= 0:
					break
		if has_hourglass:
			update_go_next_button_text()
		if update_item:
			_on_foxlab_item_gear_changed(player_index)

	if RunData.get_player_effect_bool(Utils.foxlab_curse_item_by_price_hash, player_index):
		var pos = RunData.get_player_effect(Utils.foxlab_price_digit_hash, player_index) - 1
		if pos >= 0 and pos < get_player_shop_items(player_index).size():
			var item = get_player_shop_items(player_index)[pos]
			if not item[0].is_cursed:
				var dlc = Utils.foxlab_get_dlc("abyssal_terrors")
				if dlc != null:
					item[0] = dlc.curse_item(item[0], player_index)
	RunData.get_player_effects(player_index)[Utils.foxlab_price_digit_hash] = 0
