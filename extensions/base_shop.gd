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
	var prev_weapon_slot = RunData.get_player_effect("weapon_slot", player_index)
	._on_RerollButton_pressed(player_index)
	if RunData.get_player_effect("weapon_slot", player_index) != prev_weapon_slot:
		var player_gear_container = _get_gear_container(player_index)
		var weapons = RunData.get_player_weapons(player_index)
		player_gear_container.set_weapons_data(weapons)
	
