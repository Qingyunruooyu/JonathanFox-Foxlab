extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

onready var _foxlab_item_popup = $"%ItemPopup"

func _ready():
	if player_index >= RunData.get_player_count():
		return
	if _foxlab_item_popup == null:
		# 加这个Control让界面不要晃动
		var ctrl = Control.new()
		add_child(ctrl)
		var popup = load("res://ui/menus/shop/item_popup.tscn")
		_foxlab_item_popup = popup.instance()
		ctrl.add_child(_foxlab_item_popup)
		_foxlab_item_popup.visible = false
		_foxlab_item_popup.player_index = player_index

	for ui in _get_upgrade_uis():
		ui.connect("foxlab_hovered", self, "on_upgrade_hovered")
		ui.connect("foxlab_left", self, "on_item_left")

	_take_button.connect("focus_entered", self, "on_item_hovered")
	_take_button.connect("mouse_entered", self, "on_item_hovered")
	_take_button.connect("focus_exited", self, "on_item_left")
	_take_button.connect("mouse_exited", self, "on_item_left")

func on_upgrade_hovered(upgrade_data: UpgradeData, control: Control):
	if upgrade_data.has_meta("foxlab_item"):
		_foxlab_item_popup.display_item_data(upgrade_data.get_meta("foxlab_item"), control._upgrade_description._name)
		if RunData.is_coop_run:
			_foxlab_item_popup._panel.show()
		else:
			_foxlab_item_popup._panel.hide()


func on_item_hovered():
	if _item_data is ItemData:
		_foxlab_item_popup.display_item_data(_item_data, _item_description._name)
		# 只显示佛手等道具的备注信息，因为本体信息是_item_description显示的
		_foxlab_item_popup._panel.hide()

func on_item_left():
	_foxlab_item_popup.hide()

func show_item(item_data: ItemParentData) -> void :
	.show_item(item_data)
	on_item_hovered()
