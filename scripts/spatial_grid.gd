class_name SpatialGrid

var _cell_size: float

# Spacial hash map
# Key: Vector3i
# Value: Array[Boid]
var _buckets: Dictionary = {}

func _init(cell_size) -> void:
	_cell_size = cell_size

# Mapping R^3 -> Grid
func _get_cell_coords(pos: Vector3) -> Vector3i:
	return Vector3i(floor(pos.x / _cell_size), floor(pos.y / _cell_size), floor(pos.z / _cell_size))

# Add entity
func add_entity(entity, pos: Vector3) -> void:
	var coords = _get_cell_coords(pos)
	if not _buckets.has(coords):
		_buckets[coords] = []
	_buckets[coords].append(entity)

# Clearing
func clear():
	_buckets.clear()

# Checking 3x3x3 box environment
func get_nearby_entities(pos: Vector3) -> Array:
	var center_coords = _get_cell_coords(pos)
	var res = []
	for x in range(center_coords.x - 1, center_coords.x + 2):
		for y in range(center_coords.y - 1, center_coords.y + 2):
			for z in range(center_coords.z - 1, center_coords.z + 2):
				var grid: Vector3i = Vector3i(x, y, z)
				if _buckets.has(grid):
					res.append_array(_buckets[Vector3i(x, y, z)])
	return res
