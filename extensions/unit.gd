extends "res://entities/units/unit/unit.gd"

func _on_BurningTimer_timeout() -> void :
	if _burning != null and RunData.get_nb_item(Utils.character_foxlab_nyuba_hash, _burning_player_index) > 0:
		var nb_nyuba = RunData.get_nb_item(Utils.character_foxlab_nyuba_hash, _burning_player_index)
		if not _burning.is_global_burn:
			._on_BurningTimer_timeout()
			RunData.add_tracked_value(_burning_player_index, Utils.character_foxlab_nyuba_hash, nb_nyuba)
		else:
			var nb_sausage = RunData.get_nb_item(Keys.item_scared_sausage_hash, _burning_player_index)
			var tracked_effects = RunData.tracked_item_effects[_burning_player_index]
			var before_sausage = tracked_effects[Keys.item_scared_sausage_hash]
			._on_BurningTimer_timeout()
			var after_sausage = tracked_effects[Keys.item_scared_sausage_hash]
			var diff = after_sausage - before_sausage
			var nyuba_value = diff * nb_nyuba / (nb_nyuba + nb_sausage)
			var sausage_value = diff - nyuba_value
			RunData.add_tracked_value(_burning_player_index, Utils.character_foxlab_nyuba_hash, nyuba_value)
			RunData.set_tracked_value(_burning_player_index, Keys.item_scared_sausage_hash, before_sausage + sausage_value)
	else:
		._on_BurningTimer_timeout()
