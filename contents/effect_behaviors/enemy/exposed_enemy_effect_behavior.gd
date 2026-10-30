extends "res://effect_behaviors/enemy_effect_behavior.gd"

export (int) var bonus_damage_taken_percent = 25

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
	return RunData.sum_all_player_effects(Utils.foxlab_uv_lamp_hash) > 0


func get_bonus_damage(_hitbox: Hitbox, _from_player_index: int) -> int:
	if not RunData.foxlab_exposed_enemies.has(_parent.enemy_id_hash):
		return 0
	var lamp_count: int = RunData.sum_all_player_effects(Utils.foxlab_uv_lamp_instance_hash)
	if lamp_count <= 0:
		return 0
	return lamp_count * bonus_damage_taken_percent

func on_hurt(_hitbox: Hitbox) -> void :
	if _parent.dead or not RunData.foxlab_exposed_enemies.has(_parent.enemy_id_hash):
		return
	if not _parent.is_playing_shoot_animation():
		var attack_behavior = _parent._current_attack_behavior
		var cooldown = attack_behavior.get("cooldown")
		if cooldown != null and cooldown >= 1e9:
			return
		if attack_behavior is SpawningAttackBehavior and attack_behavior.max_nb_of_spawns != - 1 and attack_behavior._current_nb_of_spawns >= attack_behavior.max_nb_of_spawns:
			return
		var attack_anim_speed = attack_behavior.get("attack_anim_speed")
		_parent._animation_player.playback_speed = attack_anim_speed if attack_anim_speed != null else 1.0
		_parent._animation_player.play(_parent.shoot_animation_name)
