extends "res://items/consumables/consumable.gd"

func drop(pos: Vector2, p_rotation: float, p_push_back_destiation: Vector2) -> void :
	.drop(pos, p_rotation, p_push_back_destiation)
	if has_damage_effect():
		var main = Utils.get_scene_node()
		for player in main._get_shuffled_live_players():
			var instant_attracting = RunData.get_player_effect(Utils.foxlab_instant_poisoned_attracting_hash, player.player_index)
			if instant_attracting > 0 and randf() < instant_attracting / 100.0:
				attracted_by = player
				set_physics_process(true)
				break