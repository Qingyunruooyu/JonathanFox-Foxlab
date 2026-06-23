extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_batch_apply"

func apply_effects_core(_player_index: int, _call_func: String):
	assert(false, "must be inherited")

func apply(player_index: int) -> void:
	apply_effects_core(player_index, "apply")

func unapply(player_index: int) -> void:
	apply_effects_core(player_index, "unapply")


