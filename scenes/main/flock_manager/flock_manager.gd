extends Node3D

# Step 1: load
@export var boid_scene: PackedScene

var _grid: SpatialGrid

func _ready() -> void:
	var i: int = 0
	var rng = RandomNumberGenerator.new()
	var perception_radius: float
	while i < 163:
		var x = rng.randf_range(-8.0, 8.0)
		var y = rng.randf_range(-8.0, 8.0)
		var z = rng.randf_range(-8.0, 8.0)
		# Step 2: instantiate
		var boid = boid_scene.instantiate()
		boid.setup(Vector3(x, y, z), Vector3(x, y, z), 5)
		# Step 3: Add child
		add_child(boid)
		i+=1
	_grid = SpatialGrid.new(perception_radius)

func _physics_process(delta: float) -> void:
	# Clean the old grid
	_grid.clear()
	# Fill the new grid
	for child in get_children():
		if child.has_method("setup"): # Quick check for boids
			_grid.add_entity(child, child.global_position)
			child.set_context_grid(_grid)
