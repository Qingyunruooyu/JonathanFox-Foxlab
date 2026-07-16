extends "res://ui/menus/ingame/character_panel_ui.gd"

var foxlab_potato_texture = load("res://entities/units/player/potato.png")
var foxlab_transparent_texture = load("res://mods-unpacked/JonathanFox-FoxLab/contents/enemy_icons/transparent_icon.png")
var foxlab_burning_particles = null

func apply_items_appearance(all_items: Array) -> void :
	if foxlab_burning_particles:
		foxlab_burning_particles.emitting = false
		foxlab_burning_particles.visible = false

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


	var potato = $"%Character"/Sprite
	potato.texture = foxlab_potato_texture
	var legs = $"%Character"/Legs
	legs.visible = true

	.apply_items_appearance(all_items)


	var add_burning_particle = false
	if RunData.get_player_effect_bool(Utils.foxlab_burning_proof_hash, player_index):
		add_burning_particle = true
	else:
		for item in all_items:
			if item.get("my_id_hash") == Utils.character_foxlab_nyuba_hash:
				add_burning_particle = true
	if add_burning_particle:
		var character_node = $"%Character"
		if foxlab_burning_particles == null:
			foxlab_burning_particles = load("res://particles/burning/unit_burning_particles.tscn").instance()
			character_node.add_child(foxlab_burning_particles)
			foxlab_burning_particles.position = Vector2( 0, -24 )
		foxlab_burning_particles.emitting = true
		foxlab_burning_particles.visible = true
		character_node.move_child(foxlab_burning_particles, character_node.get_child_count() - 1)

	for item in all_items:
		for app in item.item_appearances:
			if app.get("foxlab_hide_potato"):
				potato.texture = foxlab_transparent_texture
				legs.visible = false
				return




