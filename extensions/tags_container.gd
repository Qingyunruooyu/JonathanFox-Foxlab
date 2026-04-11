extends "res://ui/menus/shop/tags_container.gd"


func set_tags_text(item_data: ItemParentData, player_index: int) -> void :
	if item_data.my_id_hash != Utils.item_foxlab_mask_hash and item_data.my_id_hash != Utils.item_foxlab_buddhas_hand_hash:
		.set_tags_text(item_data, player_index)
		return
	rect_size = Vector2.ZERO

	var was_visible = visible
	if was_visible:
		hide()

	for panel in tag_panels:
		panel.hide()

	tag_panels[0].set_data(":".join([item_data.name, str(player_index), str(1 if item_data.is_cursed else 0)]))

	if was_visible:

		show()
