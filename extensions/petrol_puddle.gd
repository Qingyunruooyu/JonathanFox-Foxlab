extends "res://entities/gpe/petrol_puddle/petrol_puddle.gd"

var _foxlab_enemy_area: Area2D = null
var _foxlab_enemies: Dictionary = {}

func init(size: Vector2 = Vector2(1, 1)):
	.init(size)
	_foxlab_enemies.clear()
	if _foxlab_enemy_area == null:
		_foxlab_enemy_area = Area2D.new()
		_foxlab_enemy_area.name = "FoxlabEnemyArea"
		var shape: CollisionShape2D = CollisionShape2D.new()
		shape.shape = collision.shape
		_foxlab_enemy_area.add_child(shape)
		_foxlab_enemy_area.collision_layer = 0
		_foxlab_enemy_area.collision_mask = Utils.ENEMIES_BIT
		var _err_enter = _foxlab_enemy_area.connect("body_entered", self, "_on_foxlab_enemy_area_body_entered")
		var _err_exit = _foxlab_enemy_area.connect("body_exited", self, "_on_foxlab_enemy_area_body_exited")
		add_child(_foxlab_enemy_area)
	_foxlab_enemy_area.monitoring = Utils.foxlab_uv_lamp_present()

func despawn():
	.despawn()
	for body in _foxlab_enemies.keys():
		if is_instance_valid(body):
			body.foxlab_notify_petrol_exit()
	_foxlab_enemies.clear()
	_foxlab_enemy_area.monitoring = false

func _on_foxlab_enemy_area_body_entered(body) -> void:
	if _is_dying or not body is Enemy or _foxlab_enemies.has(body):
		return
	_foxlab_enemies[body] = true
	body.foxlab_apply_petrol_effect()

func _on_foxlab_enemy_area_body_exited(body) -> void:
	if not _foxlab_enemies.has(body):
		return
	_foxlab_enemies.erase(body)
	if is_instance_valid(body):
		body.foxlab_notify_petrol_exit()
