extends "res://ui/menus/pages/killed_by_container.gd"

func _display(args = Utils.default_die_args):
	._display(args)
	var texture = RunData.foxlab_killed_by_textures[player_index]
	if texture != null:
		icon.texture = texture
