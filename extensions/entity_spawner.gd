extends "res://global/entity_spawner.gd"

var foxlab_pets_structures_node_data_map = {}

func foxlab_register_builder_turret(entity) -> void:
	if Utils.foxlab_is_builder_turret(entity):
		_main.foxlab_get_builder_turret_manager().foxlab_register(entity)

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

func spawn_entity(scene: PackedScene, args: SpawnEntityArgs, data: Resource = null, source = null, charmed_by: int = - 1) -> KinematicBody2D:
	if args.type == EntityType.ENEMY or args.type == EntityType.BOSS:
		if not scene.get_instance_id() in ItemService.foxlab_enemy_seed_effect_map:
			var effect = load("res://mods-unpacked/JonathanFox-FoxLab/contents/consumables/seed/seed_effect.gd").new()
			effect.enemy_to_spawn = scene
			ItemService.foxlab_enemy_seed_effect_map[scene.get_instance_id()] = effect

	var entity = .spawn_entity(scene, args, data, source, charmed_by)
	if args.type == EntityType.STRUCTURE:
		foxlab_register_builder_turret(entity)
	if entity is Structure or entity is Pet:
		Utils.foxlab_pets_structures_pool_id_scene_map[entity.pool_id] = scene
		foxlab_pets_structures_node_data_map[entity] = data

	if args.type == EntityType.PET and data.is_structure:
		RunData.foxlab_current_living_structures += 1

	return entity

