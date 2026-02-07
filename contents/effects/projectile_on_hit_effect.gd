class_name FoxLabProjectileOnHitEffect
extends "res://effects/items/projectile_effect.gd"

export(Array, String) var effects = []
export(String) var tracking_key = ""
var tracking_key_hash: int = Keys.empty_hash

static func get_id() -> String:
	return "foxlab_effect_projectile_on_hit"

func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)
	if tracking_key_hash == Keys.empty_hash and tracking_key != "":
		tracking_key_hash = Keys.generate_hash(tracking_key)
	duplication.tracking_key_hash = self.tracking_key_hash
	return duplication

func _generate_hashes() -> void:
	._generate_hashes()
	tracking_key_hash = Keys.generate_hash(tracking_key)

func apply(player_index: int) -> void:
	var effect: Array = RunData.get_player_effect(key_hash, player_index)
	var first_apply = effect.empty()
	.apply(player_index)
	if first_apply:
		effect.append_array([effects, tracking_key_hash])

func unapply(player_index: int) -> void:
	var effect: Array = RunData.get_player_effect(key_hash, player_index)
	if effect[0] - value <= 0:
		effect.clear()
	else:
		.unapply(player_index)

func get_args(player_index: int) -> Array:
	var weapon_args = WeaponServiceInitStatsArgs.new()
	for effect in effects:
		weapon_args.effects.append(load(effect))
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true, weapon_args)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(weapon_stats.scaling_stats)

	var effect: Array = RunData.get_player_effect(key_hash, player_index)
	var new_num =  RunData.get_player_effect(Utils.foxlab_projectile_on_hit_num_hash, player_index)
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
	tracking_key_hash = Keys.generate_hash(tracking_key)
