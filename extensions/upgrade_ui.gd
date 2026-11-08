extends "res://ui/menus/upgrades/upgrade_ui.gd"

signal foxlab_hovered(upgrade_data, control)
signal foxlab_left()

var _foxlab_hide_effects: bool = false

func on_foxlab_upgrade_hovered():
	emit_signal("foxlab_hovered", upgrade_data, self)

func on_foxlab_upgrade_left():
	emit_signal("foxlab_left")

func _ready():
	if not button.is_connected("focus_entered", self, "on_foxlab_upgrade_hovered"):
		button.connect("focus_entered", self, "on_foxlab_upgrade_hovered")
	if not button.is_connected("mouse_entered", self, "on_foxlab_upgrade_hovered"):
		button.connect("mouse_entered", self, "on_foxlab_upgrade_hovered")
	if not button.is_connected("focus_exited", self, "on_foxlab_upgrade_left"):
		button.connect("focus_exited", self, "on_foxlab_upgrade_left")
	if not button.is_connected("mouse_exited", self, "on_foxlab_upgrade_left"):
		button.connect("mouse_exited", self, "on_foxlab_upgrade_left")
	set_process(false)

func set_upgrade(p_upgrade_data: UpgradeData, player_index: int) -> void :
	.set_upgrade(p_upgrade_data, player_index)
	_foxlab_hide_effects = RunData.is_coop_run and not Utils.foxlab_is_vanilla_upgrade(p_upgrade_data)
	if _foxlab_hide_effects:
		_upgrade_description.get_effects().visible = false
	set_process(_foxlab_hide_effects)

func _process(_delta: float) -> void:
	if _upgrade_description.get_effects().visible:
		_upgrade_description.get_effects().visible = false

