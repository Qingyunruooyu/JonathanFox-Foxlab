extends "res://items/consumables/consumable.gd"

func drop(pos: Vector2, p_rotation: float, p_push_back_destiation: Vector2) -> void :
	.drop(pos, p_rotation, p_push_back_destiation)
	var main = Utils.get_scene_node()
	if has_damage_effect():
		for player in main._get_shuffled_live_players():
			var instant_attracting = RunData.get_player_effect(Utils.foxlab_instant_poisoned_attracting_hash, player.player_index)
			if instant_attracting > 0 and randf() < instant_attracting / 100.0:
				attracted_by = player
				set_physics_process(true)
				break

	for effect in consumable_data.effects:
		if effect.get_id() == "foxlab_seed":
			yield(get_tree().create_timer(Utils.FOXLAB_SEED_DURATION + RunData.current_living_enemies / Utils.FOXLAB_LIVING_ENEMY_DURATION_BOOST), "timeout")
			if not already_picked_up:
				# 没来得及拾取，变成敌方单位
				# effect.apply(-1)
				already_picked_up = true
				main._consumables.erase(self)
				main.add_node_to_pool(self, main._consumable_pool_id)
			break
