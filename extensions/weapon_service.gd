extends "res://singletons/weapon_service.gd"

const FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_MELEE = "res://mods-unpacked/JonathanFox-FoxLab/contents/items/characters/jellyfish/jellyfish_explode_melee_effect.tres"
const FOXLAB_WEAPON_CLASS_EXPLODE_EFFECT_RANGED = "res://mods-unpacked/JonathanFox-FoxLab/contents/items/characters/jellyfish/jellyfish_explode_ranged_effect.tres"

var _foxlab_weapon_class_explode_args = WeaponServiceInitStatsArgs.new()

### 扩展 ###
func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure= false, is_special_spawn= false, is_pet= false) -> WeaponStats:
	args = foxlab_merge_burning_effects(args)
	args = foxlab_add_weapon_class_explode_stats(from_stats, player_index, args)
	var new_stats = .init_base_stats(from_stats, player_index, args, is_structure, is_special_spawn, is_pet)
	# 命中率超过100%反而会降低命中率，不合理
	new_stats.accuracy = min(1.0, new_stats.accuracy)
	# 原版中 构筑物+宠物 的道具，暴击率和生命窃取按构筑物来算了，比如布雷机器人要有一堆书才能暴击，并且无法生命窃取，这是不对的
	if is_structure and is_pet:
		var corrected_stats = .init_base_stats(from_stats, player_index, args, false, is_special_spawn, is_pet)
		new_stats.lifesteal = corrected_stats.lifesteal
		new_stats.crit_chance = corrected_stats.crit_chance
		new_stats.crit_damage = corrected_stats.crit_damage

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

# 玩家池与武器侧的每X投射效果按X分组合并，键为X，值为该X下全部效果
func foxlab_group_every_x_effects(player_index: int, weapon_effects: Array) -> Dictionary:
	var all_effects = []
	all_effects.append_array(RunData.get_player_effect(Keys.modify_every_x_projectile_hash, player_index))
	for effect in weapon_effects:
		if effect is WeaponEffectWithSubEffects:
			all_effects.append(effect)
	var groups = {}
	for effect in all_effects:
		if not groups.has(effect.value):
			groups[effect.value] = []
		groups[effect.value].append(effect)
	return groups

# 原版每个效果独立快照后按X直接覆盖字典：同X效果互相覆盖只剩一个，spread还跨效果累加泄漏；
# 这里按X分组，同组sub_effects全部apply后一次快照，spread只计本组投射物增量
func init_stats_every_x_projectiles(base_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs) -> Dictionary:
	var groups = foxlab_group_every_x_effects(player_index, args.effects)
	var stats_every_x_shots = {}
	for x in groups:
		var nb_projectile_effect = 0
		for effect in groups[x]:
			for sub_effect in effect.sub_effects:
				sub_effect.apply(player_index)
				if sub_effect.key_hash == Keys.projectiles_hash:
					nb_projectile_effect += sub_effect.value
		var modified_stats: RangedWeaponStats = init_ranged_stats(base_stats, player_index, false, args)
		modified_stats.projectile_spread += nb_projectile_effect * 0.15
		stats_every_x_shots[x] = modified_stats
		for effect in groups[x]:
			for sub_effect in effect.sub_effects:
				sub_effect.unapply(player_index)
	return stats_every_x_shots

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
	if (from is Weapon or from.has_method("on_bonus_gold_converted")) and from.effects.size() > 0 and not projectile.killed_something_connected:
		call_deferred("foxlab_connect_signal_for_projectile", from, projectile)
	return projectile

func init_burning_data(base_burning_data: BurningData, player_index: int, is_structure: bool = false, is_pet: bool = false) -> BurningData:
	var burning_scaling_stat_effects = RunData.get_player_effect(Utils.foxlab_burning_scaling_stats_hash, player_index)
	if not burning_scaling_stat_effects.empty():
		base_burning_data = base_burning_data.duplicate()
		base_burning_data.scaling_stats = foxlab_apply_scaling_stat_effects(burning_scaling_stat_effects, base_burning_data.scaling_stats, false)

	var new_burning_data = .init_burning_data(base_burning_data, player_index, is_structure, is_pet)

	# 燃烧能爆炸时，重新加算爆炸伤害
	if not new_burning_data.is_not_burning() and not RunData.get_player_effect(Utils.foxlab_explode_on_burn_hash, player_index).empty():
		var global_burning = RunData.get_player_effect(Keys.burn_chance_hash, player_index)
		var base_damage = global_burning.damage
		if not new_burning_data.is_global_burn:
			base_damage += base_burning_data.damage

		var percent_dmg_bonus = (1 + (Utils.get_stat(Keys.stat_percent_damage_hash, player_index) / 100.0))
		if is_structure:
			if is_pet:
				percent_dmg_bonus += Utils.get_stat(Keys.structure_percent_damage_hash, player_index) / 100.0
			else:
				percent_dmg_bonus = (1 + (Utils.get_stat(Keys.structure_percent_damage_hash, player_index) / 100.0))
		var exploding_dmg_bonus = (Utils.get_stat(Keys.explosion_damage_hash, player_index) / 100.0)

		if is_pet or not is_structure: # 和 get_explosion_damage 一致
			new_burning_data.scaling_stats = _apply_weapon_scaling_stat_effects(new_burning_data.scaling_stats, player_index)
		base_damage =  apply_scaling_stats_to_damage(base_damage, new_burning_data.scaling_stats, player_index)

		new_burning_data.damage = max(1, round(base_damage * (percent_dmg_bonus + exploding_dmg_bonus))) as int

	return new_burning_data

### 功能 ###
func foxlab_merge_burning_effects(args: WeaponServiceInitStatsArgs) -> WeaponServiceInitStatsArgs:
	var first_index = -1
	var extra_effects = []
	for i in range(args.effects.size()):
		if args.effects[i] is BurningEffect:
			if first_index == -1:
				first_index = i
			else:
				extra_effects.append(args.effects[i])
	if extra_effects.empty():
		return args

	var new_args = WeaponServiceInitStatsArgs.new()
	new_args.sets = args.sets
	new_args.from = args.from
	new_args.effects = args.effects.duplicate()
	var merged_effect = args.effects[first_index].duplicate()
	merged_effect.burning_data = args.effects[first_index].burning_data.duplicate()
	for extra_effect in extra_effects:
		merged_effect.burning_data.merge(extra_effect.burning_data)
	new_args.effects[first_index] = merged_effect
	for i in range(new_args.effects.size() - 1, -1, -1):
		if i != first_index and new_args.effects[i] is BurningEffect:
			new_args.effects.remove(i)
	return new_args

func foxlab_merge_projectiles_on_hit(effects: Array, player_index: int, init_first_stats: bool) -> Array:
	var on_hit_count = 0
	var first_stats = null
	var auto_target = false
	var on_hit_args = WeaponServiceInitStatsArgs.new()
	for effect in effects:
		if effect is ProjectilesOnHitEffect:
			if first_stats == null:
				if init_first_stats:
					first_stats = init_ranged_stats(effect.weapon_stats, player_index, true, on_hit_args)
				else:
					first_stats = effect.weapon_stats
			auto_target = auto_target or effect.auto_target_enemy
			on_hit_count += effect.value
	if first_stats == null:
		return []
	return [on_hit_count, first_stats, auto_target]

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

func foxlab_apply_scaling_stat_effects(extra_scaling_stat: Array, scaling_stats: Array, sub: bool) -> Array:
	if extra_scaling_stat.empty():
		return scaling_stats
	var new_scaling_stats = scaling_stats.duplicate(true)
	for scaling_stat_effect in extra_scaling_stat:
		assert (scaling_stat_effect[0] is int)
		var scaling_stat_hash = scaling_stat_effect[0]
		var scaling_stat_value = scaling_stat_effect[1] / 100.0
		if sub:
			scaling_stat_value *= -1
		var existing_scaling_stat = find_scaling_stat(scaling_stat_hash, new_scaling_stats)
		if existing_scaling_stat != null:
			existing_scaling_stat[1] += scaling_stat_value
		else:
			new_scaling_stats.push_back([scaling_stat_hash, scaling_stat_value])
	return new_scaling_stats

# 同炮同时命中多个X时的组合快照：命中组的sub_effects全部apply后一次构建，spread计全部命中组的投射物增量
# matched来自init时构建的字典键，波内玩家池可能已变化，组缺失时跳过该组
func foxlab_build_combined_every_x_stats(weapon, matched) -> RangedWeaponStats:
	var groups = foxlab_group_every_x_effects(weapon.player_index, weapon.effects)
	var matched_effects = []
	for x in matched:
		if groups.has(x):
			matched_effects.append_array(groups[x])

	var nb_projectile_effect = 0
	for effect in matched_effects:
		for sub_effect in effect.sub_effects:
			sub_effect.apply(weapon.player_index)
			if sub_effect.key_hash == Keys.projectiles_hash:
				nb_projectile_effect += sub_effect.value

	var args = WeaponServiceInitStatsArgs.new()
	args.sets = weapon.weapon_sets
	args.effects = weapon.effects
	var combined: RangedWeaponStats = init_ranged_stats(weapon.stats, weapon.player_index, false, args)
	combined.projectile_spread += nb_projectile_effect * 0.15

	for effect in matched_effects:
		for sub_effect in effect.sub_effects:
			sub_effect.unapply(weapon.player_index)
	return combined
