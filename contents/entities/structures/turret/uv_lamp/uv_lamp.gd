extends "res://entities/structures/turret/turret.gd"

var _instance_counted: bool = false
var _exposed_enemies: Dictionary = {}
onready var _expose_shape = $ExposeRange / CollisionShape2D

func set_data(data: Resource) -> void :
	.set_data(data)
	if not _instance_counted:
		_instance_counted = true
		RunData.get_player_effects(player_index)[Utils.foxlab_uv_lamp_instance_hash] += 1


func set_current_stats(new_stats) -> void :
	.set_current_stats(new_stats)
	_sync_expose_range()


func reload_data() -> void :
	.reload_data()
	_sync_expose_range()


func _sync_expose_range() -> void :
	if _expose_shape:
		_expose_shape.shape.radius = stats.max_range


func _on_ExposeRange_body_entered(body: Node) -> void :
	if not dead and body is Enemy:
		_exposed_enemies[body] = true
		_foxlab_expose(body)
		var _error = body.connect("died", self, "_on_exposed_enemy_died")
		var _error_charm = body.connect("charmed", self, "_on_exposed_enemy_charmed")


func _on_ExposeRange_body_exited(body: Node) -> void :
	if not body is Enemy or not is_instance_valid(body):
		return
	if not dead and not body.dead:
		_foxlab_unexpose(body)
	_exposed_enemies.erase(body)
	body.disconnect("died", self, "_on_exposed_enemy_died")
	body.disconnect("charmed", self, "_on_exposed_enemy_charmed")


func _on_exposed_enemy_died(target, _args) -> void :
	if not dead:
		_foxlab_unexpose(target)
	_exposed_enemies.erase(target)


func _on_exposed_enemy_charmed(target) -> void :
	if not dead:
		_foxlab_set_exposed_hurtbox(target)


func die(args: = Utils.default_die_args) -> void :
	if _instance_counted:
		_instance_counted = false
		RunData.get_player_effects(player_index)[Utils.foxlab_uv_lamp_instance_hash] -= 1
	for body in _exposed_enemies.keys():
		_foxlab_unexpose(body)
	_exposed_enemies.clear()
	.die(args)

func _foxlab_expose(enemy) -> void :
	var count: int = enemy.get_meta("foxlab_uv", 0) + 1
	enemy.set_meta("foxlab_uv", count)
	if count == 1:
		if not enemy.has_meta("foxlab_uv_hurtbox_mask"):
			enemy.set_meta("foxlab_uv_hurtbox_mask", enemy._hurtbox.collision_mask)
		_foxlab_set_exposed_hurtbox(enemy)
		RunData.foxlab_exposed_enemies[enemy.enemy_id_hash] = RunData.foxlab_exposed_enemies.get(enemy.enemy_id_hash, 0) + 1


func _foxlab_set_exposed_hurtbox(enemy) -> void :
	if enemy.get_charmed_by_player_index() != - 1:
		# 魅惑禁用了 hurtbox：打开但只允许敌方来源，玩家方弹幕不打自己的魅惑盟友
		enemy._hurtbox.set_deferred("collision_mask", Utils.ENEMY_PROJECTILES_BIT | Utils.ENEMIES_BIT)
		enemy._hurtbox.enable()
	else:
		enemy._hurtbox.set_deferred("collision_mask", enemy._hurtbox.collision_mask | Utils.ENEMY_PROJECTILES_BIT | Utils.ENEMIES_BIT)

func _foxlab_unexpose(body) -> void :
	if not is_instance_valid(body):
		return
	var count: int = body.get_meta("foxlab_uv", 0) - 1
	if count > 0:
		body.set_meta("foxlab_uv", count)
		return
	body.set_meta("foxlab_uv", 0)
	if body.has_meta("foxlab_uv_hurtbox_mask"):
		body._hurtbox.set_deferred("collision_mask", body.get_meta("foxlab_uv_hurtbox_mask"))
		body.remove_meta("foxlab_uv_hurtbox_mask")
	if body.get_charmed_by_player_index() != - 1:
		body._hurtbox.disable()
	var id_count: int = RunData.foxlab_exposed_enemies.get(body.enemy_id_hash, 0) - 1
	if id_count > 0:
		RunData.foxlab_exposed_enemies[body.enemy_id_hash] = id_count
	else:
		RunData.foxlab_exposed_enemies.erase(body.enemy_id_hash)
