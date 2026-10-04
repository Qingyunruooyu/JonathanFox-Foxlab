extends Unit

export (Resource) var targetable_particles

var original: Node2D
var targetable_particles_instance

func _ready():
	set_physics_process(false)

func _physics_process(_delta: float) -> void :
	global_position = original.global_position

func set_original(original_entity: Node2D):
	assert (original_entity is Structure)
	if original_entity:
		if not original_entity.is_connected("died", self, "on_foxlab_orignal_died"):
			original_entity.connect("died", self, "on_foxlab_orignal_died")
		original = original_entity
		set_physics_process(true)
		original.add_outline(Color("#fd6a2d"))
		_entity_spawner_ref.targetable_pets.append(self)
		targetable_particles_instance = targetable_particles.instance()
		add_child(targetable_particles_instance)
		move_child(targetable_particles_instance, 0)

func on_foxlab_orignal_died(_entity: Node2D, _die_args: Entity.DieArgs):
	original.disconnect("died", self, "on_foxlab_orignal_died")
	if targetable_particles_instance:
		targetable_particles_instance.queue_free()
	_entity_spawner_ref.targetable_pets.erase(self)
	die()
	set_physics_process(false)
