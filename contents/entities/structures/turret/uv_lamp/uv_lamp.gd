extends "res://entities/structures/turret/turret.gd"

func _on_Range_body_entered(body: Node) -> void :
	._on_Range_body_entered(body)
	if not dead and body is Enemy:
		_foxlab_expose(body)

func _on_Range_body_exited(body: Node) -> void :
	._on_Range_body_exited(body)
	if not dead and body is Enemy and is_instance_valid(body) and not body.dead:
		_foxlab_unexpose(body)

func on_target_died(target: Node, _args: Entity.DieArgs) -> void :
	if not dead and target is Enemy:
		_foxlab_unexpose(target)
	.on_target_died(target, _args)

func die(args: = Utils.default_die_args) -> void :
	for body in _targets_in_range:
		if body is Enemy:
			_foxlab_unexpose(body)
	.die(args)

func _foxlab_expose(enemy) -> void :
	var count: int = enemy.get_meta("foxlab_uv", 0) + 1
	enemy.set_meta("foxlab_uv", count)
	if count == 1:
		enemy._hurtbox.set_deferred("collision_mask", enemy._hurtbox.collision_mask | Utils.ENEMY_PROJECTILES_BIT | Utils.ENEMIES_BIT)
		RunData.foxlab_exposed_enemies[enemy.enemy_id_hash] = RunData.foxlab_exposed_enemies.get(enemy.enemy_id_hash, 0) + 1

func _foxlab_unexpose(body) -> void :
	if not is_instance_valid(body) or not body is Enemy:
		return
	var count: int = body.get_meta("foxlab_uv", 0) - 1
	if count > 0:
		body.set_meta("foxlab_uv", count)
		return
	body.set_meta("foxlab_uv", 0)
	body._hurtbox.set_deferred("collision_mask", body._hurtbox.collision_mask & ~(Utils.ENEMY_PROJECTILES_BIT | Utils.ENEMIES_BIT))
	var id_count: int = RunData.foxlab_exposed_enemies.get(body.enemy_id_hash, 0) - 1
	if id_count > 0:
		RunData.foxlab_exposed_enemies[body.enemy_id_hash] = id_count
	else:
		RunData.foxlab_exposed_enemies.erase(body.enemy_id_hash)
