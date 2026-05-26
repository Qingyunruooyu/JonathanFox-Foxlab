extends "res://ui/menus/shop/coop_item_popup.gd"

func show_shop_hints(p_shop_item: ShopItem) -> void :
	.show_shop_hints(p_shop_item)
	if _coop_steal_hint.visible:
		if _coop_unlock_hint.visible or _coop_lock_hint.visible:
			_coop_steal_hint.set_text("FOXLAB_COOP_STEAL_HINT")
		else:
			_coop_steal_hint.set_text(_coop_steal_hint.text)

