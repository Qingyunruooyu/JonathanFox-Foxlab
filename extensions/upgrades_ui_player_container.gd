extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

var _foxlab_item_popup = null

func _ready():
	if has_meta("item_popup"):
		_foxlab_item_popup = get_meta("item_popup")
	else:
		# 加这个Control让界面不要晃动
		var ctrl = Control.new()
		add_child(ctrl)
		var popup = load("res://ui/menus/shop/item_popup.tscn")
		_foxlab_item_popup = popup.instance()
		ctrl.add_child(_foxlab_item_popup)
		_foxlab_item_popup.visible = false

	for ui in _get_upgrade_uis():
		ui.connect("foxlab_hovered", self, "on_upgrade_hovered")
		ui.connect("foxlab_left", self, "on_item_left")

	for button in [_take_button, _discard_button,_ban_button]:
		button.connect("focus_entered", self, "on_item_hovered")
		button.connect("mouse_entered", self, "on_item_hovered")
		button.connect("focus_exited", self, "on_item_left")
		button.connect("mouse_exited", self, "on_item_left")

func on_upgrade_hovered(upgrade_data: UpgradeData, control: Control):
	if upgrade_data.has_meta("foxlab_item"):
		_foxlab_item_popup.display_item_data(upgrade_data.get_meta("foxlab_item"), control)
		if RunData.is_coop_run:
			_foxlab_item_popup._panel.show()
		else:
			_foxlab_item_popup._panel.hide()


func on_item_hovered():
	if _item_data is ItemData:
		_foxlab_item_popup.display_item_data(_item_data, _item_description)
		_foxlab_item_popup._panel.hide()

func on_item_left():
	_foxlab_item_popup.hide()


