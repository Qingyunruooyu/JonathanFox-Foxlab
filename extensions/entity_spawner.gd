extends "res://global/entity_spawner.gd"

var foxlab_enemy_connected_signal = {}
var foxlab_should_connect_signal = false

##### 新功能 #####
func _on_foxlab_area_entered_deferred(hitbox: Area2D, enemy: Node2D):
	if not enemy._pending_die and hitbox.active and hitbox.deals_damage and\
		is_instance_valid(hitbox.from) and not hitbox.from is PlayerExplosion and\
		hitbox.from.player_index != -1:
		var extra_hit:int = RunData.get_player_effect(Utils.foxlab_extra_hit_hash, hitbox.from.player_index)
		if extra_hit > 1:
			var ignored_objects = hitbox.ignored_objects.duplicate()
			for _i in extra_hit:
				hitbox.ignored_objects.erase(enemy)
				enemy.hurt_area_entered_deferred(hitbox)
				if not hitbox.active:
					break
			hitbox.ignored_objects = ignored_objects

func _on_foxlab_Hurtbox_entered(hitbox: Area2D, enemy: Node2D):
	call_deferred("_on_foxlab_area_entered_deferred", hitbox, enemy)

##### 扩展 #####
func _ready() -> void :
	for i in RunData.get_player_count():
		if RunData.get_player_effect_bool(Utils.foxlab_extra_hit_hash, i):
			foxlab_should_connect_signal = true
			break

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

	if foxlab_should_connect_signal and (args.type == EntityType.ENEMY or args.type == EntityType.BOSS) and not entity.pool_id in foxlab_enemy_connected_signal:
		var hurtbox = entity.get_node("Hurtbox")
		if not hurtbox.is_connected("area_entered", self, "_on_foxlab_Hurtbox_entered"):
			var _err = hurtbox.connect("area_entered", self, "_on_foxlab_Hurtbox_entered", [entity])
			foxlab_enemy_connected_signal[entity.pool_id] = 1
	return entity
