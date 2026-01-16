extends ItemData

const MOD_ITEMS = ["item_foxlab_inner_indomitable", "character_foxlab_refactor", "item_foxlab_reactor"]
static func foxlab_get_tracking_text(item_id: String, tracking_text: String,  player_index: int) -> String:
	var text : String = ""
	if player_index != RunData.DUMMY_PLAYER_INDEX :
		for i in RunData.tracked_item_effects[player_index][item_id].size():
			var tracked_count = RunData.tracked_item_effects[player_index][item_id][i]

			var tracking_text_to_use = tracking_text

			if item_id == "item_foxlab_inner_indomitable" and i == 1:
				tracking_text_to_use = "MATERIALS_GAINED"
			elif item_id == "character_foxlab_refactor" and i == 1:
				tracking_text_to_use = "FOXLAB_MODIFICATION_GAINED"
			elif item_id == "item_foxlab_reactor":
				if i == 1:
					tracking_text_to_use = "FOXLAB_BOSSES_INVOKED"
				elif i == 2:
					tracking_text_to_use = "FOXLAB_BOSSES_RESURRECTED"

			text += "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text_to_use.to_upper(), [Text.get_formatted_number(tracked_count)]) + "[/color]"
	return text

func _get_tracking_text(player_index: int) -> String:
	if not my_id in MOD_ITEMS:
		return ._get_tracking_text(player_index)
	return foxlab_get_tracking_text(my_id, tracking_text, player_index)
