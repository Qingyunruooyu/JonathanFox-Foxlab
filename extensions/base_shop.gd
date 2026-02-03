extends "res://ui/menus/shop/base_shop.gd"

func foxlab_switch_turret_item(old_level: int, new_level: int, p_player_index: int) -> void :
	var player_items = RunData.get_player_items(p_player_index)

	for item in player_items:
		if item.my_id_hash == Keys.item_builder_turret_n_hash[old_level]:
			RunData.remove_item(item, p_player_index)
			break

	var new_item = ItemService.foxlab_get_builder_turret_at_level(new_level, p_player_index)
	RunData.add_item(new_item, p_player_index)

func _ready() -> void :
	if RunData.get_player_effect_bool(Utils.foxlab_shop_effects_checked_hash, 0):
		DebugService.log_data("foxlab_shop_effects_checked: is true")
		return
	DebugService.log_data("foxlab_shop_effects_checked: is false")
	ItemService.foxlab_just_enter_shop = [true, true, true, true]
	for player_index in RunData.get_player_count():
		var struct_range = RunData.get_player_effect(Keys.structure_range_hash, player_index)
		var new_level = BuilderTurret.get_level(struct_range)
		var update_item = false
		for level in range(new_level):
			var number = RunData.get_nb_item(Keys.item_builder_turret_n_hash[level], player_index)
			for i in range(number):
				foxlab_switch_turret_item(level, new_level, player_index)
				update_item = true
		if update_item:
			var player_gear_container = _get_gear_container(player_index)
			var items = RunData.get_player_items(player_index)
			player_gear_container.set_items_data(items)

		if RunData.get_player_effect_bool(Utils.foxlab_keep_random_weapon_hash, player_index) and RunData.get_player_weapons_ref(player_index).size() > 0:
			var weapons = RunData.get_player_weapons(player_index)
			var weapon_idx_to_keep = Utils.randi_range(0, weapons.size() - 1)
			var weapon_to_keep:WeaponData = weapons[weapon_idx_to_keep]
			for i in range(weapons.size()):
				if i != weapon_idx_to_keep:
					RunData.remove_weapon(weapons[i], player_index)
			var player_gear_container = _get_gear_container(player_index)
			player_gear_container.set_weapons_data([weapon_to_keep])
			var recycling_value = ItemService.get_recycling_value(RunData.current_wave, weapon_to_keep.value, player_index, true, false)
			RunData.add_gold(recycling_value, player_index)
			_update_stats(player_index)
			RunData.add_tracked_value(player_index, Utils.character_foxlab_staff_officer_hash, recycling_value)

	RunData.get_player_effects(0)[Utils.foxlab_shop_effects_checked_hash] = 1
	DebugService.log_data("foxlab_shop_effects_checked: set true")

func on_shop_item_bought(shop_item: ShopItem, player_index: int) -> void :
	.on_shop_item_bought(shop_item, player_index)
	var item_data = shop_item.item_data
	if item_data.get_category() == Category.WEAPON and\
		item_data.tier >= RunData.get_player_effect(Utils.foxlab_bonus_reroll_weapon_tier_hash, player_index):
		_has_bonus_free_reroll[player_index] = true
		set_reroll_button_price(player_index)

func buy_item(item_data: ItemData, player_index: int) -> void :
	var prev_weapon_slot = RunData.get_player_effect(Keys.weapon_slot_hash, player_index)
	var prev_weapon_num = RunData.get_player_weapons_ref(player_index).size()
	var prev_mask_value = RunData.tracked_item_effects[player_index][Utils.item_foxlab_mask_hash]
	var prev_hourglass = RunData.get_player_effect(Keys.item_hourglass_hash, player_index)

	.buy_item(item_data, player_index)

	var player_gear_container = _get_gear_container(player_index)

	if (RunData.get_player_effect(Keys.weapon_slot_hash, player_index) != prev_weapon_slot) or \
		(RunData.get_player_weapons_ref(player_index).size() != prev_weapon_num):
		var weapons = RunData.get_player_weapons(player_index)
		player_gear_container.set_weapons_data(weapons)

	if RunData.tracked_item_effects[player_index][Utils.item_foxlab_mask_hash] != prev_mask_value:
		var items = RunData.get_player_items(player_index)
		player_gear_container.set_items_data(items)

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
	._on_RerollButton_pressed(player_index)
	if RunData.get_player_effect(Keys.weapon_slot_hash, player_index) != prev_weapon_slot:
		var player_gear_container = _get_gear_container(player_index)
		var weapons = RunData.get_player_weapons(player_index)
		player_gear_container.set_weapons_data(weapons)
	var effects:Array = RunData.get_player_effects(player_index)[Utils.foxlab_force_remove_on_reroll_hash]
	var update_item = false
	while not effects.empty():
		var item_id = effects.front()[0]
		var item = RunData.get_player_item(item_id, player_index)
		if item != null:
			RunData.remove_item(item, player_index)
			update_item = true
		else:
			#DebugService.log_data("item not exist: " + item_id)
			break
	if update_item:
		var player_gear_container = _get_gear_container(player_index)
		var items = RunData.get_player_items(player_index)
		player_gear_container.set_items_data(items)


func _on_GoButton_pressed(player_index: int) -> void :
	if RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
		RunData.foxlab_shop_items[player_index] = _get_shop_items_container(player_index)._shop_items
	._on_GoButton_pressed(player_index)

func _on_tree_exited() -> void :
	._on_tree_exited()

	var wave_reset_count: = 0
	for player_index in RunData.get_player_count():
		if not RunData.get_player_effect_bool(Utils.foxlab_remember_shop_items_hash, player_index):
			continue
		for item in RunData.foxlab_shop_items[player_index]:
			if item != null and item.active and not item.locked:
				RunData.foxlab_remember_item(item.item_data, player_index)
		for item in RunData.locked_shop_items[player_index]:
			RunData.foxlab_remember_item(item[0], player_index)
		RunData.foxlab_modify_weapon(player_index)
		RunData.foxlab_update_remembered_item(player_index)

		var effects = RunData.get_player_effects(player_index)
		var hourglass_count = effects[Keys.item_hourglass_hash]
		if hourglass_count > 0:
			wave_reset_count += hourglass_count
			var source_item = RunData.get_player_item(Keys.item_hourglass_hash, player_index)
			RunData.remove_item(source_item, player_index)

	RunData.current_wave -= wave_reset_count

