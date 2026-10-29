extends "res://effect_behaviors/enemy_effect_behavior.gd"

func _ready() -> void :
	_parent._hurtbox.connect("area_entered", self, "_on_Hurtbox_area_entered")
	_parent._hurtbox.connect("area_exited", self, "_on_Hurtbox_area_exited")

func _on_Hurtbox_area_entered(hitbox) -> void :
	if hitbox.from == _parent and not _parent in hitbox.ignored_objects:
		hitbox.ignored_objects.push_back(_parent)

func _on_Hurtbox_area_exited(hitbox) -> void :
	if hitbox.from == _parent and _parent in hitbox.ignored_objects:
		hitbox.ignored_objects.erase(_parent)

func should_add_on_spawn() -> bool:
	return RunData.sum_all_player_effects(Utils.foxlab_has_uv_lamp_hash) > 0

func on_hurt(_hitbox: Hitbox) -> void :
	if _parent.dead or not RunData.foxlab_exposed_enemies.has(_parent.enemy_id_hash):
		return
	if not _parent.is_playing_shoot_animation():
		_parent._animation_player.playback_speed = 1.0
		_parent._animation_player.play(_parent.shoot_animation_name)
