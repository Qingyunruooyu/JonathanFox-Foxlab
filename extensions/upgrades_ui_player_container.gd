extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

onready var _foxlab_item_popup = get_node_or_null("%ItemPopup")

var foxlab_current_ui = null

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
		ui.connect("foxlab_hovered", self, "on_foxlab_upgrade_hovered")
		ui.connect("foxlab_left", self, "on_foxlab_item_left")

	_take_button.connect("focus_entered", self, "on_foxlab_item_hovered")
	_take_button.connect("mouse_entered", self, "on_foxlab_item_hovered")
	_take_button.connect("focus_exited", self, "on_foxlab_item_left")
	_take_button.connect("mouse_exited", self, "on_foxlab_item_left")

func on_foxlab_upgrade_hovered(upgrade_data: UpgradeData, control: Control):
	foxlab_current_ui = control
	if not Utils.foxlab_is_vanilla_upgrade(upgrade_data):
		_foxlab_item_popup.display_item_data(upgrade_data.get_meta("foxlab_item", upgrade_data), control._upgrade_description._name)
		# 单人模式，不显示popup里面的item_description(panel的子节点)，只显示tag container
		# 合作模式，本体隐藏了升级的描述，改为在popup里面显示
		_foxlab_item_popup._panel.visible = RunData.is_coop_run
	else:
		on_foxlab_item_left()

func on_foxlab_item_hovered():
	if _item_data is ItemData:
		_foxlab_item_popup.display_item_data(_item_data, _item_description._name)
		# 只显示佛手等道具的备注信息，因为本体信息是 _item_description 显示的
		_foxlab_item_popup._panel.hide()

func on_foxlab_item_left():
	_foxlab_item_popup.hide()

## 扩展 ##
func show_item(item_data: ItemParentData) -> void :
	.show_item(item_data)
	on_foxlab_item_hovered()

func show_upgrades_for_level(level: int) -> void :
	.show_upgrades_for_level(level)
	if foxlab_current_ui:
		on_foxlab_upgrade_hovered(foxlab_current_ui.upgrade_data, foxlab_current_ui)