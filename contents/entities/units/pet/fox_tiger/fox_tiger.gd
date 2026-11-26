extends "res://entities/units/unit/unit.gd"

export (Resource) var foxlab_targetable_particles
export (float) var foxlab_overload_radius = 200.0
export (int) var foxlab_overload_enemy_threshold = 10
export (float) var foxlab_overload_cooldown = 2.5

var foxlab_original: Node2D
var foxlab_targetable_particles_instance
var _foxlab_enemies_in_range = {}
var _foxlab_ending = false

onready var _foxlab_range = $FoxlabRange
onready var _foxlab_range_shape = $FoxlabRange/CollisionShape2D
onready var _foxlab_overload_timer = $FoxlabOverloadTimer

func _ready():
	set_physics_process(false)
	_foxlab_range_shape.shape.radius = foxlab_overload_radius

func respawn():
	.respawn()
	_foxlab_ending = false
	_foxlab_enemies_in_range.clear()
	foxlab_original = null
	set_physics_process(false)
	_foxlab_range.set_deferred("monitoring", false)

func _physics_process(_delta: float) -> void :
	if foxlab_original == null or not is_instance_valid(foxlab_original):
		die()
		return
	global_position = foxlab_original.global_position

func _foxlab_update_overload() -> void:
	if _foxlab_ending:
		return
	var enemy_count = _foxlab_enemies_in_range.size()
	if not dead and enemy_count > foxlab_overload_enemy_threshold:
		dead = true
		_foxlab_overload_timer.start(foxlab_overload_cooldown)
		foxlab_targetable_particles_instance.hide()
		emit_signal("died", self, Utils.default_die_args)
	elif dead and _foxlab_overload_timer.is_stopped() and enemy_count < foxlab_overload_enemy_threshold:
		dead = false
		foxlab_targetable_particles_instance.show()

func _foxlab_on_Range_body_entered(body: Node) -> void:
	if _foxlab_ending or not body is Enemy or body.dead:
		return
	if _foxlab_enemies_in_range.has(body):
		return
	_foxlab_enemies_in_range[body] = true
	body.connect("died", self, "_foxlab_on_range_enemy_died")
	body.connect("tree_exiting", self, "_foxlab_on_range_enemy_removed", [body])
	_foxlab_update_overload()

func _foxlab_on_Range_body_exited(body: Node) -> void:
	_foxlab_on_range_enemy_removed(body)

func _foxlab_on_range_enemy_died(enemy: Node, _args) -> void:
	_foxlab_on_range_enemy_removed(enemy)

func _foxlab_on_range_enemy_removed(enemy: Node) -> void:
	if not _foxlab_enemies_in_range.has(enemy):
		return
	_foxlab_enemies_in_range.erase(enemy)
	if is_instance_valid(enemy):
		enemy.disconnect("died", self, "_foxlab_on_range_enemy_died")
		enemy.disconnect("tree_exiting", self, "_foxlab_on_range_enemy_removed")
	_foxlab_update_overload()

func _foxlab_on_OverloadTimer_timeout() -> void:
	_foxlab_update_overload()

func foxlab_set_original(original_entity: Node2D):
	foxlab_original = original_entity
	foxlab_original.connect("died", self, "_foxlab_on_original_died")
	foxlab_original.connect("tree_exiting", self, "_foxlab_on_original_tree_exiting")
	global_position = foxlab_original.global_position
	_entity_spawner_ref.targetable_pets.append(self)
	foxlab_targetable_particles_instance = foxlab_targetable_particles.instance()
	add_child(foxlab_targetable_particles_instance)
	move_child(foxlab_targetable_particles_instance, 0)
	_foxlab_range.set_deferred("monitoring", true)
	set_physics_process(true)

func _foxlab_on_original_died(_entity: Node2D, args):
	die(args)

func _foxlab_on_original_tree_exiting():
	die()

func die(args = Utils.default_die_args) -> void :
	if _foxlab_ending:
		return
	_foxlab_ending = true
	dead = true
	set_physics_process(false)
	_foxlab_overload_timer.stop()
	for enemy in _foxlab_enemies_in_range.keys():
		_foxlab_on_range_enemy_removed(enemy)
	if is_instance_valid(foxlab_original):
		foxlab_original.disconnect("died", self, "_foxlab_on_original_died")
		foxlab_original.disconnect("tree_exiting", self, "_foxlab_on_original_tree_exiting")
	if is_instance_valid(_entity_spawner_ref):
		_entity_spawner_ref.targetable_pets.erase(self)
		if not args.cleaning_up and not _entity_spawner_ref._cleaning_up:
			emit_signal("died", self, args)
	if is_instance_valid(foxlab_targetable_particles_instance):
		foxlab_targetable_particles_instance.queue_free()
		foxlab_targetable_particles_instance = null
	free_entity()
