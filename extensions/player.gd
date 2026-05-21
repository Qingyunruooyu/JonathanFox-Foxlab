extends "res://entities/units/player/player.gd"

var foxlab_burning_particle = load("res://particles/burning/torch_burning_particles.tscn")
var foxlab_scepter_particle = load("res://particles/ghost_scepter_particles.tscn")
var foxlab_potato_texture = preload("res://entities/units/player/potato.png")
var foxlab_transparent_texture = preload("res://mods-unpacked/JonathanFox-FoxLab/contents/enemy_icons/transparent_icon.png")
var _foxlab_curse_particle =load("res://particles/curse/curse_enemy_particles.tscn")
var _foxlab_curse_particle_instance = null

var foxlab_ball_lighting_names = [Keys.generate_hash("item_foxlab_ball_lightning_3"), Keys.generate_hash("item_foxlab_ball_lightning_2"), Keys.generate_hash("item_foxlab_ball_lightning_1"), Keys.generate_hash("item_foxlab_ball_lightning_0"), ]

var _foxlab_ball_lightning_timer: Timer

var foxlab_enemy_stats_on_hit = []

var _foxlab_projectile_on_hit_effects = []
var _foxlab_has_projectile_on_hit = false

var _foxlab_has_charmed_all = false

func _ready() -> void :
	if _foxlab_has_curse():
		foxlab_add_curse_particle()
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
			_foxlab_has_projectile_on_hit = true
			for effect in projectile_on_hit_effect[4]:
				_foxlab_projectile_on_hit_effects.append(load(effect))

	_foxlab_has_charmed_all = RunData.get_player_effect(Utils.foxlab_charm_all_when_fully_heal_hash, player_index).empty()

	call_deferred("foxlab_connect_jelly_shields")

func foxlab_connect_jelly_shields():
	for jelly in jellyshields:
		var _err = jelly.get_node("Hurtbox").connect("area_entered", self, "_on_foxlab_jellyshield_Hurtbox_area_entered", [jelly])

func _on_foxlab_jellyshield_Hurtbox_area_entered(hitbox: Area2D, jelly: Node2D) -> void :
	var parent = hitbox.get_parent()
	# 是玩家投射物但是却是敌人投射物的掩码，会攻击玩家，但又不是治疗
	if parent is PlayerProjectile and (hitbox.collision_layer & Utils.ENEMY_PROJECTILES_BIT) and not parent._weapon_stats.is_healing:
		RunData.add_tracked_value(player_index, Keys.item_jellyshield_hash, 1)
		# 为什么不用hitbox.hit_something(self, 0)？
		# 因为JellyFish是Entity，不是Unit，玩家投射物会对thing_hit做add_deacying_speed（鱼叉枪等）、._entity_spawner_ref（反弹）等操作，Entity不支持
		parent.stop()
		jelly._animation_player.play("hit")
		yield(jelly._animation_player, "animation_finished")
		jelly._animation_player.play("idle")

func _foxlab_has_curse():
	if RunData.get_player_character(player_index).is_cursed:
		return true
	var metas = RunData.get_foxlab_mask_meta(player_index)
	for meta in metas:
		for prev in meta.prevs:
			if prev is WeaponData:
				if prev.is_cursed:
					return true;
			elif prev[1] > 0:
				return true

func foxlab_add_curse_particle():
	if _foxlab_curse_particle_instance == null:
		_foxlab_curse_particle_instance = _foxlab_curse_particle.instance()
		add_child(_foxlab_curse_particle_instance)
		add_outline(Utils.CURSE_COLOR)

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
	weapon_args.effects = _foxlab_projectile_on_hit_effects
	var projectile_stats = WeaponService.init_ranged_stats(projectile_on_hit_effect[1], player_index, true, weapon_args)
	var proj_num = projectile_on_hit_effect[0] +  RunData.get_player_effect(Utils.foxlab_projectile_on_hit_num_hash, player_index)
	for i in proj_num:
		var direction = (2 * PI / projectile_on_hit_effect[0]) * i
		var auto_target_enemy: bool = projectile_on_hit_effect[2]
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.damage_tracking_key_hash = projectile_on_hit_effect[5]
		args.from_player_index = player_index
		args.effects = _foxlab_projectile_on_hit_effects
		var _projectile = WeaponService.manage_special_spawn_projectile(
			self,
			projectile_stats,
			direction,
			auto_target_enemy,
			_entity_spawner_ref,
			self,
			args
		)

func foxlab_process_lost_hp() -> bool:
	var effects = RunData.get_player_effects(player_index)
	var lost_hp = effects[Utils.foxlab_lost_hp_hash]
	if lost_hp > 0:
		var prev_health = current_stats.health
		current_stats.health = max(1, current_stats.health - lost_hp) as int
		if current_stats.health != prev_health:
			effects[Utils.foxlab_lost_hp_hash] -= prev_health - current_stats.health
			emit_signal("health_updated", self, current_stats.health, max_stats.health)
			return true
	return false

############ 函数扩展 #########
#　修复官方bug
func die(args: = Utils.default_die_args) -> void :
	var reset_to_default = false
	if args == Utils.default_die_args:
		_die_args_unit.knockback_vector = args.knockback_vector
		_die_args_unit.cleaning_up = args.cleaning_up
		_die_args_unit.enemy_killed_by_player = args.enemy_killed_by_player
		_die_args_unit.killed_by_player_index = args.killed_by_player_index
		_die_args_unit.killing_blow_dmg_value = args.killing_blow_dmg_value
		_die_args_unit.is_burning = args.is_burning
		if not is_instance_valid(args.from):
			if _is_burning:
				_die_args_unit.from = ItemService.get_item_from_id(Keys.item_scared_sausage_hash)
		elif args.from is Structure or args.from is Pet:
			_die_args_unit.from = players_ref[args.from.player_index]
		else:
			_die_args_unit.from = args.from
		if _die_args_unit.has_meta("is_bullet_hell"):
			_die_args_unit.is_bullet_hell = args.is_bullet_hell
		args = _die_args_unit
		reset_to_default = true
	.die(args)
	if reset_to_default:
		Utils.default_die_args.knockback_vector = Vector2.ZERO
		Utils.default_die_args.cleaning_up = false
		Utils.default_die_args.enemy_killed_by_player = true
		Utils.default_die_args.killed_by_player_index = - 1
		Utils.default_die_args.killing_blow_dmg_value = 0
		Utils.default_die_args.is_burning = false
		Utils.default_die_args.from = null
		if Utils.default_die_args.has_meta("is_bullet_hell"):
			Utils.default_die_args.is_bullet_hell = false


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

	for effect in cur_weapon.effects:
		if effect.custom_key_hash == Utils.foxlab_remembered_effect_begin_hash:
			var instance = foxlab_scepter_particle.instance()
			cur_weapon.muzzle.add_child(instance)
			return

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
	if not ItemService.foxlab_is_android:
		.on_weapon_wanted_to_break(weapon, gold_dropped)
		return

	if not current_weapons.has(weapon):
		return

	emit_signal("wanted_to_spawn_gold", gold_dropped, weapon.global_position, 300)
	var _r = RunData.remove_weapon_by_index(weapon.weapon_pos, player_index)

	current_weapons.erase(weapon)

	for current_weapon in current_weapons:
		if current_weapon.weapon_pos > weapon.weapon_pos:
			current_weapon.weapon_pos -= 1

	SoundManager.play(Utils.get_rand_element(WeaponService.breaking_sounds), - 15, 0.1, true)

	Utils.foxlab_queue_free_weapon(weapon)

	.on_weapon_wanted_to_break(weapon, gold_dropped)

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var ret = .take_damage(value, args)
	if ret[1] > 0:
		for stats in foxlab_enemy_stats_on_hit:
			EntityService.factor_cache.erase(stats)
		var hitbox = args.hitbox
		if _foxlab_has_projectile_on_hit and hitbox != null and is_instance_valid(hitbox.from) and hitbox.from is Enemy:
			foxlab_manage_projectile_on_hit()
	return ret

func _on_ItemAttractArea_area_entered(item: Item) -> void:
	._on_ItemAttractArea_area_entered(item)
	if item is Consumable and item.consumable_data.my_id_hash == Utils.consumable_foxlab_seed_hash and\
		item.attracted_by == null:
		item.attracted_by = self
		item.set_physics_process(true)

func on_healing_effect(value: int, tracking_key: int = Keys.empty_hash, from_torture: bool = false) -> int:
	var value_healed = .on_healing_effect(value, tracking_key, from_torture)
	foxlab_process_lost_hp()
	if value_healed > 0 and !_foxlab_has_charmed_all\
		and current_stats.health >= (Utils.get_capped_stat(Keys.stat_max_hp_hash, player_index) as int):
			_foxlab_has_charmed_all = true
			var charm_all_effect = RunData.get_player_effect(Utils.foxlab_charm_all_when_fully_heal_hash, player_index)
			if not charm_all_effect.empty():
				var main = Utils.get_scene_node()
				var play_sound =false
				if not cleaning_up:
					play_sound = true
					for enemy in main._entity_spawner.get_all_enemies():
						if not enemy is Boss and not enemy.is_loot and enemy.can_be_charmed:
							enemy.set_charmed(player_index)
				var hit_protection0 = RunData.get_player_effect(Keys.hit_protection_hash, player_index)
				for effect in charm_all_effect:
					var item_id_hash = effect[0]
					var items_got:Dictionary = RunData.get_player_effect(Utils.foxlab_charm_all_items_hash, player_index)
					var item_times = items_got.get_or_add(item_id_hash, 0)
					if Utils.get_chance_success(1.0/(1.0 + item_times)):
						main.foxlab_get_item(item_id_hash, effect[1], player_index)
						items_got[item_id_hash] += effect[1]
						play_sound = true
				var hit_protection1 = RunData.get_player_effect(Keys.hit_protection_hash, player_index)
				if hit_protection1 > hit_protection0:
					_hit_protection += (hit_protection1 - hit_protection0)
				if play_sound:
					SoundManager.play(preload("res://ui/sounds/Shield 4.mp3"))
	return value_healed
