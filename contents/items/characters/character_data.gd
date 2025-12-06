extends CharacterData

const MOD_CHARACTERS = ["character_foxlab_refactor"]
func _get_tracking_text(player_index: int) -> String:
	if not my_id in MOD_CHARACTERS:
		return ._get_tracking_text(player_index)
	var text : String = ""
	if player_index != RunData.DUMMY_PLAYER_INDEX :
		for i in RunData.tracked_item_effects[player_index][my_id].size():
			var tracked_count = RunData.tracked_item_effects[player_index][my_id][i]

			var tracking_text_to_use = tracking_text

			if my_id == "character_foxlab_refactor" and i == 1:
				tracking_text_to_use = "FOXLAB_MODIFICATION_GAINED"

			text += "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text_to_use.to_upper(), [Text.get_formatted_number(tracked_count)]) + "[/color]"
	return text
