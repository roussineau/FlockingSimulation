extends Node3D

# Data Oriented Design

@export var mesh_source: Mesh
var count: int = 5000
var perception_radius: float = 3.0
var safe_radius: float = 45

const MAX_SPEED: float = 25
const MAX_FORCE: float = 0.9 # Inercy

# Weights (rules)
const W_SEPARATION: float = 2
const W_ALIGNMENT: float = 3
const W_COHESION: float = 2

# Rendering system
var _multimesh_instance: MultiMeshInstance3D
# Grid
var _grid: SpatialGrid
# Pure data, contiguous memory
var _positions: PackedVector3Array
var _velocities: PackedVector3Array

func _ready() -> void:
	_positions.resize(count)
	_velocities.resize(count)
	# Spawn
	for i in range(count):
		_positions[i] = Vector3(randf_range(-safe_radius,safe_radius),randf_range(-safe_radius,safe_radius),randf_range(-safe_radius,safe_radius))
		_velocities[i] = Vector3(randf_range(-1.5,1.5),randf_range(-1.5,1.5),randf_range(-1.5,1.5))
	
	_setup_multimesh()
	
	# Create grid
	_grid = SpatialGrid.new(perception_radius)

func _setup_multimesh():
	_multimesh_instance = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	
	# Performative config
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh_source
	multimesh.instance_count = count
	
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
	
	for i in range(count):
		_grid.add_entity(i, _positions[i])
	
	for i in range(count):
		var current_pos = _positions[i]
		var current_vel = _velocities[i]
		var neighbor_indexes = _grid._get_nearby_entities(current_pos)
		
		# Forces
		var force: Vector3 = _calculate_flocking_force(i, current_pos, neighbor_indexes)
		
		# Centering
		var dist_to_center: float = current_pos.length()
		if dist_to_center > safe_radius:
			var return_strength = dist_to_center - safe_radius
			var dir_to_center: Vector3 = -current_pos.normalized()
			force += dir_to_center * return_strength 
		
		# Physics
		current_vel += force * delta
		current_pos += current_vel * delta
		
				# Limiting velocity
		if current_vel.length_squared() > MAX_SPEED*MAX_SPEED:
			current_vel = current_vel.normalized() * MAX_SPEED
		
		# Save data
		_positions[i] = current_pos
		_velocities[i] = current_vel

func _update_visuals() -> void:
	for i in range(count):
		var pos = _positions[i]
		var vel = _velocities[i]
		var t = Transform3D()
		t.origin = pos
		if vel.length_squared() > 0.01:
			t = t.looking_at(pos + vel, Vector3.UP)
		_multimesh_instance.multimesh.set_instance_transform(i, t)

func _calculate_flocking_force(index: int, pos: Vector3, neighbors: Array) -> Vector3:
	neighbors.erase(index)
	if neighbors.is_empty():
		return Vector3.ZERO
	
	var separation: Vector3 = Vector3.ZERO
	var alignment: Vector3 = Vector3.ZERO
	var cohesion: Vector3 = Vector3.ZERO
	var center_of_mass: Vector3 = Vector3.ZERO
	
	for neighbor in neighbors:
		alignment += _velocities[neighbor]
		center_of_mass += _positions[neighbor]
		var diff: Vector3 = pos - _positions[neighbor]
		var dist_sq = diff.length_squared()
		if dist_sq > 0.001 and dist_sq < perception_radius * perception_radius:
			separation += diff / dist_sq
	
	alignment /= neighbors.size()
	center_of_mass /= neighbors.size()
	
	cohesion = (center_of_mass - pos).normalized()
	alignment = alignment.normalized()
	separation = separation.normalized()
	
	var total_force: Vector3 = (separation * W_SEPARATION) + (alignment * W_ALIGNMENT) + (cohesion * W_COHESION)
	
	return total_force * MAX_FORCE
