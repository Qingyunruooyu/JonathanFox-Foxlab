extends "res://ui/menus/shop/base_shop.gd"

func foxlab_switch_turret_item(old_level: int, new_level: int, p_player_index: int) -> void :
	var player_items = RunData.get_player_items(p_player_index)

	for item in player_items:
		if item.my_id == ItemService.foxlab_builder_turret_names[old_level]:
			RunData.remove_item(item, p_player_index)
			break

	var new_item:ItemData = ItemService.foxlab_get_builder_turret_at_level(new_level, p_player_index)
	RunData.add_item(new_item, p_player_index)

func _ready() -> void :
	if RunData.get_player_effect_bool("foxlab_shop_effects_checked", 0):
		return

	ItemService.foxlab_just_enter_shop = [true, true, true, true]
	for player_index in RunData.get_player_count():
		var struct_range = RunData.get_player_effect("structure_range", player_index)
		var new_level = BuilderTurret.get_level(struct_range)
		var update_item = false
		for level in range(new_level):
			var number = RunData.get_nb_item(ItemService.foxlab_builder_turret_names[level], player_index)
			for i in range(number):
				foxlab_switch_turret_item(level, new_level, player_index)
				update_item = true
		if update_item:
			var player_gear_container = _get_gear_container(player_index)
			var items = RunData.get_player_items(player_index)
			player_gear_container.set_items_data(items)

		if RunData.get_player_effect_bool("foxlab_keep_random_weapon", player_index):
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
			RunData.add_tracked_value(player_index, "character_foxlab_staff_officer", recycling_value)

	RunData.get_player_effects(0)["foxlab_shop_effects_checked"] = 1

func on_shop_item_bought(shop_item: ShopItem, player_index: int) -> void :
	.on_shop_item_bought(shop_item, player_index)
	var item_data = shop_item.item_data
	if item_data.get_category() == Category.WEAPON and\
		item_data.tier >= RunData.get_player_effect("foxlab_bonus_reroll_weapon_tier", player_index):
		_has_bonus_free_reroll[player_index] = true
		set_reroll_button_price(player_index)

func buy_item(item_data: ItemData, player_index: int) -> void :
	var prev_weapon_slot = RunData.get_player_effect("weapon_slot", player_index)
	.buy_item(item_data, player_index)
	var update_weapon = false
	var update_item = false
	var update_go_next = false
	for effect in item_data.effects:
		if effect.get_id() == "foxlab_effect_get_rand_character":
			update_weapon = true
			update_item = true
		elif effect.get_id() == "foxlab_effect_get_rand_weapon":
			update_weapon = true
			update_item = true
			update_go_next = true
	if RunData.get_player_effect("weapon_slot", player_index) != prev_weapon_slot:
		update_weapon = true

	var player_gear_container = _get_gear_container(player_index)
	if update_weapon:
		var weapons = RunData.get_player_weapons(player_index)
		player_gear_container.set_weapons_data(weapons)
	if update_item:
		var items = RunData.get_player_items(player_index)
		player_gear_container.set_items_data(items)
	if update_go_next and has_method("update_go_next_button_text"):
		call_deferred("update_go_next_button_text")

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

	var prev_weapon_slot = RunData.get_player_effect("weapon_slot", player_index)
	._on_RerollButton_pressed(player_index)
	if RunData.get_player_effect("weapon_slot", player_index) != prev_weapon_slot:
		var player_gear_container = _get_gear_container(player_index)
		var weapons = RunData.get_player_weapons(player_index)
		player_gear_container.set_weapons_data(weapons)
	var effects:Array = RunData.get_player_effects(player_index)["foxlab_force_remove_on_reroll"]
	var update_item = false
	while not effects.empty():
		var item_id = effects.front()[0]
		var item = RunData.get_player_item(item_id, player_index)
		if item != null:
			RunData.remove_item(item, player_index)
			update_item = true
		else:
			DebugService.log_data("item not exist: " + item_id)
			break
	if update_item:
		var player_gear_container = _get_gear_container(player_index)
		var items = RunData.get_player_items(player_index)
		player_gear_container.set_items_data(items)

