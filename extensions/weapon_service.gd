extends "res://singletons/weapon_service.gd"
### 扩展 ###
func init_melee_stats(from_stats: MeleeWeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service) -> MeleeWeaponStats:
	var new_stats = .init_melee_stats(from_stats, player_index, args)
	new_stats.deal_dmg_on_return = from_stats.deal_dmg_on_return
	return new_stats

func _set_common_ranged_stats(new_stats: RangedWeaponStats, from_stats: RangedWeaponStats, player_index: int):
	._set_common_ranged_stats(new_stats, from_stats, player_index)
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

### 功能 ###
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
