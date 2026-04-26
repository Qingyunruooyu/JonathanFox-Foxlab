extends "res://ui/menus/shop/tag_panel.gd"

func set_data(tag: String) -> bool:
	if not tag.begins_with("ITEM_FOXLAB"):
		return .set_data(tag)

	var data = tag.split(":")
	var name = data[0]
	var player_index = int(data[1])
	var is_cursed = int(data[2])

	_tag_name.text = tr(name)
	_tag_effects.bbcode_text = tr("TAG_DESCRIPTION_" + name)

	match name:
		"ITEM_FOXLAB_BUDDHAS_HAND":
			var meta = RunData.get_foxlab_buddhas_hand_meta(player_index)[is_cursed]
			if meta.weapon:
				_tag_effects.bbcode_text += "\n[color=#ff8c00]" + meta.weapon_id + "[/color]"
				_tag_effects.bbcode_text += "\n" + meta.weapon.get_weapon_stats_text(player_index)
				_tag_effects.bbcode_text += "\n" + meta.weapon.get_effects_text(player_index)
			if meta.item:
				_tag_effects.bbcode_text += "\n[color=#ff8c00]" + tr(meta.item.name) + "[/color]"
				_tag_effects.bbcode_text += "\n" + meta.item.get_effects_text(player_index)

		"ITEM_FOXLAB_MASK":
			var meta = RunData.get_foxlab_mask_meta(player_index)[is_cursed]
			var chars = meta.chars.duplicate()
			chars.shuffle()
			for character in chars:
				_tag_effects.bbcode_text += "\n[color=#ff8c00]" + tr(character.name) + "[/color]"
				_tag_effects.bbcode_text += "\n" + character.get_effects_text(player_index)

	if RunData.is_coop_run:
		if _tag_effects.text.length() >= 300:
			_tag_effects.add_font_override("normal_font", small_font)
		else:
			_tag_effects.add_font_override("normal_font", normal_font)

	show()
	return true
