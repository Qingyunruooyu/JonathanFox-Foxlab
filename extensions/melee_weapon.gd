extends "res://weapons/melee/melee_weapon.gd"

func queue_free():
	Utils.foxlab_queue_free_weapon(self)
