extends "res://entities/units/enemies/crash_zone/basic/evil_mob/evil_mob.gd"

func respawn() -> void :
	.respawn()
	evolve(0)
	gold_count = 0
	on_health_updated(self, current_stats.health, max_stats.health)


