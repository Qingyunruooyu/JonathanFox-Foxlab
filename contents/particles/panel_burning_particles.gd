extends CPUParticles2D

onready var secondary_particles: CPUParticles2D = $secondaryParticle

func _physics_process(_delta: float) -> void :
	if secondary_particles.emitting != emitting:
		secondary_particles.emitting = emitting
