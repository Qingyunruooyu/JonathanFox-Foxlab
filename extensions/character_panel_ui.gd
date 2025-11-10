extends "res://ui/menus/ingame/character_panel_ui.gd"

var potato_texture = load("res://entities/units/player/potato.png")
var transparent_texture = load("res://mods-unpacked/JonathanFox-FoxLab/contents/enemy_icons/transparent_icon.png")

func apply_items_appearance(all_items: Array) -> void :
	.apply_items_appearance(all_items)
	for item in all_items:
		for app in item.item_appearances:
			if "hide_vanilla_potato" in app and app.hide_vanilla_potato:
				var potato = $"%Character"/Sprite
				potato.texture = transparent_texture
				var legs = $"%Character"/Legs
				legs.visible = false
				return

	var potato = $"%Character"/Sprite
	potato.texture = potato_texture
	var legs = $"%Character"/Legs
	legs.visible = true
	

