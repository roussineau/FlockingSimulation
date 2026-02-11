extends Node3D

# Step 1: load
@export var boid_scene: PackedScene

func _ready() -> void:
	var i: int = 0
	var rng = RandomNumberGenerator.new()
	while i < 118:
		var x = rng.randf_range(-3.0, 3.0)
		var y = rng.randf_range(-3.0, 3.0)
		var z = rng.randf_range(-3.0, 3.0)
		# Step 2: instantiate
		var boid = boid_scene.instantiate()
		boid.setup(Vector3(x, y, z), Vector3(x, y, z), 5)
		# Step 3: Add child
		add_child(boid)
		i+=1
