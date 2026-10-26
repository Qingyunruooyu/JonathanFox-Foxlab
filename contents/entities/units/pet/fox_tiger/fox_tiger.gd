extends "res://entities/units/unit/unit.gd"

export (Resource) var targetable_particles
export (float) var overload_radius = 200.0
export (int) var overload_enemy_threshold = 10
export (float) var overload_cooldown = 2.5

var original: Node2D
var targetable_particles_instance
var _enemies_in_range = {}
var _ending = false

onready var _range = $Range
onready var _range_shape = $Range/CollisionShape2D
onready var _overload_timer = $OverloadTimer

func _ready():
	set_physics_process(false)
	_range_shape.shape.radius = overload_radius

func _physics_process(_delta: float) -> void :
	global_position = original.global_position

func _update_overload() -> void:
	if _ending:
		return
	var enemy_count = _enemies_in_range.size()
	if not dead and enemy_count > overload_enemy_threshold:
		dead = true
		_overload_timer.start(overload_cooldown)
		targetable_particles_instance.hide()
		emit_signal("died", self, Utils.default_die_args)
	elif dead and _overload_timer.is_stopped() and enemy_count < overload_enemy_threshold:
		dead = false
		targetable_particles_instance.show()

func _on_Range_body_entered(body: Node) -> void:
	if _ending or not body is Enemy or body.dead:
		return
	if _enemies_in_range.has(body):
		return
	_enemies_in_range[body] = true
	body.connect("died", self, "_on_range_enemy_died")
	body.connect("tree_exiting", self, "_on_range_enemy_removed", [body])
	_update_overload()

func _on_Range_body_exited(body: Node) -> void:
	_on_range_enemy_removed(body)

func _on_range_enemy_died(enemy: Node, _args) -> void:
	_on_range_enemy_removed(enemy)

func _on_range_enemy_removed(enemy: Node) -> void:
	if not _enemies_in_range.has(enemy):
		return
	_enemies_in_range.erase(enemy)
	enemy.disconnect("died", self, "_on_range_enemy_died")
	enemy.disconnect("tree_exiting", self, "_on_range_enemy_removed")
	_update_overload()

func _on_OverloadTimer_timeout() -> void:
	_update_overload()

func set_original(original_entity: Node2D):
	original = original_entity
	original.connect("died", self, "_on_original_died")
	original.connect("tree_exiting", self, "_on_original_tree_exiting")
	global_position = original.global_position
	_entity_spawner_ref.targetable_pets.append(self)
	targetable_particles_instance = targetable_particles.instance()
	add_child(targetable_particles_instance)
	move_child(targetable_particles_instance, 0)
	_range.set_deferred("monitoring", true)
	set_physics_process(true)

func _on_original_died(_entity: Node2D, args):
	die(args)

func _on_original_tree_exiting():
	die()

func die(args = Utils.default_die_args) -> void :
	if _ending:
		return
	_ending = true
	dead = true
	set_physics_process(false)
	_overload_timer.stop()
	for enemy in _enemies_in_range.keys():
		_on_range_enemy_removed(enemy)
	original.disconnect("died", self, "_on_original_died")
	original.disconnect("tree_exiting", self, "_on_original_tree_exiting")
	_entity_spawner_ref.targetable_pets.erase(self)
	if not args.cleaning_up and not _entity_spawner_ref._cleaning_up:
		emit_signal("died", self, args)
	queue_free()
