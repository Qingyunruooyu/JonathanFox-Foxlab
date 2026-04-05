extends "res://ui/menus/upgrades/upgrade_ui.gd"

signal foxlab_hovered(upgrade_data, control)
signal foxlab_left()

func on_upgrade_hovered():
	emit_signal("foxlab_hovered", upgrade_data, self)

func on_upgrade_left():
	emit_signal("foxlab_left")

func _ready():
	if RunData.is_coop_run:
		button.connect("focus_entered", self, "on_upgrade_hovered")
		button.connect("mouse_entered", self, "on_upgrade_hovered")
		button.connect("focus_exited", self, "on_upgrade_left")
		button.connect("mouse_exited", self, "on_upgrade_left")