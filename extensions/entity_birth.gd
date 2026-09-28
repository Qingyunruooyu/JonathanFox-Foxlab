extends "res://entities/birth/entity_birth.gd"

var foxlab_entered_players = []

func start(p_type: int, p_scene: PackedScene, pos: Vector2, p_data: Resource = null, p_player_index: = - 1, p_source = null, p_charmed_by: = - 1) -> void :
	.start(p_type, p_scene, pos, p_data, p_player_index, p_source, p_charmed_by)
	foxlab_entered_players.clear()

func _on_EntityBirth_body_entered(body: Node) -> void :
	._on_EntityBirth_body_entered(body)

	if not (body is Player):
		return

	if not (type == EntityType.ENEMY or type == EntityType.BOSS):
		return

	var player_index: int = body.player_index
	if player_index in foxlab_entered_players:
		return
	foxlab_entered_players.append(player_index)
	foxlab_process_copy_weapon_on_summon_birth(body, player_index)
	foxlab_process_spawn_landmine(body, player_index)

func foxlab_process_copy_weapon_on_summon_birth(player, player_index: int) -> void :
	if not (charmed_by < 0 and is_instance_valid(source) and source is Enemy):
		return

	# 觉醒之后，只能复制危机个数次的武器
	if RunData.get_player_effect_bool(Utils.item_foxlab_trouble_mutation_hash, player_index) and\
		player.foxlab_temp_weapons.size() >= RunData.get_player_effect(Utils.foxlab_troubleshooter_crisis_num_hash, player_index):
		return

	var copy_effects = RunData.get_player_effect(Utils.foxlab_copy_weapon_on_summon_birth_hash, player_index)
	if copy_effects.empty():
		return

	var weapons_ref = RunData.get_player_weapons_ref(player_index)
	if weapons_ref.empty():
		return

	for effect_entry in copy_effects:
		var stat_key: int = effect_entry[0]
		var stat_delta: int = effect_entry[1]
		var weapon_count: int = effect_entry[2]

		for _i in weapon_count:
			player.foxlab_add_temp_weapon( Utils.get_rand_element(weapons_ref))
		if stat_delta != 0:
			TempStats.add_stat(stat_key, stat_delta, player_index)


# 踩到敌人出生点生成可反复爆炸的地雷（每波最多FOXLAB_MOM_LANDMINE_MAX_PER_WAVE个，魅惑的除外）
func foxlab_process_spawn_landmine(player, player_index: int) -> void :
	if charmed_by > 0:
		return

	var count: int = RunData.get_player_effect(Utils.foxlab_spawn_landmine_on_entering_birth_area_hash, player_index)
	if count <= 0:
		return

	var to_spawn: int = min(count, Utils.FOXLAB_MOM_LANDMINE_MAX_PER_WAVE - player.foxlab_mom_landmine_spawned_this_wave) as int
	if to_spawn <= 0:
		return
	player.foxlab_mom_landmine_spawned_this_wave += to_spawn

	var main = Utils.get_scene_node()
	if main == null or main._entity_spawner == null:
		return

	if player.foxlab_mom_landmine_effect == null:
		player.foxlab_mom_landmine_effect = load(player.FOXLAB_MOM_LANDMINE_EFFECT_PATH).duplicate()
		player.foxlab_mom_landmine_effect.scene = load(player.FOXLAB_MOM_LANDMINE_REUSABLE_SCENE_PATH)

	for _i in to_spawn:
		var pos = main._entity_spawner.get_spawn_pos_in_area(global_position, 200)
		var queue = main._entity_spawner.queues_to_spawn_structures[player_index]
		queue.push_back([EntityType.STRUCTURE, player.foxlab_mom_landmine_effect.scene, pos, player.foxlab_mom_landmine_effect])
