extends "res://entities/units/player/player.gd"

var foxlab_potato_texture = load("res://entities/units/player/potato.png")
var foxlab_transparent_texture = load("res://mods-unpacked/JonathanFox-FoxLab/contents/enemy_icons/transparent_icon.png")

var foxlab_ball_lighting_names = ["item_foxlab_ball_lightning_3", "item_foxlab_ball_lightning_2", "item_foxlab_ball_lightning_1", "item_foxlab_ball_lightning_0"]

var _foxlab_ball_lightning_timer: Timer

func _ready() -> void :
	var ball_lightning_effect = RunData.get_player_effect("foxlab_ball_lightning", player_index)
	if ball_lightning_effect.size() > 0 and ball_lightning_effect[0] > 0:
		_foxlab_ball_lightning_timer = Timer.new()
		_foxlab_ball_lightning_timer.wait_time = ball_lightning_effect[3]
		var _foxlab_ball_lightning = _foxlab_ball_lightning_timer.connect("timeout", self, "on_foxlab_ball_lightning_timeout")
		add_child(_foxlab_ball_lightning_timer)
		_foxlab_ball_lightning_timer.start()

func on_foxlab_ball_lightning_timeout() -> void :
	var ball_lightning_effect = RunData.get_player_effect("foxlab_ball_lightning", player_index)
	var ball_lightning_stats = WeaponService.init_ranged_stats(ball_lightning_effect[1], player_index, true)
	var tracking_key = ""
	for track_id in foxlab_ball_lighting_names:
		if RunData.get_nb_item(track_id, player_index):
			tracking_key = track_id
			break
	for i in ball_lightning_effect[0]:
		var direction = (2 * PI / ball_lightning_effect[0]) * i
		var auto_target_enemy: bool = ball_lightning_effect[2]
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.damage_tracking_key = tracking_key
		args.from_player_index = player_index
		var _projectile = WeaponService.manage_special_spawn_projectile(
			self,
			ball_lightning_stats,
			direction,
			auto_target_enemy,
			_entity_spawner_ref,
			self,
			args
		)


############ 函数扩展 #########
func _clean_up() -> void :
	._clean_up()
	if _foxlab_ball_lightning_timer:
		_foxlab_ball_lightning_timer.stop()
		_foxlab_ball_lightning_timer.paused = true

func apply_items_effects() -> void :
	.apply_items_effects()
	for appearance in RunData.get_player_appearances(player_index):
			if "hide_vanilla_potato" in appearance and appearance.hide_vanilla_potato:
				var potato = $Animation / Sprite
				potato.texture = foxlab_transparent_texture
				var legs = $Animation/Legs
				legs.visible = false
				return
	var potato = $Animation / Sprite
	potato.texture = foxlab_potato_texture
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
