extends "res://projectiles/player_explosion.gd"

func end_explosion() -> void :
	Utils.disconnect_all_signal_connections(self, "killed_something")
	.end_explosion()
