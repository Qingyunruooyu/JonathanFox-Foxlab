extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_extra_bosses"

func get_args(_player_index: int) -> Array:
	return [str(Utils.FOXLAB_BOSS_INTERVAL), str(Utils.FOXLAB_BOSS_SPAWN_NUM * value), str(Utils.FOXLAB_BOSS_SPAWN_CHANCE)]

