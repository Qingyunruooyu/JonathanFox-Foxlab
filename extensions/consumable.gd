extends "res://items/consumables/consumable.gd"

var foxlab_seed_timer = null

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

	for effect in consumable_data.effects:
		if effect.get_id() == "foxlab_seed":
			if foxlab_seed_timer == null:
				foxlab_seed_timer = Timer.new()
				foxlab_seed_timer.one_shot = true
				add_child(foxlab_seed_timer)
				var _err = foxlab_seed_timer.connect("timeout", self, "on_foxlab_seed_timer_timeout")
			foxlab_seed_timer.wait_time = Utils.FOXLAB_SEED_DURATION + RunData.current_living_enemies / Utils.FOXLAB_LIVING_ENEMY_DURATION_BOOST
			foxlab_seed_timer.start()
			break

func reset() -> void :
	.reset()
	if foxlab_seed_timer and !foxlab_seed_timer.is_stopped():
		# print("stop the timer, my_id: ", consumable_data.my_id, self)
		foxlab_seed_timer.stop()

func on_foxlab_seed_timer_timeout():
	if not already_picked_up:
		var main = Utils.get_scene_node()
		already_picked_up = true
		main._consumables.erase(self)
		main.add_node_to_pool(self, main._consumable_pool_id)
		# print("disappear, id: ", consumable_data.my_id, self)
		reset()
