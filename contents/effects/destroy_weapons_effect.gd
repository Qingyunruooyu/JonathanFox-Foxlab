extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_destroy_weapons"

func apply(player_index: int) -> void:
	RunData.remove_all_weapons(player_index)

func unapply(_player_index: int) -> void:
	pass
