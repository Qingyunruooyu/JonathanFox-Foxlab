extends "res://entities/units/player/player.gd"

var potato_texture = load("res://entities/units/player/potato.png")
var transparent_texture = load("res://mods-unpacked/JonathanFox-FoxLab/contents/enemy_icons/transparent_icon.png")

var ball_lightings = ["item_brolab_球状闪电_3", "item_brolab_球状闪电_2", "item_brolab_球状闪电_1", "item_brolab_球状闪电_0"]

func on_alien_eyes_timeout() -> void :
	.on_alien_eyes_timeout()
	for track_id in ball_lightings:
		if RunData.get_nb_item(track_id, player_index):
			RunData.set_tracked_value(player_index, track_id, RunData.tracked_item_effects[player_index]["item_alien_eyes"])
			break

func apply_items_effects() -> void :
	.apply_items_effects()
	for appearance in RunData.get_player_appearances(player_index):
			if "hide_vanilla_potato" in appearance and appearance.hide_vanilla_potato:
				var potato = $Animation / Sprite
				potato.texture = transparent_texture
				var legs = $Animation/Legs
				legs.visible = false
				return
	var potato = $Animation / Sprite
	potato.texture = potato_texture
	var legs = $Animation/Legs
	legs.visible = true

func on_weapon_wanted_to_break(weapon: Weapon, gold_dropped: int) -> void :
	if not current_weapons.has(weapon):
		return

	emit_signal("wanted_to_spawn_gold", gold_dropped, weapon.global_position, 300)
	var _r = RunData.remove_weapon_by_index(weapon.weapon_pos, player_index)

	current_weapons.erase(weapon)

	for current_weapon in current_weapons:
		if current_weapon.weapon_pos > weapon.weapon_pos:
			current_weapon.weapon_pos -= 1

	SoundManager.play(Utils.get_rand_element(WeaponService.breaking_sounds), - 15, 0.1, true)

	weapon._current_cooldown = 99999999.9
	weapon.visible = false
	weapon.disable_hitbox()
	weapon.disable_target_tracking()
	.on_weapon_wanted_to_break(weapon, gold_dropped)
