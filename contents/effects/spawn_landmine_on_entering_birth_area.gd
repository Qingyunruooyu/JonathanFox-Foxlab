extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "foxlab_spawn_landmine_on_entering_birth_area"

func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	# {2}：每波生成上限
	args.append(str(Utils.FOXLAB_MOM_LANDMINE_MAX_PER_WAVE))
	return args
