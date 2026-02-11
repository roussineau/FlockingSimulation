extends Area3D

# Configuration
const MAX_SPEED: float = 20.0
const MAX_FORCE: float = 1.0 # Inercy

# Weights (rules)
const W_SEPARATION: float = 3.3
const W_ALIGNMENT: float = 3.3
const W_COHESION: float = 6

# Private
var _velocity: Vector3
var _perception_radius: float
var _neighbors: Array = []
var _context_grid: SpatialGrid

func set_context_grid(grid: SpatialGrid):
	_context_grid = grid

# Dependency Injection
func setup(start_pos: Vector3, start_vel: Vector3, perception: float) -> void:
	position = start_pos
	_velocity = start_vel
	_perception_radius = perception
	$CollisionShape3D.shape.radius = _perception_radius

# Life Cycle
func _physics_process(delta: float) -> void:
	if _context_grid:
		_neighbors = _context_grid._get_nearby_entities(global_position)
		_neighbors.erase(self)
	
	# Acceleration
	var acceleration: Vector3 = Vector3.ZERO
	if _neighbors.size() > 0:
		acceleration = _calculate_flocking_force(_neighbors)
	
	# Centering
	var center_force: Vector3 = (Vector3.ZERO - global_position).normalized()
	acceleration += center_force * 3.3
	
	# Integrate velocity
	_velocity += acceleration * delta
	# Limiting velocity
	if _velocity.length() > MAX_SPEED:
		_velocity = _velocity.normalized() * MAX_SPEED
	
	# Integrate position
	position += _velocity * delta
	
	if _velocity.length() > 0.1:
		look_at(position - _velocity, Vector3.UP)

# Only called when neighbors.size() > 0
func _calculate_flocking_force(neighbors : Array) -> Vector3:
	var separation: Vector3 = Vector3.ZERO
	var alignment: Vector3 = Vector3.ZERO
	var cohesion: Vector3 = Vector3.ZERO
	var center_of_mass: Vector3 = Vector3.ZERO
	
	for neighbor in neighbors:
		alignment += neighbor._velocity # In a strict environment should implement get_velocity(), but it is an intern hot loop
		center_of_mass += neighbor.global_position
		var diff: Vector3 = global_position - neighbor.global_position
		var dist = diff.length()
		if dist > 0:
			separation += diff.normalized() / dist
	
	alignment /= neighbors.size()
	center_of_mass /= neighbors.size()
	
	cohesion = (center_of_mass - global_position).normalized()
	alignment = alignment.normalized()
	separation = separation.normalized()
	
	var total_force: Vector3 = (separation * W_SEPARATION) + (alignment * W_ALIGNMENT) + (cohesion * W_COHESION)

	
	return total_force * MAX_FORCE
