extends "res://ui/menus/shop/shop_item.gd"

onready var foxlab_material_icon = preload("res://items/materials/material_ui.png")

var _foxlab_steal_timer: Timer

func set_shop_item(p_item_data: ItemParentData, p_wave_value: int = RunData.current_wave)->void :
	.set_shop_item(p_item_data, p_wave_value)
	if !RunData.get_player_effect_bool(Keys.hp_shop_hash, player_index):
		if RunData.is_coop_run:
			_button.set_material_icon(foxlab_material_icon, CoopService.get_player_color(player_index))
		else:
			_button.set_material_icon(foxlab_material_icon, Utils.GOLD_COLOR)

func steal_item() -> void :
	#既能偷又能锁，则双击是偷，单击只会切换锁定
	if not _lock_button.disabled:
		if _foxlab_steal_timer == null:
			_foxlab_steal_timer = Timer.new()
			_foxlab_steal_timer.wait_time = 0.3
			_foxlab_steal_timer.one_shot = true
			add_child(_foxlab_steal_timer)
		if _foxlab_steal_timer.is_stopped():
			_foxlab_steal_timer.start()
			return
	.steal_item()