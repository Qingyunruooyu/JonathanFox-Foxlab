extends "res://entities/units/player/player.gd"

var foxlab_burning_particle = preload("res://particles/burning/torch_burning_particles.tscn")
var foxlab_scepter_particle = preload("res://particles/ghost_scepter_particles.tscn")
var foxlab_potato_texture = preload("res://entities/units/player/potato.png")
var foxlab_transparent_texture = preload("res://mods-unpacked/JonathanFox-FoxLab/contents/enemy_icons/transparent_icon.png")

var foxlab_ball_lighting_names = [Keys.generate_hash("item_foxlab_ball_lightning_3"), Keys.generate_hash("item_foxlab_ball_lightning_2"), Keys.generate_hash("item_foxlab_ball_lightning_1"), Keys.generate_hash("item_foxlab_ball_lightning_0"), ]

var _foxlab_ball_lightning_timer: Timer

var foxlab_enemy_stats_on_hit = []

var _projectile_on_hit_effects = []
var _has_projectile_on_hit = false

func _ready() -> void :
	var ball_lightning_effect = RunData.get_player_effect(Utils.foxlab_ball_lightning_hash, player_index)
	if ball_lightning_effect.size() > 0 and ball_lightning_effect[0] > 0:
		_foxlab_ball_lightning_timer = Timer.new()
		_foxlab_ball_lightning_timer.wait_time = ball_lightning_effect[3]
		var _foxlab_ball_lightning = _foxlab_ball_lightning_timer.connect("timeout", self, "on_foxlab_ball_lightning_timeout")
		add_child(_foxlab_ball_lightning_timer)
		_foxlab_ball_lightning_timer.start()

	var temp_stats_on_hit_effect = RunData.get_player_effect(Keys.temp_stats_on_hit_hash, player_index)
	for temp_stat_on_hit in temp_stats_on_hit_effect:
			if temp_stat_on_hit[0] in Utils.foxlab_enemy_stats:
				foxlab_enemy_stats_on_hit.push_back(temp_stat_on_hit[0])

	var projectile_on_hit_effect: Array = RunData.get_player_effect(Utils.foxlab_projectile_on_hit_hash, player_index)
	if not projectile_on_hit_effect.empty() and \
		projectile_on_hit_effect[0] + RunData.get_player_effect(Utils.foxlab_projectile_on_hit_num_hash, player_index) > 0:
			_has_projectile_on_hit = true
			for effect in projectile_on_hit_effect[4]:
				_projectile_on_hit_effects.append(load(effect))

func on_foxlab_ball_lightning_timeout() -> void :
	var ball_lightning_effect = RunData.get_player_effect(Utils.foxlab_ball_lightning_hash, player_index)
	var ball_lightning_stats = WeaponService.init_ranged_stats(ball_lightning_effect[1], player_index, true)
	var tracking_key = Keys.empty_hash
	for track_id in foxlab_ball_lighting_names:
		if RunData.get_nb_item(track_id, player_index):
			tracking_key = track_id
			break
	for i in ball_lightning_effect[0]:
		var direction = (2 * PI / ball_lightning_effect[0]) * i
		var auto_target_enemy: bool = ball_lightning_effect[2]
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.damage_tracking_key_hash = tracking_key
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

func foxlab_manage_projectile_on_hit() -> void:
	var projectile_on_hit_effect: Array = RunData.get_player_effect(Utils.foxlab_projectile_on_hit_hash, player_index)
	var weapon_args = WeaponServiceInitStatsArgs.new()
	weapon_args.effects = _projectile_on_hit_effects
	var projectile_stats = WeaponService.init_ranged_stats(projectile_on_hit_effect[1], player_index, true, weapon_args)
	var proj_num = projectile_on_hit_effect[0] +  RunData.get_player_effect(Utils.foxlab_projectile_on_hit_num_hash, player_index)
	for i in proj_num:
		var direction = (2 * PI / projectile_on_hit_effect[0]) * i
		var auto_target_enemy: bool = projectile_on_hit_effect[2]
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.damage_tracking_key_hash = projectile_on_hit_effect[5]
		args.from_player_index = player_index
		args.effects = _projectile_on_hit_effects
		var _projectile = WeaponService.manage_special_spawn_projectile(
			self,
			projectile_stats,
			direction,
			auto_target_enemy,
			_entity_spawner_ref,
			self,
			args
		)

############ 函数扩展 #########
func add_weapon(weapon: WeaponData, pos: int) -> void :
	.add_weapon(weapon, pos)
	var cur_weapon = current_weapons.back()
	if not cur_weapon.muzzle.get_children().empty():
		return

	for effect in cur_weapon.effects:
		if "burning_data" in effect:
			var instance = foxlab_burning_particle.instance()
			cur_weapon.muzzle.add_child(instance)
			return

	if not RunData.foxlab_remembered_weapons[player_index].empty():
		var instance = foxlab_scepter_particle.instance()
		cur_weapon.muzzle.add_child(instance)

func _clean_up() -> void :
	._clean_up()
	if _foxlab_ball_lightning_timer:
		_foxlab_ball_lightning_timer.stop()
		_foxlab_ball_lightning_timer.paused = true

func apply_items_effects() -> void :
	.apply_items_effects()
	for appearance in RunData.get_player_appearances(player_index):
			if "foxlab_hide_potato" in appearance and appearance.foxlab_hide_potato:
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

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var ret = .take_damage(value, args)
	if ret[1] > 0:
		for stats in foxlab_enemy_stats_on_hit:
			EntityService.factor_cache.erase(stats)
		var hitbox = args.hitbox
		if _has_projectile_on_hit and hitbox != null and is_instance_valid(hitbox.from) and hitbox.from is Enemy:
			foxlab_manage_projectile_on_hit()
	return ret
