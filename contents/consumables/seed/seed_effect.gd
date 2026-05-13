extends "res://effects/weapons/null_effect.gd"

var enemy_to_spawn = null

static func get_id() -> String:
	return "foxlab_seed"

func apply(player_index: int) -> void :
	var main = Utils.get_scene_node()
	if main._cleaning_up or enemy_to_spawn == null:
		 return
	var entity_spawner = main._entity_spawner
	var source_spawner = null
	var pos = null
	if player_index >= 0:
		source_spawner = main._players[player_index]
		pos = ZoneService.get_rand_pos_in_area(Vector2(source_spawner.global_position.x, source_spawner.global_position.y), 200)
		RunData.add_tracked_value(player_index, Utils.item_foxlab_salvation_hash, 1, 2)
	else:
		pos = ZoneService.get_rand_pos()
	entity_spawner.on_enemy_wanted_to_spawn_an_enemy(enemy_to_spawn, pos, source_spawner, player_index)


