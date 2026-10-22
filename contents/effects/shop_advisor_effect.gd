extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_shop_advisor"

func apply(player_index: int) -> void:
	Utils.foxlab_try_analyze_shop_advisor(player_index)
	Utils.foxlab_sync_shop_advisor(player_index)

func unapply(player_index: int) -> void:
	Utils.foxlab_clear_shop_advisor(player_index)

func get_args(player_index: int) -> Array:
	Utils.foxlab_try_analyze_shop_advisor(player_index)
	var item = Utils.foxlab_get_shop_advisor_item(player_index)
	return [tr(item.name) if item != null else "-"]
