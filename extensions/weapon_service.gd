extends "res://singletons/weapon_service.gd"

const FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_MELEE = "res://mods-unpacked/JonathanFox-FoxLab/contents/items/characters/水母/jellyfish_explode_melee_effect.tres"
const FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_RANGED = "res://mods-unpacked/JonathanFox-FoxLab/contents/items/characters/水母/jellyfish_explode_ranged_effect.tres"

var _foxlab_weapon_class_explode_args = WeaponServiceInitStatsArgs.new()

### 扩展 ###
func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure: = false, is_special_spawn: = false, is_pet: = false) -> WeaponStats:
	args = foxlab_add_weapon_class_explode_stats(from_stats, player_index, args)
	var new_stats = .init_base_stats(from_stats, player_index, args, is_structure, is_special_spawn, is_pet)
	# 命中率超过100%反而会降低命中率，不合理
	new_stats.accuracy = min(1.0, new_stats.accuracy)
	# 原版中 构筑物+宠物 的道具，暴击率和生命窃取按构筑物来算了，比如布雷机器人要有一堆书才能暴击，并且无法生命窃取，这是不对的
	if is_structure and is_pet:
		var corrected_stats = .init_base_stats(from_stats, player_index, args, false, is_special_spawn, is_pet)
		new_stats.lifesteal = corrected_stats.lifesteal
		new_stats.crit_chance = corrected_stats.crit_chance

	new_stats.crit_damage += Utils.get_stat(Utils.stat_foxlab_crit_damage_hash, player_index) / 100.0
	return new_stats

func init_melee_stats(from_stats: MeleeWeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service):
	var new_stats = .init_melee_stats(from_stats, player_index, args)
	new_stats.deal_dmg_on_return = from_stats.deal_dmg_on_return
	return new_stats

func _set_common_ranged_stats(new_stats: RangedWeaponStats, from_stats: RangedWeaponStats, player_index: int):
	._set_common_ranged_stats(new_stats, from_stats, player_index)
	new_stats.increase_projectile_speed_with_range = from_stats.increase_projectile_speed_with_range

	if not RunData.get_player_effect_bool(Utils.foxlab_piercing_is_bounce_hash, player_index):
		return
	var piercing = new_stats.piercing
	new_stats.piercing = 0
	if from_stats.can_bounce:
		new_stats.bounce += piercing

func set_projectile_effects(base_effects: Array, player_index: int = - 1) -> Array:
	if player_index >= 0 and RunData.get_player_effect_bool(Utils.foxlab_piercing_is_bounce_hash, player_index):
		for effect in base_effects:
			if effect.key_hash == Keys.pierce_on_crit_hash:
				effect.key = "bounce_on_crit"
				effect.key_hash = Keys.bounce_on_crit_hash
	return .set_projectile_effects(base_effects, player_index)

func explode(effect: ExplodingEffect, args: WeaponServiceExplodeArgs) -> Node:
	var instance = .explode(effect, args)
	# 原版在start_explosion里面，又覆盖掉了from，影响狂骨判断伤害来源是不是构筑物/宠物
	if args.from != null:
		instance.set_from(args.from)
	var explosion_hitbox = instance._hitbox
	explosion_hitbox.effects = [ ]
	explosion_hitbox.set_knockback(Vector2.ZERO, 0.0, 0.0)
	call_deferred("foxlab_add_weapon_effects_for_explosion", instance)
	return instance

func manage_special_spawn_projectile(
	entity_from,
	weapon_stats,
	direction: float,
	auto_target_enemy: bool,
	entity_spawner_ref,
	from: Node,
	args = _default_spawn_projectile_args
) -> Node:
	var projectile = .manage_special_spawn_projectile(entity_from, weapon_stats, direction, auto_target_enemy, entity_spawner_ref, from, args)
	if (from is Weapon or from is BuilderTurret) and from.effects.size() > 0 and not projectile.killed_something_connected:
		call_deferred("foxlab_connect_signal_for_projectile", from, projectile)
	return projectile

### 功能 ###
func foxlab_connect_signal_for_projectile(from: Node, projectile: Node):
	var _killed_sthing = projectile._hitbox.connect("killed_something", from, "on_killed_something", [projectile._hitbox])
	projectile.killed_something_connected = true
	for effect in from.effects:
		if not effect is ExplodingEffect and not effect is ProjectilesOnHitEffect:
			projectile._hitbox.effects.append(effect)

func foxlab_add_weapon_effects_for_explosion(explosion: Node):
	for connection in explosion.get_signal_connection_list("hit_something"):
		if connection.target is Weapon:
			var dst_hitbox = explosion._hitbox
			var src_hitbox = connection.target._hitbox
			for effect in connection.target.effects:
				if not effect is ExplodingEffect and not effect is ProjectilesOnHitEffect:
					dst_hitbox.effects.append(effect)
			dst_hitbox.set_knockback(src_hitbox.knockback_direction, src_hitbox.knockback_amount, src_hitbox.knockback_piercing)

func foxlab_spawn_landmines_on_enemy_death_count(hitbox: Hitbox, was_burning: bool, player_index: int) -> int:
	var landmines_on_death_effects = RunData.get_player_effect(Utils.foxlab_landmines_on_death_chance_hash, player_index)
	if landmines_on_death_effects.empty():
		return 0

	var from = hitbox.from if hitbox != null else null
	var landmine_count = 0
	for landmines_on_death_effect in landmines_on_death_effects:
		var effect_stat = landmines_on_death_effect[0]
		assert (effect_stat is int)
		var chance = landmines_on_death_effect[1] / 100.0
		if not Utils.get_chance_success(chance):
			continue
		var weapon_did_stat_damage = from is Weapon and find_scaling_stat(effect_stat, from.current_stats.scaling_stats) != null
		var burning_did_stat_damage = effect_stat == Keys.stat_elemental_damage_hash and was_burning
		if weapon_did_stat_damage or burning_did_stat_damage:
			landmine_count += 1
	return landmine_count

func foxlab_add_weapon_class_explode_stats(from_stats:WeaponStats, player_index: int, args:WeaponServiceInitStatsArgs) -> WeaponServiceInitStatsArgs:
	if args.sets.empty():
		return args
	var explode_sets = RunData.get_player_effect(Utils.foxlab_weapon_class_explode_hash, player_index)
	if explode_sets.empty():
		return args
	# 武器实际的效果在player.gd里面添加了
	for effect in args.effects:
		if effect.custom_key_hash == Utils.foxlab_weapon_class_explode_hash:
			return args

	# 这个实际上只是为了装备上显示正确的伤害
	for set_id in explode_sets:
		for set in args.sets:
			if set.my_id_hash == set_id:
				var explode_effect = null
				if from_stats is MeleeWeaponStats:
					explode_effect = load(FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_MELEE)
				else:
					explode_effect = load(FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_RANGED)
				_foxlab_weapon_class_explode_args.sets = args.sets
				_foxlab_weapon_class_explode_args.from = args.from
				_foxlab_weapon_class_explode_args.effects = args.effects.duplicate()
				_foxlab_weapon_class_explode_args.effects.append(explode_effect)
				return _foxlab_weapon_class_explode_args
	return args
