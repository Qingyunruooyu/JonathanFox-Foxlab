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

var _foxlab_bounce_box:Area2D = null

func _ready() -> void :
	if _foxlab_has_curse():
		foxlab_add_curse_particle()
	foxlab_ball_ligntning_ready()
	foxlab_enemy_temp_stats_on_hit_ready()
	foxlab_projectile_on_hit_ready()
	foxlab_bounce_player_projectile_ready()
	_foxlab_has_charmed_all = RunData.get_player_effect(Utils.foxlab_charm_all_when_fully_heal_hash, player_index).empty()
	call_deferred("foxlab_connect_jelly_shields")

func foxlab_ball_ligntning_ready():
	var ball_lightning_effect = RunData.get_player_effect(Utils.foxlab_ball_lightning_hash, player_index)
	if ball_lightning_effect.size() > 0 and ball_lightning_effect[0] > 0:
		_foxlab_ball_lightning_timer = Timer.new()
		_foxlab_ball_lightning_timer.wait_time = ball_lightning_effect[3]
		var _foxlab_ball_lightning = _foxlab_ball_lightning_timer.connect("timeout", self, "on_foxlab_ball_lightning_timeout")
		add_child(_foxlab_ball_lightning_timer)
		_foxlab_ball_lightning_timer.start()

func foxlab_enemy_temp_stats_on_hit_ready():
	var temp_stats_on_hit_effect = RunData.get_player_effect(Keys.temp_stats_on_hit_hash, player_index)
	for temp_stat_on_hit in temp_stats_on_hit_effect:
			if temp_stat_on_hit[0] in Utils.foxlab_enemy_stats:
				foxlab_enemy_stats_on_hit.push_back(temp_stat_on_hit[0])

func foxlab_projectile_on_hit_ready():
	var projectile_on_hit_effect: Array = RunData.get_player_effect(Utils.foxlab_projectile_on_hit_hash, player_index)
	if not projectile_on_hit_effect.empty() and \
		projectile_on_hit_effect[0] + RunData.get_player_effect(Utils.foxlab_projectile_on_hit_num_hash, player_index) > 0:
			_foxlab_has_projectile_on_hit = true
			for effect in projectile_on_hit_effect[4]:
				_foxlab_projectile_on_hit_effects.append(load(effect))

func foxlab_bounce_player_projectile_ready():
	if RunData.get_player_effect_bool(Utils.foxlab_bounce_player_projectile_hash, player_index):
		_foxlab_bounce_box = load("res://overlap/hurtbox.tscn").instance()
		add_child(_foxlab_bounce_box)
		_foxlab_bounce_box.position =_hurtbox.position
		_foxlab_bounce_box.collision_mask = Utils.PLAYER_PROJECTILES_BIT | Utils.PET_PROJECTILES_BIT
		var collision = _foxlab_bounce_box._collision
		collision.position = _hurtbox._collision.position
		collision.shape = _hurtbox._collision.shape

		_foxlab_bounce_box.connect("area_entered", self, "_on_foxlab_bounce_box_area_entered")

func _on_foxlab_bounce_box_area_entered(hitbox: Area2D) -> void :
	call_deferred("foxlab_bounce_area_entered_deferred", hitbox)

func foxlab_bounce_area_entered_deferred(hitbox: Area2D) -> void:
	if get_parent() == null or not hitbox.active or not hitbox.deals_damage or hitbox.ignored_objects.has(self) or _pending_die:
		return
	var source = hitbox.get_parent()
	if source is PlayerProjectile and source._weapon_stats.can_bounce:
		# 这个反弹需要能随机到BOSS头上，如果用_entity_spawner_ref.get_rand_enemy就不会随机到BOSS了
		var target = Utils.get_rand_element(_entity_spawner_ref.get_all_enemies())
		var direction = (target.global_position - source.global_position).angle() if target != null else rand_range( - PI, PI)

		var stats = source._weapon_stats
		var base_speed = stats.projectile_speed
		source._max_range = source.INFINITE_RANGE
		var velocity_scalar = source.velocity.length()
		if stats.increase_projectile_speed_with_range:
			stats.projectile_speed = clamp(base_speed + (base_speed / 300.0) * source._max_range, 50, 6000) as int
			velocity_scalar *= stats.projectile_speed / (base_speed as float)

		source.velocity = Vector2.RIGHT.rotated(direction) * velocity_scalar
		source.rotation = source.velocity.angle()

		source._set_time_until_max_range()
		stats.projectile_speed = base_speed
		foxlab_process_player_projectile_effects(hitbox)

	elif "velocity" in source: # 敌人投射物
		# 这个反弹需要能随机到BOSS头上，如果用_entity_spawner_ref.get_rand_enemy就不会随机到BOSS了
		var target = Utils.get_rand_element(_entity_spawner_ref.get_all_enemies())
		var direction = (target.global_position - source.global_position).angle() if target != null else rand_range( - PI, PI)
		source.velocity = Vector2.RIGHT.rotated(direction) * source.velocity.length()
		source.rotation = source.velocity.angle()

func foxlab_process_player_projectile_effects(hitbox: Area2D):
	var from = hitbox.from if is_instance_valid(hitbox.from) else null
	var from_player_index = from.player_index if (from != null and from.player_index != - 1) else RunData.DUMMY_PLAYER_INDEX
	for effect in hitbox.effects:
		if effect is ExplodingEffect:
			if Utils.get_chance_success(effect.chance):
				_explode_args_unit.pos = global_position
				_explode_args_unit.damage = hitbox.damage
				_explode_args_unit.accuracy = hitbox.accuracy
				_explode_args_unit.crit_chance = hitbox.crit_chance
				_explode_args_unit.crit_damage = hitbox.crit_damage
				_explode_args_unit.burning_data = hitbox.burning_data
				_explode_args_unit.scaling_stats = hitbox.scaling_stats
				_explode_args_unit.from_player_index = from_player_index
				_explode_args_unit.is_healing = hitbox.is_healing
				_explode_args_unit.damage_tracking_key_hash = hitbox.damage_tracking_key_hash

				var explosion = WeaponService.explode(effect, _explode_args_unit)
				if from != null and from is Weapon:
					explosion.connect("hit_something", from, "on_weapon_hit_something", [explosion._hitbox])
					if not explosion.is_connected("killed_something", from, "on_killed_something"):
						explosion.connect("killed_something", from, "on_killed_something", [explosion._hitbox])

	if hitbox.projectiles_on_hit.size() > 0:
		for i in hitbox.projectiles_on_hit[0]:
			_spawn_projectile_args.from_player_index = from_player_index
			var projectile = WeaponService.manage_special_spawn_projectile(
				self,
				hitbox.projectiles_on_hit[1],
				rand_range( - PI, PI),
				hitbox.projectiles_on_hit[2],
				_entity_spawner_ref,
				from,
				_spawn_projectile_args
			)
			if from != null and from is Weapon and not projectile.is_connected("hit_something", from, "on_weapon_hit_something"):
				projectile.connect("hit_something", from, "on_weapon_hit_something", [projectile._hitbox])
			if projectile.is_node_ready():
				projectile.set_ignored_objects([self])
			else:
				projectile.call_deferred("set_ignored_objects", [self])

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
	if ball_lightning_effect.empty():
		if _foxlab_ball_lightning_timer:
			_foxlab_ball_lightning_timer.stop()
			_foxlab_ball_lightning_timer.paused = true
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

func foxlab_add_weapon_particle(cur_weapon: Weapon):
	if not cur_weapon.muzzle.get_children().empty():
		return

	for effect in cur_weapon.effects:
		if effect is BurningEffect:
			var instance = foxlab_burning_particle.instance()
			cur_weapon.muzzle.add_child(instance)
			return

	for effect in cur_weapon.effects:
		if effect.custom_key_hash == Utils.foxlab_remembered_effect_begin_hash:
			var instance = foxlab_scepter_particle.instance()
			cur_weapon.muzzle.add_child(instance)
			return


func foxlab_weapon_class_explode(cur_weapon: Weapon, weapon_data: WeaponData):
	for set_id in RunData.get_player_effect(Utils.foxlab_weapon_class_explode_hash, player_index):
		for set in cur_weapon.weapon_sets:
			if set.my_id_hash == set_id:
				if weapon_data.type == WeaponType.MELEE:
					cur_weapon.effects.append(load(WeaponService.FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_MELEE))
				else:
					cur_weapon.effects.append(load(WeaponService.FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_RANGED))

func foxlab_add_weapon(weapon: WeaponData):
	add_weapon(weapon, current_weapons.size())

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
			if _is_burning or args.is_burning:
				_die_args_unit.from = ItemService.get_item_from_id(Keys.item_scared_sausage_hash)
		elif args.from is Enemy:
			_die_args_unit.from = args.from
		elif "player_index" in args.from and args.from.player_index >= 0 and args.from.player_index < RunData.get_player_count():
			_die_args_unit.from = players_ref[args.from.player_index]
		else:
			_die_args_unit.from = args.from
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
		Utils.default_die_args.is_bullet_hell = false

func add_weapon(weapon: WeaponData, pos: int) -> void :
	.add_weapon(weapon, pos)
	var cur_weapon = current_weapons.back()
	foxlab_add_weapon_particle(cur_weapon)
	foxlab_weapon_class_explode(cur_weapon, weapon)

func _clean_up() -> void :
	._clean_up()
	if _foxlab_ball_lightning_timer:
		_foxlab_ball_lightning_timer.stop()
		_foxlab_ball_lightning_timer.paused = true
	if _foxlab_bounce_box:
		_foxlab_bounce_box.disable()

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
	var prev_weapons = current_weapons.size()
	if not ItemService.foxlab_is_android:
		.on_weapon_wanted_to_break(weapon, gold_dropped)
	else:
		if current_weapons.has(weapon):
			emit_signal("wanted_to_spawn_gold", gold_dropped, weapon.global_position, 300)
			var _r = RunData.remove_weapon_by_index(weapon.weapon_pos, player_index)
			current_weapons.erase(weapon)
			for current_weapon in current_weapons:
				if current_weapon.weapon_pos > weapon.weapon_pos:
					current_weapon.weapon_pos -= 1
			SoundManager.play(Utils.get_rand_element(WeaponService.breaking_sounds), - 15, 0.1, true)
			Utils.foxlab_queue_free_weapon(weapon)
			.on_weapon_wanted_to_break(weapon, gold_dropped)

	if current_weapons.size() < prev_weapons:
		var get_item_on_break_effects = RunData.get_player_effect(Utils.foxlab_get_item_on_weapon_break_hash, player_index)
		var main = Utils.get_scene_node()
		RunData.emit_signal("foxlab_item_added", {"icon": weapon._original_sprite, "is_cursed": weapon.is_cursed}, -1, player_index)
		if not get_item_on_break_effects.empty():
			for get_item_on_break_effect in get_item_on_break_effects:
				var boost = Utils.get_stat(get_item_on_break_effect[2], player_index) / 100.0
				var base_chance:float = (get_item_on_break_effect[3] / 100.0) * (1 + boost)
				if RunData.current_wave > RunData.nb_of_waves:
					base_chance /= (1.0 + RunData.get_endless_factor())
				base_chance = min(Utils.FOXLAB_GET_ITEM_ON_BREAK_MAX_CHANCE, base_chance)
				if Utils.get_chance_success(base_chance):
					main.foxlab_get_item(get_item_on_break_effect[0], get_item_on_break_effect[1], player_index)

func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var ret = .take_damage(value, args)
	if ret[1] > 0:
		for stats in foxlab_enemy_stats_on_hit:
			EntityService.factor_cache.erase(stats)
		var hitbox = args.hitbox
		if _foxlab_has_projectile_on_hit and hitbox != null and is_instance_valid(hitbox.from) and hitbox.from.player_index == -1:
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
				for effect in charm_all_effect:
					var item_id_hash = effect[0]
					var items_got:Dictionary = RunData.get_player_effect(Utils.foxlab_charm_all_items_hash, player_index)
					var item_times = items_got.get_or_add(item_id_hash, 0)
					if Utils.get_chance_success(1.0/(1.0 + item_times)):
						main.foxlab_get_item(item_id_hash, effect[1], player_index)
						items_got[item_id_hash] += effect[1]
						play_sound = true
				if play_sound:
					SoundManager.play(preload("res://ui/sounds/Shield 4.mp3"))
	return value_healed

func on_alien_eyes_timeout() -> void :
	var alien_eyes_effect = RunData.get_player_effect(Keys.alien_eyes_hash, player_index)
	# 唯一的异形眼球效果敌袭期间被回收
	if not alien_eyes_effect.empty():
		.on_alien_eyes_timeout()
	elif _alien_eyes_timer:
		print("alien eyes is cleaned")
		_alien_eyes_timer.stop()
		_alien_eyes_timer.paused = true
