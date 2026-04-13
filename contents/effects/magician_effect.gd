extends "res://effects/weapons/null_effect.gd"

static func get_id() -> String:
	return "foxlab_magician"

func get_text(player_index: int, _colored: bool = true) -> String:
	var text:String = tr("EFFECT_FOXLAB_MAGICIAN") + "\n"

	var min_tier = clamp(RunData.get_player_effect(Keys.min_weapon_tier_hash, player_index), 0, 3)
	var max_tier = clamp(RunData.get_player_effect(Keys.max_weapon_tier_hash, player_index), 0, 3)

	var weapon_tier_str = ItemService.get_tier_number(min_tier) if min_tier else "I"
	if min_tier == max_tier:
		text += Text.text(tr("EFFECT_FOXLAB_TIER_X_WEAPON"), [weapon_tier_str], [Sign.NEGATIVE])
	else:
		var weapon_tier_str1 = ItemService.get_tier_number(max_tier) if max_tier else "I"
		text += Text.text(tr("EFFECT_FOXLAB_TIER_XY_WEAPON"), [weapon_tier_str, weapon_tier_str1], [Sign.NEGATIVE, Sign.POSITIVE])

	if RunData.get_player_effect_bool(Keys.hp_shop_hash, player_index):
		text += tr("EFFECT_FOXLAB_SEMICOLON") + '\n' + tr("EFFECT_HP_SHOP")

	if RunData.get_player_effect_bool(Keys.disable_item_locking_hash, player_index):
		text += tr("EFFECT_FOXLAB_SEMICOLON") + '\n' + tr("EFFECT_FOXLAB_SWITCH_ITEM_LOCKING")

	if RunData.get_player_effect_bool(Keys.item_steals_hash, player_index):
		text += tr("EFFECT_FOXLAB_SEMICOLON") + '\n' + Text.text(tr("EFFECT_ITEM_STEALS"), [str(RunData.get_player_effect(Keys.item_steals_hash, player_index))], [Sign.POSITIVE]) + tr("EFFECT_FOXLAB_STEAL_INIT")

	text += tr("EFFECT_FOXLAB_PERIOD")

	return text
