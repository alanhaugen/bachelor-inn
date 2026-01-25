extends Node3D

@onready var particles := get_children()

func play() -> void:
	for p in particles:
		if p is GPUParticles3D:
			p.restart()
	var max_lifetime := 0.0
	for p in particles:
		if p is GPUParticles3D:
			max_lifetime = max(max_lifetime, p.lifetime)

	await get_tree().create_timer(max_lifetime).timeout
	queue_free()
