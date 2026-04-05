extends "res://ui/menus/ingame/coop_upgrades_ui_player_container.gd"

func on_upgrade_hovered(upgrade_data: UpgradeData, control: Control):
	if upgrade_data.has_meta("foxlab_item"):
		item_popup.display_item_data(upgrade_data.get_meta("foxlab_item"), control)

func on_upgrade_left():
	item_popup.hide()

func _ready() -> void :
	for ui in [_upgrade_ui_1, _upgrade_ui_2, _upgrade_ui_3, _upgrade_ui_4]:
		ui.connect("foxlab_hovered", self, "on_upgrade_hovered")
		ui.connect("foxlab_left", self, "on_upgrade_left")
