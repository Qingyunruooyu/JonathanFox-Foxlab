extends "res://global/entity_spawner.gd"

var foxlab_pets_structures_node_data_map = {}

const FOXLAB_CHARMED_PROJ_ORIGINAL_META: = "foxlab_charmed_original"

##### 扩展 #####
func on_group_spawn_timing_reached(group_data: WaveGroupData) -> void :
	if group_data.is_neutral:
		for player_index in RunData.get_player_count():
			if RunData.get_player_effect_bool(Utils.foxlab_no_trees_hash, player_index):
				return
	.on_group_spawn_timing_reached(group_data)

func get_nb_bosses_and_elites_alive() -> int:
	var boss_num = .get_nb_bosses_and_elites_alive()
	# 异变或者水滴石穿出来的BOSS，不在bosses里面
	if RunData.current_wave == RunData.nb_of_waves:
		for enemy in enemies:
			if enemy is Boss and not enemy in charmed_enemies:
				boss_num += 1
	return boss_num

func on_enemy_charmed(enemy: Entity) -> void :
	.on_enemy_charmed(enemy)
	var is_boss = enemy is Boss
	for effect_behavior in enemy.effect_behaviors.get_children():
		if not "charmed" in effect_behavior:
			continue
		for proj in enemy._all_additional_projectiles:
			if is_instance_valid(proj):
				proj.set_meta(FOXLAB_CHARMED_PROJ_ORIGINAL_META, [proj._hitbox.collision_layer, proj._sprite.material])
				proj.set_collision_layer(Utils.PET_PROJECTILES_BIT)
				var new_shader = effect_behavior.projectile_shader.duplicate()
				new_shader.set_shader_param("hue", Utils.CHARM_COLOR.h)
				proj.set_sprite_material(new_shader)
		if is_boss:
			effect_behavior._charm_timer.start(max(_wave_timer.time_left - 5, Utils.CHARM_DURATION))

func _on_enemy_died(enemy: Node2D, _args: Entity.DieArgs) -> void :
	._on_enemy_died(enemy, _args)
	for proj in enemy._all_additional_projectiles:
		if is_instance_valid(proj) and proj.has_meta(FOXLAB_CHARMED_PROJ_ORIGINAL_META):
			var original = proj.get_meta(FOXLAB_CHARMED_PROJ_ORIGINAL_META)
			proj.set_collision_layer(original[0])
			proj.set_sprite_material(original[1])
			proj.remove_meta(FOXLAB_CHARMED_PROJ_ORIGINAL_META)

func spawn_entity(scene: PackedScene, args: SpawnEntityArgs, data: Resource = null, source = null, charmed_by: int = - 1) -> KinematicBody2D:
	if args.type == EntityType.ENEMY or args.type == EntityType.BOSS:
		if not scene.get_instance_id() in ItemService.foxlab_enemy_seed_effect_map:
			var effect = load("res://mods-unpacked/JonathanFox-FoxLab/contents/consumables/seed/seed_effect.gd").new()
			effect.enemy_to_spawn = scene
			ItemService.foxlab_enemy_seed_effect_map[scene.get_instance_id()] = effect

	var entity = .spawn_entity(scene, args, data, source, charmed_by)
	if entity is Structure or entity is Pet:
		Utils.foxlab_pets_structures_pool_id_scene_map[entity.pool_id] = scene
		foxlab_pets_structures_node_data_map[entity] = data
	if ItemService.foxlab_is_android and entity is Enemy and entity.enemy_id_hash == Utils.foxlab_evil_mob_hash:
		entity.evolve(0)
		entity.gold_count = 0
		entity.on_health_updated(entity, entity.current_stats.health, entity.max_stats.health)

	if args.type == EntityType.PET and data.is_structure:
		RunData.foxlab_current_living_structures += 1

	return entity
