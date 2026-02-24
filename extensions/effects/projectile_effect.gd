extends "res://effects/items/projectile_effect.gd"

func unapply(player_index: int) -> void:
	var effect: Array = RunData.get_player_effect(key_hash, player_index)
	if effect[0] - value <= 0:
		effect.clear()
	else:
		.unapply(player_index)
