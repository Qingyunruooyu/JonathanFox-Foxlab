extends "res://ui/menus/ingame/character_panel_ui.gd"

var foxlab_potato_texture = load("res://entities/units/player/potato.png")
var foxlab_transparent_texture = load("res://mods-unpacked/JonathanFox-FoxLab/contents/enemy_icons/transparent_icon.png")

func apply_items_appearance(all_items: Array) -> void :
	if RunData.get_player_character(player_index) and \
		RunData.get_player_character(player_index).my_id_hash == Utils.character_foxlab_faceless_hash:
		all_items = all_items.duplicate()
		if RunData.tracked_item_effects[player_index][Utils.item_foxlab_mask_hash] <= 0:
			var mask_item = ItemService.get_element(ItemService.items, Utils.item_foxlab_mask_hash)
			for effect in mask_item.effects:
				if effect.get_id() == "foxlab_get_rand_character":
					effect.try_generate(player_index)
			var meta = RunData.get_foxlab_mask_meta(player_index)[0]
			all_items.append_array(meta.chars)
		else:
			all_items.append({"item_appearances": RunData.get_player_appearances(player_index)})
	.apply_items_appearance(all_items)
	for item in all_items:
		for app in item.item_appearances:
			if "foxlab_hide_potato" in app and app.foxlab_hide_potato:
				var potato = $"%Character"/Sprite
				potato.texture = foxlab_transparent_texture
				var legs = $"%Character"/Legs
				legs.visible = false
				return

	var potato = $"%Character"/Sprite
	potato.texture = foxlab_potato_texture
	var legs = $"%Character"/Legs
	legs.visible = true


