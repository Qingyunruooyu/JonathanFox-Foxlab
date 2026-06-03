extends "res://global/entity_spawner.gd"

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
	if ItemService.foxlab_is_android and enemy is Boss:
		for effect_behavior in enemy.effect_behaviors.get_children():
			if "charmed" in effect_behavior:
				effect_behavior._charm_timer.start(max(_wave_timer.time_left - 5, Utils.CHARM_DURATION))

func spawn_entity(scene: PackedScene, args: SpawnEntityArgs, data: Resource = null, source = null, charmed_by: int = - 1) -> KinematicBody2D:
	if args.type == EntityType.ENEMY or args.type == EntityType.BOSS:
		if not scene.get_instance_id() in Utils.foxlab_enemy_id_scene_map:
			var effect = load("res://mods-unpacked/JonathanFox-FoxLab/contents/consumables/seed/seed_effect.gd").new()
			effect.enemy_to_spawn = scene
			Utils.foxlab_enemy_id_scene_map[scene.get_instance_id()] = effect

	var entity = .spawn_entity(scene, args, data, source, charmed_by)
	if ItemService.foxlab_is_android and entity is Enemy and entity.enemy_id_hash == Utils.foxlab_evil_mob_hash:
		entity.evolve(0)
		entity.gold_count = 0
		entity.on_health_updated(entity, entity.current_stats.health, entity.max_stats.health)

	if args.type == EntityType.PET and data.is_structure:
		RunData.foxlab_current_living_structures += 1

	return entity
