extends Node3D
# Data Oriented Design

# This design is for a great number of boids, so you can balance
# performance by changing the values of all the export variables.
# For example, a great amount of boids may require a high safe radius

# Visual
@export var mesh_source: Mesh
@export var amount: int = 8125

# Behavior
@export var perception_radius: float = 2.0
@export var safe_radius: float = 75

# Physics
@export var MAX_SPEED: float = 25
@export var INERCY: float = 0.9

# Weights
@export var SEPARATION: float = 6
@export var ALIGNMENT: float = 9
@export var COHESION: float = 6

# Rendering system
var _multimesh_instance: MultiMeshInstance3D

# Grid
var _grid: SpatialGrid

# Pure data, contiguous memory. Each boid is mapped to a unique index in both arrays:
var _positions: PackedVector3Array
var _velocities: PackedVector3Array

func _ready() -> void:
	_positions.resize(amount)
	_velocities.resize(amount)
	
	# Spawn
	for i in range(amount):
		_positions[i] = Vector3(randf_range(-safe_radius,safe_radius),randf_range(-safe_radius,safe_radius),randf_range(-safe_radius,safe_radius))
		_velocities[i] = Vector3(randf_range(-1.5,1.5),randf_range(-1.5,1.5),randf_range(-1.5,1.5))
	
	_setup_multimesh()
	_grid = SpatialGrid.new(perception_radius)


func _setup_multimesh():
	_multimesh_instance = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	
	# Performance config
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh_source
	multimesh.instance_count = amount
	
	# Add child
	_multimesh_instance.multimesh = multimesh
	add_child(_multimesh_instance)


func _process(delta: float) -> void:
	# Maths
	_update_boids_logic(delta)
	# Visuals
	_update_visuals()


func _update_boids_logic(delta: float) -> void:
	_grid.clear()
	
	for i in range(amount):
		_grid.add_entity(i, _positions[i])
	
	var group_task_id = WorkerThreadPool.add_group_task(
		Callable(self, "_process_boid_task").bind(delta),
		amount,
		-1,
		true
	)
	
	WorkerThreadPool.wait_for_group_task_completion(group_task_id)


func _update_visuals() -> void:
	for i in range(amount):
		var pos = _positions[i]
		var vel = _velocities[i]
		var t = Transform3D()
		t.origin = pos
		if vel.length_squared() > 0.01:
			t = t.looking_at(pos + vel, Vector3.UP)
		_multimesh_instance.multimesh.set_instance_transform(i, t)


func _calculate_flocking_force(index: int, pos: Vector3, neighbor_indexes: Array) -> Vector3:
	neighbor_indexes.erase(index)
	if neighbor_indexes.is_empty():
		return Vector3.ZERO
	
	var separation: Vector3 = Vector3.ZERO
	var alignment: Vector3 = Vector3.ZERO
	var cohesion: Vector3 = Vector3.ZERO
	var center_of_mass: Vector3 = Vector3.ZERO
	
	for neighbor in neighbor_indexes:
		alignment += _velocities[neighbor]
		center_of_mass += _positions[neighbor]
		var diff: Vector3 = pos - _positions[neighbor]
		var dist_sq = diff.length_squared()
		if dist_sq > 0.001 and dist_sq < perception_radius * perception_radius:
			separation += diff / dist_sq
	
	alignment /= neighbor_indexes.size()
	center_of_mass /= neighbor_indexes.size()
	
	cohesion = (center_of_mass - pos).normalized()
	alignment = alignment.normalized()
	separation = separation.normalized()
	
	var total_force: Vector3 = (separation * SEPARATION) + (alignment * ALIGNMENT) + (cohesion * COHESION)
	
	return total_force * INERCY


func _process_boid_task(boid_index: int, delta: float) -> void:
	var current_pos = _positions[boid_index]
	var current_vel = _velocities[boid_index]
	var neighbor_indexes = _grid.get_nearby_entities(current_pos)
	
	var force = _calculate_flocking_force(boid_index, current_pos, neighbor_indexes)
	
	# Centering
	var dist_to_center: float = current_pos.length()
	if dist_to_center > safe_radius:
		var return_strength = dist_to_center - safe_radius
		var dir_to_center: Vector3 = -current_pos.normalized()
		force += dir_to_center * return_strength 
	
	current_vel += force * delta
	if current_vel.length_squared() > MAX_SPEED * MAX_SPEED:
		current_vel = current_vel.normalized() * MAX_SPEED
	
	current_pos += current_vel * delta
	
	_velocities[boid_index] = current_vel
	_positions[boid_index] = current_pos
