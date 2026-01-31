extends StaticBody3D
class_name BaseUnit

# -------- ENUMS --------
enum BuildFace {
	TOP    = 1 << 0,
	BOTTOM = 1 << 1,
	NORTH  = 1 << 2,
	SOUTH  = 1 << 3,
	EAST   = 1 << 4,
	WEST   = 1 << 5
}

# -------- CONFIG --------
@export var size: Vector3 = Vector3.ONE
@export_flags("TOP", "BOTTOM", "NORTH", "SOUTH", "EAST", "WEST")
var build_faces: int = BuildFace.TOP | BuildFace.NORTH | BuildFace.SOUTH | BuildFace.EAST | BuildFace.WEST

@export var inv_size: int = 5
# Inventory: slot index -> { "unit_type": String, "amount": int }
var inventory: Dictionary[int, Dictionary] = {}

@export var process_interval: float = 1.0
@export var process_timer: float = 0.0

# Neighbors: BuildFace -> BaseUnit
var neighbors: Dictionary[int, BaseUnit] = {}

# -------- READY --------
func _ready() -> void:
	# Initialize inventory slots
	for i in range(inv_size):
		inventory[i] = {}

# -------- BUILDFACE LOGIC --------
func can_build_on(normal: Vector3) -> bool:
	var face: int = normal_to_face(normal)
	return (build_faces & face) != 0

func _face_to_dir(face: int) -> Vector3:
	match face:
		BuildFace.TOP:
			return Vector3.UP
		BuildFace.BOTTOM:
			return Vector3.DOWN
		BuildFace.NORTH:
			return Vector3(0, 0, -1)
		BuildFace.SOUTH:
			return Vector3(0, 0, 1)
		BuildFace.EAST:
			return Vector3(1, 0, 0)
		BuildFace.WEST:
			return Vector3(-1, 0, 0)
	return Vector3.ZERO

func normal_to_face(n: Vector3) -> int:

	var abs_n := Vector3(abs(n.x), abs(n.y), abs(n.z))
	
	if abs_n.x > abs_n.y and abs_n.x > abs_n.z:
		return BuildFace.EAST if n.x > 0 else BuildFace.WEST
	elif abs_n.y > abs_n.x and abs_n.y > abs_n.z:
		return BuildFace.TOP if n.y > 0 else BuildFace.BOTTOM
	else:
		return BuildFace.SOUTH if n.z > 0 else BuildFace.NORTH


func get_snap_offset(face: int, other_size: Vector3) -> Vector3:
	match face:
		BuildFace.TOP:
			return Vector3(0.0, size.y * 0.5 + other_size.y * 0.5, 0.0)
		BuildFace.BOTTOM:
			return Vector3(0.0, -size.y * 0.5 - other_size.y * 0.5, 0.0)
		BuildFace.EAST:
			return Vector3(size.x * 0.5 + other_size.x * 0.5, 0.0, 0.0)
		BuildFace.WEST:
			return Vector3(-size.x * 0.5 - other_size.x * 0.5, 0.0, 0.0)
		BuildFace.SOUTH:
			return Vector3(0.0, 0.0, size.z * 0.5 + other_size.z * 0.5)
		BuildFace.NORTH:
			return Vector3(0.0, 0.0, -size.z * 0.5 - other_size.z * 0.5)
	return Vector3.ZERO

# -------- NEIGHBORS UPDATE --------
func update_neighbors() -> void:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

	for face in BuildFace.values():
		# Skip faces this block can't build on
		if face == 0:
			continue
		if (build_faces & face) == 0:
			continue
		
		var dir: Vector3 = _face_to_dir(face)
		var ray_origin: Vector3 = global_transform.origin

		# Determine distance to check for neighbor
		var max_distance: float = 0.0 
		match face:
			BuildFace.TOP, BuildFace.BOTTOM:
				max_distance = size.y * 0.5 
			BuildFace.NORTH, BuildFace.SOUTH:
				max_distance = size.z * 0.5 
			BuildFace.EAST, BuildFace.WEST: 
				max_distance = size.x * 0.5

		var ray_end: Vector3 = ray_origin + dir * (max_distance + 0.1) # small margin

		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collision_mask = collision_mask
		query.collide_with_bodies = true
		query.collide_with_areas = true
		query.exclude = [self]

		var result: Dictionary = space.intersect_ray(query)

		if result and result.collider is BaseUnit:
			var new_neighbor: BaseUnit = result.collider
			
			if neighbors.get(face, null) != new_neighbor:
				neighbors[face] = new_neighbor
				new_neighbor.update_neighbors()
		else:
			if neighbors.has(face):
				neighbors.erase(face)

func set_neighbor(face: int, unit: BaseUnit) -> void:
	neighbors[face] = unit

# -------- PROCESS TIMER --------
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	process_timer += delta
	if process_timer >= process_interval:
		process_timer = 0.0
		process_tick()

func process_tick() -> void:
	# Override in children for automation / processing
	pass

# -------- INVENTORY IO --------
# ? might need changes looks like

func try_input(slot: int, unit_type: String, amount: int) -> int:
	if slot < 0 or slot >= inv_size:
		return 0

	var slot_data: Dictionary = inventory[slot]

	# Check if slot is empty by looking at keys
	if slot_data.keys().size() == 0:
		inventory[slot] = {"unit_type": unit_type, "amount": amount}
		return amount
	elif slot_data.get("unit_type", "") == unit_type:
		slot_data["amount"] += amount
		return amount

	return 0


func try_output(slot: int, amount: int) -> int:
	if slot < 0 or slot >= inv_size:
		return 0
	var slot_data: Dictionary[String, int] = inventory[slot]
	if slot_data.size() == 0:
		return 0
	var give: int = min(slot_data["amount"], amount)
	slot_data["amount"] -= give
	if slot_data["amount"] <= 0:
		inventory[slot] = {}
	return give
