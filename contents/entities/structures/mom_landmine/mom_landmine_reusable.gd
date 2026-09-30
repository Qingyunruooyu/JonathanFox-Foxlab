extends "res://entities/structures/landmine/landmine.gd"

# 可反复爆炸的鬼妈地雷：explode() 之后调用的 die() 不真正销毁，只重置贴图重新武装，达到能一直爆炸的目的
# 只有清理房间（cleaning_up 为 true）时才调用基类 die() 真正移除

func die(args: = Utils.default_die_args) -> void :
	if args.cleaning_up:
		.die(args)
		return
	_sprite.texture = _original_texture

func _ready() -> void :
	add_outline(Color.violet)
