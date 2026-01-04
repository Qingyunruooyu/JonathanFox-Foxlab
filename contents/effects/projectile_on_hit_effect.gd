class_name FoxLabProjectileOnHitEffect
extends ProjectileEffect

export(Array, String) var effects = []
export(String) var tracking_key = ""

static func get_id() -> String:
	return "foxlab_effect_projectile_on_hit"

func apply(player_index: int) -> void:
	.apply(player_index)
	var effect: Array = RunData.get_player_effect(key, player_index)
	effect.append_array([effects, tracking_key])

func get_args(player_index: int) -> Array:
	var weapon_args = WeaponServiceInitStatsArgs.new()
	for effect in effects:
		weapon_args.effects.append(load(effect))
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true, weapon_args)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(weapon_stats.scaling_stats)

	var effect: Array = RunData.get_player_effect(key, player_index)
	var new_num =  RunData.get_player_effect("foxlab_projectile_on_hit_num", player_index)
	if effect.empty():
		new_num += value
	else:
		new_num += effect[0]
	return [str(new_num), str(current_stats.damage), str(current_stats.bounce + 1), scaling_text, str(cooldown)]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.effects = effects
	serialized.tracking_key = tracking_key
	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	effects = serialized.effects
	tracking_key = serialized.tracking_key
