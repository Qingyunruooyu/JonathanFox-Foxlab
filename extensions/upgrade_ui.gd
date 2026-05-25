extends "res://ui/menus/upgrades/upgrade_ui.gd"

signal foxlab_hovered(upgrade_data, control)
signal foxlab_left()

func on_foxlab_upgrade_hovered():
	emit_signal("foxlab_hovered", upgrade_data, self)

func on_foxlab_upgrade_left():
	emit_signal("foxlab_left")

func _ready():
	button.connect("focus_entered", self, "on_foxlab_upgrade_hovered")
	button.connect("mouse_entered", self, "on_foxlab_upgrade_hovered")
	button.connect("focus_exited", self, "on_foxlab_upgrade_left")
	button.connect("mouse_exited", self, "on_foxlab_upgrade_left")

func set_upgrade(p_upgrade_data: UpgradeData, player_index: int) -> void :
	.set_upgrade(p_upgrade_data, player_index)
	if RunData.is_coop_run:
		# 合作模式，只有标准升级会显示，特殊升级通过 _foxlab_item_popup 显示
		_upgrade_description.get_effects().visible = Utils.foxlab_is_vanilla_upgrade(p_upgrade_data)

